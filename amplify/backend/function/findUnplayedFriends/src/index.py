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
    print("=== findUnplayedFriends START ===")
    print(f"Event: {json.dumps(event)}")

    try:
        # 1. リクエストパラメータの取得
        arguments = event.get('arguments', {})
        identity = event.get('identity', {})
        
        requesting_user_id = identity.get('sub')
        scenario_id = arguments.get('scenarioId')

        if not requesting_user_id or not scenario_id:
            raise ValueError("Invalid arguments or identity")

        # 2. 全フレンズIDの取得 (Query)
        response = user_relationship_table.query(
            KeyConditionExpression=Key('followingId').eq(requesting_user_id)
        )
        
        items = response.get('Items', [])
        friend_ids = [item['followedId'] for item in items]
        
        if not friend_ids:
            print("No friends found. Returning empty list.")
            return json.dumps([])

        # 3. BatchGetItemで各フレンズの UserScenario 状態を取得
        keys_to_get = [
            {'userId': friend_id, 'scenarioId': scenario_id} 
            for friend_id in friend_ids
        ]
        
        # ProjectionExpression に wantsToPlay を追加
        batch_response = dynamodb.batch_get_item(
            RequestItems={
                SCENARIO_TABLE: {
                    'Keys': keys_to_get,
                    'ProjectionExpression': 'userId, isPlayed, isPossessed, wantsToGm, wantsToPlay'
                }
            }
        )
        
        found_scenarios = batch_response.get('Responses', {}).get(SCENARIO_TABLE, [])
        
        # 4. メモリ上で突合・フィルタリング (未通過判定)
        played_or_registered_map = {}
        wants_to_play_map = {} # PL希望フラグ用

        for item in found_scenarios:
            uid = item['userId']
            is_played = item.get('isPlayed', False)
            is_possessed = item.get('isPossessed', False)
            wants_to_gm = item.get('wantsToGm', False)
            wants_to_play = item.get('wantsToPlay', False)
            
            # 何らかのステータスがあれば「登録済み」とみなす（未通過判定用）
            # wantsToPlay は未通過扱いなので、除外条件には含めない
            if is_played or is_possessed or wants_to_gm:
                played_or_registered_map[uid] = True
            
            if wants_to_play:
                wants_to_play_map[uid] = True

        # 未通過フレンズのIDリストを抽出
        unplayed_friend_ids = [
            fid for fid in friend_ids 
            if not played_or_registered_map.get(fid, False)
        ]
        
        if not unplayed_friend_ids:
            return json.dumps([])

        # 5. BatchGetItemで未通過フレンズのユーザー情報を取得
        user_keys = [{'id': uid} for uid in unplayed_friend_ids]
        
        user_batch_response = dynamodb.batch_get_item(
            RequestItems={
                USER_TABLE: {
                    'Keys': user_keys,
                    'ProjectionExpression': 'id, username, publicUserId, bio'
                }
            }
        )
        
        users = user_batch_response.get('Responses', {}).get(USER_TABLE, [])
        
        # クライアントへのレスポンス用に整形
        results = []
        for u in users:
            uid = u['id']
            results.append({
                'id': uid,
                'username': u.get('username', ''),
                'publicUserId': u.get('publicUserId', ''),
                'bio': u.get('bio', ''),
                'wantsToPlay': wants_to_play_map.get(uid, False) # PL希望フラグを追加
            })

        return json.dumps(results)

    except Exception as e:
        print(f"[ERROR] An exception occurred: {str(e)}")
        traceback.print_exc()
        return json.dumps([])