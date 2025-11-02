import json
import boto3
import os
import csv
import io
import urllib.parse # S3キーのURLデコード用

# S3とDynamoDBのクライアントを初期化
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

# Amplifyが自動で設定する環境変数からテーブル名を取得
try:
    AUTHOR_TABLE_NAME = os.environ['API_MYMADAMISAPP_AUTHORTABLE_NAME']
    SCENARIO_TABLE_NAME = os.environ['API_MYMADAMISAPP_SCENARIOTABLE_NAME']
    
    AUTHOR_TABLE = dynamodb.Table(AUTHOR_TABLE_NAME)
    SCENARIO_TABLE = dynamodb.Table(SCENARIO_TABLE_NAME)

except KeyError as e:
    print(f"環境変数が設定されていません: {e}")
    # このエラーは Lambda の設定ミス（APIへの権限付与忘れ）で発生します

def handler(event, context):
    print('S3トリガーイベント受信:')
    print(json.dumps(event))

    try:
        # 1. S3イベントからバケット名とファイル名を取得
        record = event['Records'][0]
        bucket = record['s3']['bucket']['name']
        
        # ファイル名が日本語などを含む場合、URLエンコードされているためデコードする
        key = urllib.parse.unquote_plus(record['s3']['object']['key'], encoding='utf-8')
        
        print(f"処理対象ファイル: {bucket} / {key}")

        # 2. ファイル名で処理を分岐
        if key.endswith('Authors.csv') or key.endswith('authors.csv'):
            print("Authors.csv を処理します。")
            process_csv(s3, bucket, key, AUTHOR_TABLE, 'author')
        
        elif key.endswith('Scenarios.csv') or key.endswith('scenarios.csv'):
            # (1).csv のようなファイル名にも対応
            print("Scenarios.csv を処理します。")
            process_csv(s3, bucket, key, SCENARIO_TABLE, 'scenario')
            
        else:
            print("処理対象外のファイルです。")
            return {'statusCode': 200, 'body': 'Not a target file.'}

        print("処理が正常に完了しました。")
        return {'statusCode': 200, 'body': json.dumps('CSV import successful!')}

    except Exception as e:
        print(f"エラーが発生しました: {e}")
        raise e

def process_csv(s3_client, bucket, key, table, data_type):
    """S3からCSVを読み取り、DynamoDBにバッチ書き込みする"""
    
    item_count = 0
    try:
        # S3からファイルオブジェクトを取得
        obj = s3_client.get_object(Bucket=bucket, Key=key)
        
        # CSVデータをUTF-8 (BOM付き対応) でデコード
        try:
            body = obj['Body'].read().decode('utf-8-sig')
        except UnicodeDecodeError:
            print("UTF-8-SIGデコード失敗。CP932で再試行します。")
            body = obj['Body'].read().decode('cp932')
            
        csv_data = io.StringIO(body)
        reader = csv.reader(csv_data)
        
        # ヘッダー行を読み飛ばす
        header = next(reader)
        print(f"CSVヘッダー: {header}")

        # DynamoDBのバッチライターを使用して効率的に書き込む
        with table.batch_writer() as batch:
            for row in reader:
                item = None
                try:
                    if data_type == 'author':
                        # Authors.csv のカラムマッピング
                        item = {
                            'id': row[0],         # authorId
                            'authorName': row[1]  # authorName
                        }
                    
                    elif data_type == 'scenario':
                        # Scenarios.csv のカラムマッピング
                        
                        # --- ▼▼▼ここが修正点▼▼▼ ---
                        gm_req_value = row[4].upper() if row[4] else 'NONE' # 大文字に統一
                        if gm_req_value not in ['REQUIRED', 'OPTIONAL', 'NONE']:
                            print(f"不明なgmRequirement値: {row[4]}。NONEとして扱います。")
                            gm_req_value = 'NONE'
                        # --- ▲▲▲ここまで修正点▲▲▲ ---
                        
                        item = {
                            'id': row[0],
                            'title': row[1],
                            'minPlayerCount': convert_to_int(row[2]),
                            'maxPlayerCount': convert_to_int(row[3]),
                            'gmRequirement': gm_req_value, # <== 修正点: Enumの文字列をそのままセット
                            'authorId': row[5],
                            'storeUrl': row[6] if row[6] else None,
                        }
                        
                except IndexError as ie:
                    print(f"CSVの行 {row} のカラムが不足しています: {ie}")
                    continue

                if item:
                    # 空白のキー（例: storeUrl: None）はDynamoDBに送らない
                    clean_item = {k: v for k, v in item.items() if v is not None}
                    batch.put_item(Item=clean_item)
                    item_count += 1
        
        print(f"{item_count} 件の {data_type} アイテムを書き込みました。")

    except Exception as e:
        print(f"CSV処理中にエラー: {e}")
        raise

def convert_to_int(value_str):
    """CSVの文字列を数値(Int)に変換する。空白はNoneにする。"""
    if value_str:
        try:
            return int(value_str)
        except ValueError:
            print(f"数値変換エラー: {value_str}")
            return None
    return None

# 'convert_to_bool' 関数は不要になったので削除しました。