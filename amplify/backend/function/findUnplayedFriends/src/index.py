import json
import os
import boto3
from boto3.dynamodb.conditions import Key
import traceback

# 環境変数からテーブル名を取得
ENV = os.environ['ENV']
REGION = os.environ['REGION']
API_ID = os.environ['API_MYMADAMISAPP_GRAPHQLAPIIDOUTPUT']

# テーブル名の構築
USER_TABLE = f'User-{API_ID}-{ENV}'
RELATIONSHIP_TABLE = f'UserRelationship-{API_ID}-{ENV}'
SCENARIO_TABLE = f'UserScenario-{API_ID}-{ENV}'

dynamodb = boto3.resource('dynamodb', region_name=REGION)
user_relationship_table = dynamodb.Table(RELATIONSHIP_TABLE)
user_scenario_table = dynamodb.Table(SCENARIO_TABLE)
user_table = dynamodb.Table(USER_TABLE)

def handler(event, context):
    print("=== findUnplayedFriends START (v2.15) ===")
    print(f"Event: {json.dumps(event)}")

    try:
        # 1. リクエストパラメータの取得
        arguments = event.get('arguments', {})
        identity = event.get('identity', {})
        
        requesting_user_id = identity.get('sub')
        scenario_id = arguments.get('scenarioId')
        mode = arguments.get('mode', 'player')

        if not requesting_user_id or not scenario_id:
            raise ValueError("Invalid arguments or identity")

        # 2. 全フレンズIDの取得 (Query)
        response = user_relationship_table.query(
            KeyConditionExpression=Key('followingId').eq(requesting_user_id)
        )
        
        items = response.get('Items', [])
        friend_ids = [item['followedId'] for item in items]
        
        if not friend_ids:
            return json.dumps([])

        # 3. BatchGetItemで各フレンズの UserScenario 状態を取得
        keys_to_get = [
            {'userId': friend_id, 'scenarioId': scenario_id} 
            for friend_id in friend_ids
        ]
        
        batch_response = dynamodb.batch_get_item(
            RequestItems={
                SCENARIO_TABLE: {
                    'Keys': keys_to_get,
                    'ProjectionExpression': 'userId, isPlayed, isPossessed, wantsToGm, wantsToPlay'
                }
            }
        )
        
        found_scenarios = batch_response.get('Responses', {}).get(SCENARIO_TABLE, [])
        scenario_status_map = {item['userId']: item for item in found_scenarios}
        
        filtered_users = []

        for fid in friend_ids:
            status = scenario_status_map.get(fid, {})
            
            is_played = status.get('isPlayed', False)
            is_possessed = status.get('isPossessed', False)
            wants_to_gm = status.get('wantsToGm', False)
            wants_to_play = status.get('wantsToPlay', False)

            user_data = {
                'id': fid,
                'isPlayed': is_played,
                'isPossessed': is_possessed,
                'wantsToGm': wants_to_gm,
                'wantsToPlay': wants_to_play,
                'sortScore': 0 
            }

            if mode == 'gm':
                # 【v2.15 GM検索モード】
                # 対象: 所持 (isPossessed) OR 購入検討 (wantsToGm)
                # 変更点: 「通過済 (isPlayed)」のみのユーザーは除外する
                if is_possessed or wants_to_gm:
                    # 優先順位付け
                    if is_possessed:
                        user_data['sortScore'] = 30 # 最優先: 所持
                    elif wants_to_gm:
                        user_data['sortScore'] = 10 # 次点: 購入検討
                    
                    filtered_users.append(user_data)

            else:
                # 【PL検索モード】 (デフォルト)
                # 対象: 未通過 (レコードなし OR 全フラグfalse)
                is_registered_ng = is_played or is_possessed or wants_to_gm
                
                if not is_registered_ng:
                    # PL希望者を優先表示
                    if wants_to_play:
                        user_data['sortScore'] = 10
                    filtered_users.append(user_data)

        # ソート実行 (sortScoreの降順)
        filtered_users.sort(key=lambda x: x['sortScore'], reverse=True)
        
        target_user_ids = [u['id'] for u in filtered_users]
        
        if not target_user_ids:
            return json.dumps([])

        # 5. プロフィール情報の取得
        user_keys = [{'id': uid} for uid in target_user_ids]
        
        user_batch_response = dynamodb.batch_get_item(
            RequestItems={
                USER_TABLE: {
                    'Keys': user_keys,
                    'ProjectionExpression': 'id, username, publicUserId, bio'
                }
            }
        )
        
        users_info = user_batch_response.get('Responses', {}).get(USER_TABLE, [])
        users_map = {u['id']: u for u in users_info}
        
        results = []
        for f_user in filtered_users:
            uid = f_user['id']
            u_info = users_map.get(uid)
            if u_info:
                results.append({
                    'id': uid,
                    'username': u_info.get('username', ''),
                    'publicUserId': u_info.get('publicUserId', ''),
                    'bio': u_info.get('bio', ''),
                    'wantsToPlay': f_user['wantsToPlay'],
                    'isPlayed': f_user['isPlayed'],
                    'isPossessed': f_user['isPossessed'],
                    'wantsToGm': f_user['wantsToGm']
                })

        return json.dumps(results)

    except Exception as e:
        print(f"[ERROR] {e}")
        traceback.print_exc()
        return json.dumps([])