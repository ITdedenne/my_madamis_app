# amplify/backend/function/csvImporterFunction/src/index.py

import json
import boto3
import csv
import io
import logging
import os
import urllib.parse
from datetime import datetime, timezone

# --- Logger Setup ---
logger = logging.getLogger()
# ログレベルをINFOに設定 (デバッグ時はDEBUGに変更可能)
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO').upper())


# --- AWS Client Initialization ---
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

# --- Environment Variable Acquisition ---
# backend-config.json で指定した Function の dependsOn から自動的に設定される
# 環境変数名を確認するには amplify status -v を実行
SCENARIO_TABLE_NAME = os.environ.get('API_MYMADAMISAPP_SCENARIOTABLE_NAME')
AUTHOR_TABLE_NAME = os.environ.get('API_MYMADAMISAPP_AUTHORTABLE_NAME')

if not SCENARIO_TABLE_NAME:
    logger.error("Environment variable 'API_MYMADAMISAPP_SCENARIOTABLE_NAME' not found.")
    # 必要に応じて raise ValueError(...) などでエラー終了させることも検討
if not AUTHOR_TABLE_NAME:
    logger.error("Environment variable 'API_MYMADAMISAPP_AUTHORTABLE_NAME' not found.")
    # 必要に応じて raise ValueError(...) などでエラー終了させることも検討

def lambda_handler(event, context):
    """
    EventBridgeからS3のObject Createdイベントを受け取り、
    CSVファイルを解析して適切なDynamoDBテーブルに書き込むLambda関数
    """
    logger.info(f"Received event: {json.dumps(event)}") # Log the received event

    # 1. Get bucket and key from the EventBridge event (S3 Direct Notification)
    try:
        # EventBridgeからのS3イベントの構造に合わせて取得
        bucket = event['detail']['bucket']['name']
        # オブジェクトキーはURLエンコードされている可能性があるためデコード
        key_raw = event['detail']['object']['key']
        key = urllib.parse.unquote_plus(key_raw)

        file_name = os.path.basename(key)
        logger.info(f"Processing file: s3://{bucket}/{key}")
    except KeyError as e:
        logger.error(f"Failed to parse EventBridge S3 event structure: Missing key {e}")
        logger.debug(f"Event detail: {event.get('detail', 'Not Found')}")
        # 不正なイベント構造の場合、処理を中断
        return {'statusCode': 400, 'body': json.dumps(f'Invalid EventBridge S3 event structure: Missing key {e}')}
    except Exception as e:
        logger.error(f"Unexpected error parsing event: {e}", exc_info=True)
        return {'statusCode': 500, 'body': json.dumps(f'Unexpected error parsing event: {str(e)}')}


    try:
        # 2. Get and parse the CSV file from S3
        response = s3.get_object(Bucket=bucket, Key=key)
        # 'utf-8-sig': BOM (Byte Order Mark) 付きのUTF-8ファイルに対応
        content = response['Body'].read().decode('utf-8-sig')
        csv_file = io.StringIO(content)
        reader = csv.reader(csv_file)

        try:
            # ヘッダー行を取得し、不要な空白を除去
            header_raw = next(reader)
            # ★ ヘッダー名をそのままDynamoDBのAttribute名として使用することを想定
            header = [h.strip() for h in header_raw if h.strip()]
            if not header:
                logger.warning("CSV header is empty or contains only whitespace.")
                return {'statusCode': 400, 'body': json.dumps('CSV header is empty or invalid.')}
            logger.info(f"CSV Header: {header}")
        except StopIteration:
            logger.warning("CSV file is empty (only header or completely empty).")
            return {'statusCode': 200, 'body': json.dumps('CSV file is empty')}

        # DynamoDB用のタイムスタンプ (ISO 8601形式, UTC, ミリ秒まで)
        now_iso = datetime.now(timezone.utc).isoformat(timespec='milliseconds').replace('+00:00', 'Z')
        # DataStore用のUnixタイムスタンプ (秒)
        now_unix_sec = int(datetime.now(timezone.utc).timestamp())


        # 3. Determine target table based on filename and schema
        items_to_write = []
        target_table = None
        target_typename = None
        processed_count = 0
        skipped_count = 0
        required_fields = []

        # --- ファイル名に基づいて処理を分岐 ---
        if 'Scenario' in file_name: # ファイル名に "Scenario" が含まれる場合
            if not SCENARIO_TABLE_NAME:
                 logger.error("Scenario table name is not configured. Cannot proceed.")
                 return {'statusCode': 500, 'body': json.dumps('Configuration error: Scenario table name missing.')}
            target_table = dynamodb.Table(SCENARIO_TABLE_NAME)
            target_typename = 'Scenario' # GraphQLスキーマの型名
            # ★ シナリオテーブルに必要な必須フィールド名をリストアップ (GraphQLスキーマに基づく)
            required_fields = ['id', 'title', 'authorId']
            logger.info(f"Target table: {SCENARIO_TABLE_NAME} ({target_typename})")

        elif 'Author' in file_name: # ファイル名に "Author" が含まれる場合
            if not AUTHOR_TABLE_NAME:
                 logger.error("Author table name is not configured. Cannot proceed.")
                 return {'statusCode': 500, 'body': json.dumps('Configuration error: Author table name missing.')}
            target_table = dynamodb.Table(AUTHOR_TABLE_NAME)
            target_typename = 'Author' # GraphQLスキーマの型名
            # ★ 著者テーブルに必要な必須フィールド名をリストアップ (GraphQLスキーマに基づく)
            required_fields = ['id', 'authorName']
            logger.info(f"Target table: {AUTHOR_TABLE_NAME} ({target_typename})")

        else:
            logger.warning(f"Filename '{file_name}' does not contain 'Scenario' or 'Author'. Skipping.")
            return {'statusCode': 200, 'body': json.dumps('File skipped based on filename.')}

        # --- ヘッダーチェック ---
        missing_headers = [rf for rf in required_fields if rf not in header]
        if missing_headers:
            logger.error(f"CSV header is missing required columns for {target_typename}: {', '.join(missing_headers)}")
            return {'statusCode': 400, 'body': json.dumps(f"CSV header missing required columns: {', '.join(missing_headers)}")}

        # --- 行データの処理 ---
        for i, row in enumerate(reader):
            row_num = i + 2 # ヘッダーが1行目、データは2行目から
            # 空行をスキップ
            if not any(row):
                 logger.debug(f"Skipping empty row {row_num}")
                 skipped_count += 1
                 continue

            # 列数がヘッダーと合わない行はスキップ
            if len(row) != len(header):
                logger.warning(f"Skipping row {row_num} due to incorrect column count ({len(row)} expected {len(header)}). Row: {row}")
                skipped_count += 1
                continue

            item = {}
            has_error = False
            missing_required = []

            # ヘッダーに基づいて item を作成
            for idx, col_name in enumerate(header):
                value = row[idx].strip()

                # 必須フィールドが空かチェック
                if col_name in required_fields and not value:
                    missing_required.append(col_name)

                # 型変換 (例: 数値型への変換) - 必要に応じて追加・修正
                if target_typename == 'Scenario' and col_name in ['minPlayerCount', 'maxPlayerCount']:
                    if value.isdigit():
                        item[col_name] = int(value)
                    elif value: # 空文字でなく、数字でもない場合
                        logger.warning(f"Row {row_num}: Invalid integer value for {col_name}: '{value}'. Setting to null.")
                        item[col_name] = None
                    else: # 空文字の場合
                         item[col_name] = None # 数値項目が空ならnull
                else:
                    # 文字列はそのまま、空文字は空文字として登録（または None にしたい場合は if value else None）
                    item[col_name] = value

            # 必須フィールドが欠けている場合はスキップ
            if missing_required:
                 logger.warning(f"Skipping row {row_num} due to missing required values for: {', '.join(missing_required)}. Row: {row}")
                 skipped_count += 1
                 continue

            # Amplify @model 関連フィールドを追加
            item['__typename'] = target_typename
            item['createdAt'] = now_iso
            item['updatedAt'] = now_iso
            # DataStore連携用フィールド (GraphQLスキーマに合わせて自動生成される)
            item['_version'] = 1
            item['_lastChangedAt'] = now_unix_sec
            item['_deleted'] = None # または False (スキーマ定義による)

            items_to_write.append(item)
            processed_count += 1


        # 4. Batch write items to DynamoDB
        written_count = 0
        if items_to_write:
            try:
                # DynamoDBのbatch_writerは25件ごとの書き込みを自動で処理
                with target_table.batch_writer() as batch:
                    for item in items_to_write:
                        logger.debug(f"Putting item: {json.dumps(item)}")
                        batch.put_item(Item=item)
                written_count = len(items_to_write)
                logger.info(f"Successfully wrote {written_count} items to {target_table.name}.")

            except Exception as e:
                # バッチ書き込み中にエラーが発生した場合
                logger.error(f"Error during batch write operation to {target_table.name}: {e}", exc_info=True)
                # エラーが発生した場合、部分的に成功している可能性もある
                # ここでは処理全体を失敗として扱うが、より詳細なエラーハンドリングも可能
                # (例: unprocessed_items の処理など)
                # raise e # エラーを再スローしてLambda実行を失敗させることも可能

        else:
            logger.info("No valid items found in CSV to write.")

        summary = f"Processing complete for {file_name}. Processed: {processed_count}, Skipped: {skipped_count}, Written: {written_count}."
        logger.info(summary)
        return {'statusCode': 200, 'body': json.dumps(summary)}

    except boto3.exceptions.Boto3Error as e:
        logger.error(f"AWS API Error accessing S3 or DynamoDB: {e}", exc_info=True)
        return {'statusCode': 500, 'body': json.dumps(f'AWS API Error: {str(e)}')}
    except UnicodeDecodeError as e:
        logger.error(f"Error decoding file {key} as UTF-8 (with BOM): {e}. Ensure file encoding is correct.", exc_info=True)
        return {'statusCode': 400, 'body': json.dumps(f'File encoding error: {str(e)}')}
    except Exception as e:
        logger.error(f"Unhandled error processing file {key}: {e}", exc_info=True)
        # 予期せぬエラーの詳細をCloudWatch Logsに出力
        return {'statusCode': 500, 'body': json.dumps(f'Unhandled internal server error.')}