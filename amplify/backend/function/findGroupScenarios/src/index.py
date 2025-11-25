import json
import os
import boto3
from concurrent.futures import ThreadPoolExecutor
from boto3.dynamodb.conditions import Key, Attr

# --- 環境変数 ---
ENV = os.environ['ENV']
REGION = os.environ['REGION']
API_ID = os.environ['API_MYMADAMISAPP_GRAPHQLAPIIDOUTPUT']

# --- 定数 ---
USER_SCENARIO_TABLE_NAME = f'UserScenario-{API_ID}-{ENV}'

# --- AWS リソース ---
dynamodb_resource = boto3.resource('dynamodb', region_name=REGION)
user_scenario_table = dynamodb_resource.Table(USER_SCENARIO_TABLE_NAME)

def fetch_friend_status(user_id):
    """
    指定ユーザーのステータスを取得し、各状態ごとのシナリオIDセットを返す
    Returns: 
        user_id (str)
        ng_set (set): 通過済などでNGなシナリオID
        wants_play_set (set): PL希望のシナリオID
        possessed_set (set): 所持しているシナリオID
        wants_gm_set (set): 購入検討のシナリオID
    """
    ng_set = set()
    wants_play_set = set()
    possessed_set = set()
    wants_gm_set = set()
    
    try:
        response = user_scenario_table.query(
            IndexName='byUser',
            KeyConditionExpression=Key('userId').eq(user_id),
            # 必要な属性のみ取得
            FilterExpression=Attr('isPlayed').eq(True) | Attr('isPossessed').eq(True) | Attr('wantsToGm').eq(True) | Attr('wantsToPlay').eq(True),
            ProjectionExpression='scenarioId, isPlayed, isPossessed, wantsToGm, wantsToPlay'
        )
        
        for item in response.get('Items', []):
            sid = item['scenarioId']
            
            # NG判定 (通過済はNG確定)
            # ※ 所持・購入検討も基本はPL不可だが、要件によっては「未通過ならPL可」とする場合もある。
            # ここでは要件定義に基づき、通過済(isPlayed)のみを完全NG、他は状況によると判断できるよう分離して返す設計にするが、
            # 一般的なマダミスアプリとして「通過済」をNGの主軸とする。
            if item.get('isPlayed'):
                ng_set.add(sid)
            
            # 所持・購入検討 (GM候補情報として収集)
            if item.get('isPossessed'):
                possessed_set.add(sid)
                # 通常、所持している＝内容は知っている＝PL不可 なのでNGにも追加
                ng_set.add(sid)
            
            if item.get('wantsToGm'):
                wants_gm_set.add(sid)
                # GM検討中＝ネタバレを見ている可能性があるためNGに追加
                ng_set.add(sid)
                
            # PL希望
            if item.get('wantsToPlay'):
                wants_play_set.add(sid)
                
        return user_id, ng_set, wants_play_set, possessed_set, wants_gm_set
        
    except Exception as e:
        print(f"Error fetching status for friend {user_id}: {e}")
        return user_id, set(), set(), set(), set()

def fetch_my_target_list(user_id):
    """自分の対象リスト（所持 OR GM検討 OR PL希望）を取得"""
    # 自分が全く関心のないシナリオまで計算すると膨大になるため、自分のリストをベースにする
    try:
        response = user_scenario_table.query(
            IndexName='byUser',
            KeyConditionExpression=Key('userId').eq(user_id),
            # 自分がステータスをつけているものすべてを候補とする
            FilterExpression=Attr('isPossessed').eq(True) | Attr('wantsToGm').eq(True) | Attr('wantsToPlay').eq(True) | Attr('isPlayed').eq(True),
            ProjectionExpression='scenarioId'
        )
        return {item['scenarioId'] for item in response.get('Items', [])}
    except Exception as e:
        print(f"Error fetching target list for user {user_id}: {e}")
        return set()

def handler(event, context):
    print("=== findGroupScenarios START (v2.16 Detail Info) ===")

    try:
        arguments = event.get('arguments', {})
        identity = event.get('identity', {})
        
        requesting_user_id = identity.get('sub')
        friend_ids = arguments.get('friendIds', []) 

        if not requesting_user_id:
            raise ValueError("Unauthorized")
        if len(friend_ids) > 8:
             raise ValueError("Too many friends selected (Max 8).")

        with ThreadPoolExecutor(max_workers=10) as executor:
            # A. 自分の候補リスト取得
            my_list_future = executor.submit(fetch_my_target_list, requesting_user_id)
            
            # B. フレンズのステータス取得
            friend_futures = [executor.submit(fetch_friend_status, fid) for fid in friend_ids]

            my_target_scenarios = my_list_future.result()
            
            # 集計用マップ { scenarioId: [userIds...] }
            map_ng = {}
            map_wants_play = {}
            map_possessed = {}
            map_wants_gm = {}
            
            # 全フレンズの情報をマップに集約
            for future in friend_futures:
                uid, ngs, plays, poss, gms = future.result()
                
                for sid in ngs: map_ng.setdefault(sid, []).append(uid)
                for sid in plays: map_wants_play.setdefault(sid, []).append(uid)
                for sid in poss: map_possessed.setdefault(sid, []).append(uid)
                for sid in gms: map_wants_gm.setdefault(sid, []).append(uid)
            
            # フレンズが「PL希望」を出しているシナリオも、自分が未登録でも候補に加えるべき
            # (自分がGMをする可能性があるため)。
            # そのため、friends_wants_scenarios に含まれるIDも候補に追加する
            for sid in map_wants_play.keys():
                my_target_scenarios.add(sid)

        # レスポンス構築
        result_list = []
        for sid in my_target_scenarios:
            # 各リストを取得 (なければ空リスト)
            ng_users = map_ng.get(sid, [])
            play_users = map_wants_play.get(sid, [])
            poss_users = map_possessed.get(sid, [])
            gm_users = map_wants_gm.get(sid, [])
            
            result_list.append({
                'scenarioId': sid,
                'ngUserIds': ng_users,
                'wantsToPlayUserIds': play_users,
                'possessedUserIds': poss_users,
                'wantsToGmUserIds': gm_users
            })
        
        print(f"Returned Scenarios Count: {len(result_list)}")
        return json.dumps(result_list)

    except Exception as e:
        print(f"[ERROR] {e}")
        return json.dumps([])