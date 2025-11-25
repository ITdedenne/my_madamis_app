import json
import os
import boto3
from concurrent.futures import ThreadPoolExecutor
from boto3.dynamodb.conditions import Key, Attr

# --- 環境変数 ---
ENV = os.environ['ENV']
REGION = os.environ['REGION']
API_ID = os.environ['API_MYMADAMISAPP_GRAPHQLAPIIDOUTPUT']

# --- テーブル名 ---
USER_SCENARIO_TABLE_NAME = f'UserScenario-{API_ID}-{ENV}'
USER_RELATIONSHIP_TABLE_NAME = f'UserRelationship-{API_ID}-{ENV}'

# --- AWS リソース ---
dynamodb = boto3.resource('dynamodb', region_name=REGION)
user_scenario_table = dynamodb.Table(USER_SCENARIO_TABLE_NAME)
user_relationship_table = dynamodb.Table(USER_RELATIONSHIP_TABLE_NAME)

def fetch_user_status(user_id):
    """指定ユーザーのステータスを取得"""
    try:
        response = user_scenario_table.query(
            IndexName='byUser',
            KeyConditionExpression=Key('userId').eq(user_id),
            FilterExpression=Attr('isPlayed').eq(True) | Attr('isPossessed').eq(True) | Attr('wantsToGm').eq(True) | Attr('wantsToPlay').eq(True),
            ProjectionExpression='scenarioId, isPlayed, isPossessed, wantsToGm, wantsToPlay'
        )
        return user_id, response.get('Items', [])
    except Exception as e:
        print(f"Error fetching status for user {user_id}: {e}")
        return user_id, []

def handler(event, context):
    print("=== findGroupScenarios START (V4 Split & Fix) ===")
    
    try:
        arguments = event.get('arguments', {})
        identity = event.get('identity', {})
        
        requesting_user_id = identity.get('sub')
        selected_friend_ids = set(arguments.get('friendIds', []))
        
        if not requesting_user_id:
            raise ValueError("Unauthorized")

        # 1. 全フレンドを取得 (外部GM候補用)
        rel_response = user_relationship_table.query(
            KeyConditionExpression=Key('followingId').eq(requesting_user_id)
        )
        all_friend_ids = {item['followedId'] for item in rel_response.get('Items', [])}
        
        # 検索対象: A(選択メンバー), B(外部フレンド)
        target_members = selected_friend_ids | {requesting_user_id}
        other_friends = all_friend_ids - selected_friend_ids
        all_targets = target_members | other_friends
        
        # 2. 並列データ取得
        user_status_map = {}
        with ThreadPoolExecutor(max_workers=20) as executor:
            futures = [executor.submit(fetch_user_status, uid) for uid in all_targets]
            for future in futures:
                uid, items = future.result()
                user_status_map[uid] = items

        # 3. 集計用データ構造
        # metadata = { scenarioId: { 'ng': [], 'wants': [], 'ext': [] } }
        metadata = {}

        def get_meta(sid):
            if sid not in metadata:
                metadata[sid] = {'ng': [], 'wants': [], 'ext': []}
            return metadata[sid]

        # A. 選択メンバー (NG判定 & PL希望)
        for uid in target_members:
            items = user_status_map.get(uid, [])
            for item in items:
                sid = item['scenarioId']
                
                # NG判定 (通過済/所持/GM検討)
                if item.get('isPlayed') or item.get('isPossessed') or item.get('wantsToGm'):
                    get_meta(sid)['ng'].append(uid)
                
                # PL希望
                if item.get('wantsToPlay'):
                    get_meta(sid)['wants'].append(uid)

        # B. 選択外フレンド (外部GM候補)
        for uid in other_friends:
            items = user_status_map.get(uid, [])
            for item in items:
                sid = item['scenarioId']
                if item.get('isPossessed') or item.get('wantsToGm'):
                    get_meta(sid)['ext'].append(uid)

        # 4. レスポンス整形
        response_list = []
        for sid, data in metadata.items():
            response_list.append({
                'scenarioId': sid,
                'ngUserIds': data['ng'],
                'wantsToPlayUserIds': data['wants'],
                'externalHolderUserIds': data['ext']
            })

        # V4では単純なリスト形式で返す（クライアント側で結合するため）
        print(f"Result Count: {len(response_list)}")
        return json.dumps(response_list)

    except Exception as e:
        print(f"[ERROR] {e}")
        return json.dumps([])