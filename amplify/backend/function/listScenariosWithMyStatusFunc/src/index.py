import os
import boto3
from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError
import json

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
    全てのシナリオ一覧を取得し、ログインユーザーのプレイ/所持ステータスを結合して返す
    """
    try:
        # 1. ログイン中のユーザーID (sub) を取得
        user_id = event['identity']['sub'] if event.get('identity') and event['identity'].get('sub') else None
        
        # 2. クエリパラメータの取得
        args = event.get('arguments', {})
        filter_str = args.get('filter')
        # ... sort や nextToken もあれば処理
        
        print(f"listScenariosWithMyStatus: ユーザーID {user_id} の処理を開始")
        
        # 3. 全シナリオ一覧をスキャンまたはクエリ（今回は簡略化のためスキャンを前提）
        # 本来は Scenario モデルの適切なインデックスを使用してクエリすべきです
        scan_kwargs = {}
        if args.get('nextToken'):
            scan_kwargs['ExclusiveStartKey'] = {'id': args['nextToken']}

        # DynamoDB の Scan を実行 (ここでは filter は無視し、シナリオ一覧をページング)
        response = scenario_table.scan(
            Limit=20, # 例として20件に制限
            **scan_kwargs
        )
        
        scenarios = response.get('Items', [])
        next_token = response.get('LastEvaluatedKey', {}).get('id') if response.get('LastEvaluatedKey') else None
        
        # 4. 著者IDリストを抽出
        author_ids = [s['authorId'] for s in scenarios if 'authorId' in s]
        author_items = _batch_get_items(author_table, author_ids)
        
        # 5. UserScenario のステータス情報を一括取得
        scenario_statuses = {}
        if user_id and scenarios:
            # NewUserScenario の PK は userId (Partition Key) と scenarioId (Sort Key) の複合キー
            keys_to_fetch = []
            for s in scenarios:
                keys_to_fetch.append({
                    'userId': user_id,
                    'scenarioId': s['id']
                })
            
            # UserScenario の BatchGetItem を実行
            user_scenario_statuses = _batch_get_items_composite(user_scenario_table, keys_to_fetch)
            
            # scenario_id をキーとしてステータス情報を格納
            scenario_statuses = {item['scenarioId']: item for item in user_scenario_statuses}

        # 6. データ結合とレスポンス形式への変換
        result_items = []
        for s in scenarios:
            status = scenario_statuses.get(s['id'], {})
            author = author_items.get(s.get('authorId'))
            
            item = {
                'id': s['id'],
                'title': s['title'],
                # ... 他のシナリオフィールド
                'authorId': s.get('authorId'),
                'author': author, # Author オブジェクトをそのままネスト
                
                # ステータス情報（見つからない場合は False/None）
                'isPlayed': status.get('isPlayed', False),
                'isPossessed': status.get('isPossessed', False),
            }
            # None のキーを削除 (DynamoDBはNoneを許容しないため)
            result_items.append({k: v for k, v in item.items() if v is not None})
            
        return {
            'items': result_items,
            'nextToken': next_token
        }

    except Exception as e:
        print(f"エラーが発生しました: {e}")
        raise Exception(f"シナリオ一覧の取得に失敗しました: {e}")


def _batch_get_items(table, keys):
    """シンプルな BatchGetItem (PKが id のテーブル用)"""
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
        
    return {item['id']: item for item in items}


def _batch_get_items_composite(table, keys_list):
    """複合キー（PartitionKey + SortKey）用の BatchGetItem"""
    if not keys_list:
        return []
        
    items = []
    # keys_list は [{'userId': 'sub_id', 'scenarioId': 'id1'}, ...] 形式を想定
    
    while keys_list:
        chunk = keys_list[:100]
        keys_list = keys_list[100:]
        
        response = dynamodb.batch_get_item(
            RequestItems={
                table.name: {
                    # 複合キーのキー名を明示的に指定
                    'Keys': chunk 
                }
            }
        )
        items.extend(response['Responses'].get(table.name, []))
        
    return items