import os
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')

try:
    USER_SCENARIO_TABLE_NAME = os.environ['API_MYMADAMISAPP_USERSCENARIOTABLE_NAME']
    SCENARIO_TABLE_NAME = os.environ['API_MYMADAMISAPP_SCENARIOTABLE_NAME']
    AUTHOR_TABLE_NAME = os.environ['API_MYMADAMISAPP_AUTHORTABLE_NAME']
except KeyError:
    raise Exception("環境変数が設定されていません。Lambdaの権限を確認してください。")

user_scenario_table = dynamodb.Table(USER_SCENARIO_TABLE_NAME)
scenario_table = dynamodb.Table(SCENARIO_TABLE_NAME)
author_table = dynamodb.Table(AUTHOR_TABLE_NAME)

def handler(event, context):
    """
    全シナリオ一覧と、それに対する「ログイン中ユーザーの」ステータスを結合して返す
    """
    try:
        # 1. ログイン中のユーザーID (sub) を取得
        user_id = event['identity']['sub']
        # TODO: filter, sort, nextToken を引数から取得
        # filter = event['arguments'].get('filter')
        
        print(f"listScenariosWithMyStatus: ユーザーID {user_id} の処理を開始")

        # 2. 【ステップ1】まずログイン中ユーザーのステータスを全て取得
        response = user_scenario_table.query(
            IndexName='byUser', #
            KeyConditionExpression=Key('userId').eq(user_id)
        )
        user_scenarios = response.get('Items', [])
        
        # 扱いやすいよう {scenarioId: status_item} の辞書(Map)にする
        status_map = {us['scenarioId']: us for us in user_scenarios}
        print(f"ユーザーのステータスを {len(status_map)} 件取得")

        # 3. 【ステップ2】全シナリオを取得 (Scan)
        # ※ パフォーマンス注意: 本番アプリではScanは非推奨。
        #    ここでは要件(1.2.1)に基づきScanを使用。将来的にはOpenSearch等での検索を推奨。
        # TODO: 引数(nextToken) に基づくページネーション処理を追加
        scenario_response = scenario_table.scan() # TODO: filter, sort, pagination
        all_scenarios = scenario_response.get('Items', [])
        
        # 4. 【ステップ3】作者情報を一括取得
        author_ids = list(set([s['authorId'] for s in all_scenarios if 'authorId' in s]))
        author_map = _batch_get_items(author_table, author_ids)

        # 5. 【ステップ4】データを結合
        result_items = []
        for scenario in all_scenarios:
            my_status = status_map.get(scenario['id'])
            author = author_map.get(scenario.get('authorId'))

            entry = {
                # schema.graphql の ScenarioWithMyStatus の型に合わせる
                'id': scenario['id'],
                'title': scenario.get('title'),
                'minPlayerCount': scenario.get('minPlayerCount'),
                'maxPlayerCount': scenario.get('maxPlayerCount'),
                'gmRequirement': scenario.get('gmRequirement'),
                'storeUrl': scenario.get('storeUrl'),
                'authorId': scenario.get('authorId'),
                'authorName': author.get('authorName') if author else None,
                
                # ユーザーのステータス（存在すれば）
                'isPlayed': my_status.get('isPlayed') if my_status else None,
                'isPossessed': my_status.get('isPossessed') if my_status else None,
            }
            result_items.append({k: v for k, v in entry.items() if v is not None})

        # 6. Connection 型 で返す
        result = {
            'items': result_items,
            'nextToken': scenario_response.get('LastEvaluatedKey') # TODO: ページネーション対応
        }
        
        print(f"処理完了: {len(result_items)} 件のシナリオを返します。")
        return result

    except Exception as e:
        print(f"エラーが発生しました: {e}")
        raise Exception(f"シナリオ一覧の取得に失敗しました: {e}")

def _batch_get_items(table, keys):
    """DynamoDBのBatchGetItemをラッパーし、100件制限を自動で処理する"""
    if not keys:
        return {}
    items = []
    keys_to_fetch = list(set(keys))
    while keys_to_fetch:
        chunk = keys_to_fetch[:100]
        keys_to_fetch = keys_to_fetch[100:]
        response = dynamodb.batch_get_item(
            RequestItems={
                table.name: {
                    'Keys': [{'id': k} for k in chunk]
                }
            }
        )
        items.extend(response['Responses'].get(table.name, []))
        unprocessed = response.get('UnprocessedKeys', {}).get(table.name, {}).get('Keys', [])
        if unprocessed:
            keys_to_fetch.extend([k['id'] for k in unprocessed])
    return {item['id']: item for item in items}