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
    print(f"Target Tables: {USER_TABLE}, {RELATIONSHIP_TABLE}, {SCENARIO_TABLE}")

    try:
        # 1. リクエストパラメータの取得
        arguments = event.get('arguments', {})
        identity = event.get('identity', {})
        
        requesting_user_id = identity.get('sub')
        scenario_id = arguments.get('scenarioId')

        print(f"Requesting User ID: {requesting_user_id}")
        print(f"Scenario ID: {scenario_id}")

        if not requesting_user_id or not scenario_id:
            raise ValueError("Invalid arguments or identity")

        # 2. 全フレンズIDの取得 (Query)
        # followingId (PK) でクエリして followedId (フレンズ) を取得
        print(f"Querying UserRelationship table for followingId: {requesting_user_id}")
        response = user_relationship_table.query(
            KeyConditionExpression=Key('followingId').eq(requesting_user_id)
        )
        
        items = response.get('Items', [])
        friend_ids = [item['followedId'] for item in items]
        print(f"Found {len(friend_ids)} friends: {friend_ids}")
        
        if not friend_ids:
            print("No friends found. Returning empty list.")
            return json.dumps([])

        # 3. BatchGetItemで各フレンズの UserScenario 状態を取得
        
        # BatchGetItem用のキーリスト作成
        keys_to_get = [
            {'userId': friend_id, 'scenarioId': scenario_id} 
            for friend_id in friend_ids
        ]
        
        print(f"BatchGetItem Keys ({len(keys_to_get)}): {keys_to_get}")

        # BatchGetItem実行
        # 注意: SCENARIO_TABLE 変数が実際のDynamoDBテーブル名と完全に一致している必要があります
        batch_response = dynamodb.batch_get_item(
            RequestItems={
                SCENARIO_TABLE: {
                    'Keys': keys_to_get,
                    'ProjectionExpression': 'userId, isPlayed, isPossessed, wantsToGm'
                }
            }
        )
        
        found_scenarios = batch_response.get('Responses', {}).get(SCENARIO_TABLE, [])
        print(f"BatchGetItem Response Items ({len(found_scenarios)}): {found_scenarios}")
        
        # UnprocessedKeysのチェック（念のため）
        unprocessed = batch_response.get('UnprocessedKeys', {})
        if unprocessed:
            print(f"WARNING: There were unprocessed keys: {unprocessed}")

        # 4. メモリ上で突合・フィルタリング (未通過判定)
        played_or_registered_map = {}
        for item in found_scenarios:
            uid = item['userId']
            is_played = item.get('isPlayed', False)
            is_possessed = item.get('isPossessed', False)
            wants_to_gm = item.get('wantsToGm', False)
            
            # 何らかのステータスがあれば「登録済み」とみなす
            if is_played or is_possessed or wants_to_gm:
                played_or_registered_map[uid] = True

        print(f"Registered Map: {played_or_registered_map}")

        # 未通過フレンズのIDリストを抽出
        # (レコードが存在しない OR レコードはあるが全てFalse)
        unplayed_friend_ids = [
            fid for fid in friend_ids 
            if not played_or_registered_map.get(fid, False)
        ]
        
        print(f"Unplayed Friend IDs ({len(unplayed_friend_ids)}): {unplayed_friend_ids}")

        if not unplayed_friend_ids:
            print("All friends have played/registered this scenario. Returning empty list.")
            return json.dumps([])

        # 5. BatchGetItemで未通過フレンズのユーザー情報を取得
        user_keys = [{'id': uid} for uid in unplayed_friend_ids]
        
        print(f"Fetching User Info for keys: {user_keys}")
        
        user_batch_response = dynamodb.batch_get_item(
            RequestItems={
                USER_TABLE: {
                    'Keys': user_keys,
                    'ProjectionExpression': 'id, username, publicUserId, bio'
                }
            }
        )
        
        users = user_batch_response.get('Responses', {}).get(USER_TABLE, [])
        print(f"Fetched Users ({len(users)}): {users}")
        
        # クライアントへのレスポンス用に整形
        results = []
        for u in users:
            results.append({
                'id': u['id'],
                'username': u.get('username', ''),
                'publicUserId': u.get('publicUserId', ''),
                'bio': u.get('bio', '')
            })

        print(f"Returning results: {json.dumps(results)}")
        return json.dumps(results)

    except Exception as e:
        print(f"[ERROR] An exception occurred: {str(e)}")
        traceback.print_exc()
        # エラー時もGraphQLの仕様上Stringを返す必要があるため、空リストを返す
        # (本番ではエラーハンドリングを検討すべきですが、まずはログを確認します)
        return json.dumps([])