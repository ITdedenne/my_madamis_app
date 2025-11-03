import os
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')

# 環境変数からテーブル名を取得
try:
    # 修正: USER_SCENARIO_TABLE_NAME の環境変数名を NewUserScenario に変更
    USER_SCENARIO_TABLE_NAME = os.environ['API_MYMADAMISAPP_NEWUSERSCENARIOTABLE_NAME']
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
        # @index(name: "byUser") が userId に設定されているため、GSI名も 'byUser' のまま
        # NewUserScenario の GSI 名は byUser のままであることを前提とします。
        response = user_scenario_table.query(
            IndexName='byUser', # schema.graphql の @index(name: "byUser")
            KeyConditionExpression=Key('userId').eq(user_id)
        )
        
        user_scenarios = response.get('Items', [])
        print(f"UserScenario から {len(user_scenarios)} 件のレコードを取得。")

        if not user_scenarios:
            return []

        # 3. シナリオIDリストを抽出
        scenario_ids = [us['scenarioId'] for us in user_scenarios]
        
        # 4. シナリオ情報を BatchGetItem で一括取得 (N+1問題の「N」の部分)
        scenario_items = _batch_get_items(scenario_table, scenario_ids)
        
        # 5. Author ID リストを抽出
        author_ids = [item['authorId'] for item in scenario_items.values() if 'authorId' in item]

        # 6. Author 情報を BatchGetItem で一括取得
        author_items = _batch_get_items(author_table, author_ids)

        # 7. データを結合してレスポンス形式に変換
        result = []
        for us in user_scenarios:
            scenario_id = us['scenarioId']
            scenario = scenario_items.get(scenario_id)

            if not scenario:
                continue # シナリオデータがない場合はスキップ

            # Author 名を取得
            author = author_items.get(scenario.get('authorId'))
            
            entry = {
                'id': scenario['id'],
                'title': scenario['title'],
                'minPlayerCount': scenario.get('minPlayerCount'),
                'maxPlayerCount': scenario.get('maxPlayerCount'),
                'gmRequirement': scenario.get('gmRequirement'),
                'storeUrl': scenario.get('storeUrl'),
                'authorId': scenario.get('authorId'),
                'authorName': author.get('authorName') if author else None,
                
                # UserScenario のフィールド
                'isPlayed': us.get('isPlayed', False),
                'isPossessed': us.get('isPossessed', False),
                'createdAt': us.get('createdAt'), # ソート用にタイムスタンプを追加
                'updatedAt': us.get('updatedAt'), # ソート用にタイムスタンプを追加
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
                    # DynamoDBのPKが id のため、id でクエリします
                    'Keys': [{'id': k} for k in chunk]
                }
            }
        )
        items.extend(response['Responses'].get(table.name, []))
        
        # UnprocessedKeysの処理 (ここでは簡略化のため省略)
        
    # idをキーとする辞書に変換
    return {item['id']: item for item in items}