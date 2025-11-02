import os
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')

# 環境変数からテーブル名を取得
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
    ログイン中ユーザーのマイリスト（シナリオ情報＋ステータス）を結合して返す
    """
    try:
        # 1. ログイン中のユーザーID (sub) を取得
        user_id = event['identity']['sub']
        
        print(f"getMyScenarioLogbook: ユーザーID {user_id} の処理を開始")

        # 2. UserScenarioテーブルをGSI(byUser)でQueryし、ユーザーの全関連を取得
        # (N+1問題の「1」の部分)
        response = user_scenario_table.query(
            IndexName='byUser', # schema.graphql の @index(name: "byUser")
            KeyConditionExpression=Key('userId').eq(user_id)
        )
        user_scenarios = response.get('Items', [])

        if not user_scenarios:
            print("このユーザーのシナリオ登録はありません。")
            return []

        # 3. 取得した全scenarioIdをリスト化
        scenario_ids = list(set([us['scenarioId'] for us in user_scenarios]))
        
        # 4. ScenarioテーブルからBatchGetItemで全シナリオ情報を一括取得
        # (N+1問題の「N」を「1」にまとめる)
        scenario_map = _batch_get_items(scenario_table, scenario_ids)
        
        # 5. AuthorテーブルからBatchGetItemで全作者情報を一括取得
        author_ids = list(set([s['authorId'] for s in scenario_map.values() if 'authorId' in s]))
        author_map = _batch_get_items(author_table, author_ids)

        # 6. Lambda内でデータを結合（JOIN）し、FEが欲しい型に整形
        result = []
        for us in user_scenarios:
            scenario = scenario_map.get(us['scenarioId'])
            
            # データ不整合（UserScenarioはあるがScenario本体がない）でもクラッシュさせない
            if not scenario:
                print(f"警告: Scenario ID {us['scenarioId']} が見つかりません。")
                continue
                
            author = author_map.get(scenario.get('authorId'))

            entry = {
                # schema.graphql の ScenarioLogbookEntry の型に合わせる
                'id': us['id'], # UserScenario の ID
                'title': scenario.get('title'),
                'minPlayerCount': scenario.get('minPlayerCount'),
                'maxPlayerCount': scenario.get('maxPlayerCount'),
                'gmRequirement': scenario.get('gmRequirement'),
                'storeUrl': scenario.get('storeUrl'),
                'authorId': scenario.get('authorId'),
                'authorName': author.get('authorName') if author else None,
                
                # UserScenario のフィールド
                'isPlayed': us.get('isPlayed', False),
                'isPossessed': us.get('isPossessed', False),
                # 'createdAt' や 'updatedAt' も必要なら追加
            }
            # None のキーを削除 (DynamoDBはNoneを許容しないため)
            result.append({k: v for k, v in entry.items() if v is not None})

        print(f"処理完了: {len(result)} 件のマイリストを返します。")
        return result

    except Exception as e:
        print(f"エラーが発生しました: {e}")
        # FEにエラーを返す
        raise Exception(f"マイリストの取得に失敗しました: {e}")


def _batch_get_items(table, keys):
    """DynamoDBのBatchGetItemをラッパーし、100件制限を自動で処理する"""
    if not keys:
        return {}
        
    items = []
    keys_to_fetch = list(set(keys)) # 重複排除
    
    while keys_to_fetch:
        # 100件ずつ分割
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
        
        # UnprocessedKeysが残っていれば次のループで処理
        unprocessed = response.get('UnprocessedKeys', {}).get(table.name, {}).get('Keys', [])
        if unprocessed:
            keys_to_fetch.extend([k['id'] for k in unprocessed])

    # 扱いやすいように {id: item} の辞書(Map)にして返す
    return {item['id']: item for item in items}