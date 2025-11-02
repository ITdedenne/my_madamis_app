import os
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')

# (getMyScenarioLogbookFunc と同じ環境変数とテーブル定義)
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
    指定された (他人の) userId のマイリストを結合して返す
    """
    try:
        # 1. 引数から対象のユーザーIDを取得
        user_id = event['arguments']['userId']
        
        print(f"getUserScenarioLogbook: ユーザーID {user_id} の処理を開始")

        # 2. UserScenarioテーブルをGSI(byUser)でQuery
        response = user_scenario_table.query(
            IndexName='byUser', #
            KeyConditionExpression=Key('userId').eq(user_id)
        )
        user_scenarios = response.get('Items', [])

        if not user_scenarios:
            return []

        # 3. BatchGet (getMyScenarioLogbook と同じロジック)
        scenario_ids = list(set([us['scenarioId'] for us in user_scenarios]))
        scenario_map = _batch_get_items(scenario_table, scenario_ids)
        author_ids = list(set([s['authorId'] for s in scenario_map.values() if 'authorId' in s]))
        author_map = _batch_get_items(author_table, author_ids)

        # 4. データを結合 (getMyScenarioLogbook と同じロジック)
        result = []
        for us in user_scenarios:
            scenario = scenario_map.get(us['scenarioId'])
            if not scenario:
                continue
            author = author_map.get(scenario.get('authorId'))

            entry = {
                'id': us['id'],
                'title': scenario.get('title'),
                'minPlayerCount': scenario.get('minPlayerCount'),
                'maxPlayerCount': scenario.get('maxPlayerCount'),
                'gmRequirement': scenario.get('gmRequirement'),
                'storeUrl': scenario.get('storeUrl'),
                'authorId': scenario.get('authorId'),
                'authorName': author.get('authorName') if author else None,
                'isPlayed': us.get('isPlayed', False),
                'isPossessed': us.get('isPossessed', False),
            }
            result.append({k: v for k, v in entry.items() if v is not None})

        print(f"処理完了: {len(result)} 件のマイリストを返します。")
        return result

    except Exception as e:
        print(f"エラーが発生しました: {e}")
        raise Exception(f"ユーザーのマイリスト取得に失敗しました: {e}")


def _batch_get_items(table, keys):
    """(getMyScenarioLogbookFunc と同じヘルパー関数)"""
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