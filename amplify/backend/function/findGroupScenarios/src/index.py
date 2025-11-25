import json
import os
import boto3
import time
from concurrent.futures import ThreadPoolExecutor
from boto3.dynamodb.conditions import Key, Attr

# --- 環境変数 ---
ENV = os.environ['ENV']
REGION = os.environ['REGION']
API_ID = os.environ['API_MYMADAMISAPP_GRAPHQLAPIIDOUTPUT']
BUCKET_NAME = os.environ.get('STORAGE_MADAMISAPPS3_BUCKETNAME') 

# --- 定数 ---
SCENARIOS_JSON_KEY = 'Scenarios.json'
VERSION_JSON_KEY = 'version.json'
USER_SCENARIO_TABLE_NAME = f'UserScenario-{API_ID}-{ENV}'

# --- グローバルキャッシュ (コンテナ再利用時用) ---
_cached_scenarios = None
_cached_version = None

# --- AWS リソース ---
s3_client = boto3.client('s3', region_name=REGION)
dynamodb_resource = boto3.resource('dynamodb', region_name=REGION)
user_scenario_table = dynamodb_resource.Table(USER_SCENARIO_TABLE_NAME)

def get_master_data():
    """S3からマスターデータを取得"""
    global _cached_scenarios, _cached_version
    try:
        version_obj = s3_client.get_object(Bucket=BUCKET_NAME, Key=VERSION_JSON_KEY)
        current_version = json.loads(version_obj['Body'].read().decode('utf-8'))

        if _cached_scenarios and _cached_version == current_version:
            print("Using cached scenarios.json")
            return _cached_scenarios

        print("Downloading scenarios.json from S3...")
        scenarios_obj = s3_client.get_object(Bucket=BUCKET_NAME, Key=SCENARIOS_JSON_KEY)
        _cached_scenarios = json.loads(scenarios_obj['Body'].read().decode('utf-8'))
        _cached_version = current_version
        return _cached_scenarios
    except Exception as e:
        print(f"Error fetching master data: {e}")
        return _cached_scenarios if _cached_scenarios else []

def fetch_friend_status(user_id):
    """
    指定ユーザーのステータスを取得し、NGセットとWantsセットを返す
    Returns: (ng_set, wants_set)
    """
    ng_set = set()
    wants_set = set()
    
    try:
        # 検索対象: NG条件(既知/所持/GM検討) または PL希望(wantsToPlay)
        # コスト最適化: 1回のクエリで両方の情報を取得する
        response = user_scenario_table.query(
            IndexName='byUser',
            KeyConditionExpression=Key('userId').eq(user_id),
            FilterExpression=Attr('isPlayed').eq(True) | Attr('isPossessed').eq(True) | Attr('wantsToGm').eq(True) | Attr('wantsToPlay').eq(True),
            ProjectionExpression='scenarioId, isPlayed, isPossessed, wantsToGm, wantsToPlay'
        )
        
        for item in response.get('Items', []):
            sid = item['scenarioId']
            # NG判定 (通過済・所持・GM検討 はNG)
            if item.get('isPlayed') or item.get('isPossessed') or item.get('wantsToGm'):
                ng_set.add(sid)
            # PL希望判定 (NG条件に引っかかっていない場合のみ有効とする運用も考えられるが、
            # データ構造的には独立しているので個別にチェックして追加)
            elif item.get('wantsToPlay'):
                wants_set.add(sid)
                
        return ng_set, wants_set
        
    except Exception as e:
        print(f"Error fetching status for friend {user_id}: {e}")
        return set(), set()

def fetch_my_target_list(user_id):
    """自分の対象リスト（所持 OR GM検討 OR PL希望）を取得"""
    try:
        response = user_scenario_table.query(
            IndexName='byUser',
            KeyConditionExpression=Key('userId').eq(user_id),
            FilterExpression=Attr('isPossessed').eq(True) | Attr('wantsToGm').eq(True) | Attr('wantsToPlay').eq(True),
            ProjectionExpression='scenarioId'
        )
        return {item['scenarioId'] for item in response.get('Items', [])}
    except Exception as e:
        print(f"Error fetching target list for user {user_id}: {e}")
        return set()

def handler(event, context):
    print("=== findGroupScenarios START (v2.14 Enhanced) ===")

    try:
        arguments = event.get('arguments', {})
        identity = event.get('identity', {})
        
        requesting_user_id = identity.get('sub')
        friend_ids = arguments.get('friendIds', []) 

        if not requesting_user_id:
            raise ValueError("Unauthorized")
        if len(friend_ids) > 8:
             raise ValueError("Too many friends selected (Max 8).")

        # 並列処理でデータ取得
        with ThreadPoolExecutor(max_workers=10) as executor:
            # 自分のリスト取得
            my_list_future = executor.submit(fetch_my_target_list, requesting_user_id)
            
            # フレンズのステータス取得 (NGリストとPL希望リスト)
            friend_futures = {fid: executor.submit(fetch_friend_status, fid) for fid in friend_ids}

            my_target_scenarios = my_list_future.result()
            
            friends_ng_scenarios = set()
            friends_wants_scenarios = set() # 誰か一人でもPL希望しているシナリオID
            
            for fid, future in friend_futures.items():
                ng_set, wants_set = future.result()
                friends_ng_scenarios.update(ng_set)
                friends_wants_scenarios.update(wants_set)

        # 候補選定: (自分が持ってる等) - (誰かが通過済等)
        final_candidates_ids = my_target_scenarios - friends_ng_scenarios
        
        # レスポンス構築: オブジェクトのリストを返す
        result_list = []
        for sid in final_candidates_ids:
            result_list.append({
                'scenarioId': sid,
                'isFriendWantsToPlay': sid in friends_wants_scenarios
            })
        
        print(f"Matched Scenarios Count: {len(result_list)}")

        return json.dumps(result_list)

    except Exception as e:
        print(f"[ERROR] {e}")
        # エラー時は空リストを返す
        return json.dumps([])