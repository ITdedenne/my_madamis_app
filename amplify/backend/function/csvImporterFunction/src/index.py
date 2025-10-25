# /amplify/backend/function/csvImporterFunction/src/index.py

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
logger.setLevel(logging.INFO)

# --- AWS Client Initialization ---
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

# --- Environment Variable Acquisition ---
API_NAME_UPPER = "MYMADAMISAPP" # ★もし 'amplify add api' で違う名前を付けたら、ここを修正

#SCENARIO_TABLE_NAMEもAUTHOR_TABLE_NAMEも本当は直値ではなく、今コメントアウトしているように本当は変数で指定したい。
#じゃないとIaCに反する上に、本番用にCloudFourmationを起動したときに直値で指定しないといけないため
#SCENARIO_TABLE_NAME = os.environ.get(f'API_{API_NAME_UPPER}_SCENARIOTABLENAME')
SCENARIO_TABLE_NAME = "Scenario-shn3ctad5ractaju4rvlsyxvge-dev"
#AUTHOR_TABLE_NAME = os.environ.get(f'API_{API_NAME_UPPER}_AUTHORTABLENAME')
AUTHOR_TABLE_NAME = "Author-shn3ctad5ractaju4rvlsyxvge-dev"

if not SCENARIO_TABLE_NAME:
    logger.error(f"Environment variable 'API_{API_NAME_UPPER}_SCENARIOTABLENAME' not found.")
if not AUTHOR_TABLE_NAME:
    logger.error(f"Environment variable 'API_{API_NAME_UPPER}_AUTHORTABLENAME' not found.")
# ------------------------------------

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

    # 1. Get bucket and key from the EventBridge event (S3 Direct Notification)
    try:
        # ★★★ ここが修正箇所です ★★★
        # S3ダイレクト通知イベント (detail-type: "Object Created") の構造に合わせます
        bucket = event['detail']['bucket']['name']
        key_raw = event['detail']['object']['key']
        key = urllib.parse.unquote_plus(key_raw)
        # ---------------------
        
        file_name = os.path.basename(key)
        logger.info(f"Processing file: {file_name} from bucket: {bucket}")
    except KeyError as e:
        logger.error(f"Failed to parse S3 direct event structure: {e}")
        return {'statusCode': 400, 'body': json.dumps('Failed to parse S3 direct event')}

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
            header = [h.strip() for h in header_raw if h.strip()]
            logger.info(f"CSV Header: {header}")
        except StopIteration:
            logger.warning("CSV file is empty.")
            return {'statusCode': 200, 'body': json.dumps('CSV file is empty')}

        # DynamoDB用のタイムスタンプ (ISO 8601形式, UTC, ミリ秒まで)
        now_iso = datetime.now(timezone.utc).isoformat(timespec='milliseconds').replace('+00:00', 'Z')


        # 3. Determine target table and process rows
        items_to_write = []
        target_table_name = None
        target_typename = None
        processed_count = 0

        # --- Scenarios CSVの処理 ---
        if 'Scenarios' in file_name:
            target_table_name = SCENARIO_TABLE_NAME
            target_typename = 'Scenario'
            logger.info(f"Target table: {target_table_name}")

            try:
                # ヘッダー名から列のインデックス（位置）を取得
                col_indices = {
                    'id': header.index('scenarioId'),
                    'title': header.index('title'),
                    'minPlayerCount': header.index('minPlayerCount'),
                    'maxPlayerCount': header.index('maxPlayerCount'),
                    'gmRequirement': header.index('gmRequirement'),
                    'authorId': header.index('authorId'),
                    'storeUrl': header.index('storeUrl')
                }
            except ValueError as e:
                logger.error(f"Scenarios CSV Header mismatch: {e}")
                return {'statusCode': 400, 'body': json.dumps(f"Scenarios CSV Header mismatch: {e}")}

            for i, row in enumerate(reader):
                row_num = i + 2 # ヘッダーが1行目、データは2行目から
                # 行の列数が不足している場合はスキップ
                if len(row) <= max(col_indices.values()):
                    logger.warning(f"Skipping malformed row {row_num}: {row}")
                    continue

                try:
                    # 必須項目を取得
                    scenario_id = row[col_indices['id']].strip()
                    title = row[col_indices['title']].strip()
                    author_id = row[col_indices['authorId']].strip()
                    
                    # 必須項目が空欄の行はスキップ
                    if not all([scenario_id, title, author_id]):
                        logger.warning(f"Skipping row {row_num} due to empty required fields: {row}")
                        continue

                    # DynamoDB Itemを作成
                    item = {
                        'id': scenario_id,
                        'title': title,
                        'minPlayerCount': int(row[col_indices['minPlayerCount']].strip()) if row[col_indices['minPlayerCount']].strip().isdigit() else None,
                        'maxPlayerCount': int(row[col_indices['maxPlayerCount']].strip()) if row[col_indices['maxPlayerCount']].strip().isdigit() else None,
                        'gmRequirement': row[col_indices['gmRequirement']].strip(),
                        'authorId': author_id,
                        'storeUrl': row[col_indices['storeUrl']].strip(),
                        '__typename': target_typename,
                        'createdAt': now_iso,
                        'updatedAt': now_iso,
                    }
                    items_to_write.append(item)
                    processed_count += 1
                except (ValueError, IndexError) as e:
                    logger.warning(f"Skipping row {row_num} due to data error: {e}. Row: {row}")

        # --- Authors CSVの処理 ---
        elif 'Authors' in file_name:
            target_table_name = AUTHOR_TABLE_NAME
            target_typename = 'Author'
            logger.info(f"Target table: {target_table_name}")

            try:
                # ヘッダー名から列のインデックス（位置）を取得
                col_indices = { 'id': header.index('authorId'), 'authorName': header.index('authorName') }
            except ValueError as e:
                logger.error(f"Authors CSV Header mismatch: {e}")
                return {'statusCode': 400, 'body': json.dumps(f"Authors CSV Header mismatch: {e}")}

            for i, row in enumerate(reader):
                row_num = i + 2
                if len(row) <= max(col_indices.values()):
                    logger.warning(f"Skipping malformed row {row_num}: {row}")
                    continue

                try:
                    author_id = row[col_indices['id']].strip()
                    if not author_id:
                        logger.warning(f"Skipping row {row_num} due to empty authorId: {row}")
                        continue

                    # DynamoDB Itemを作成
                    item = {
                        'id': author_id,
                        'authorName': row[col_indices['authorName']].strip(),
                        '__typename': target_typename,
                        'createdAt': now_iso,
                        'updatedAt': now_iso,
                    }
                    items_to_write.append(item)
                    processed_count += 1
                except (ValueError, IndexError) as e:
                    logger.warning(f"Skipping row {row_num} due to data error: {e}. Row: {row}")
        
        else:
            logger.warning(f"Filename '{file_name}' does not match 'Scenarios' or 'Authors'. Skipping.")
            return {'statusCode': 200, 'body': json.dumps('File skipped.')}

        # 4. Batch write items to DynamoDB
        if items_to_write:
            if not target_table_name:
                logger.error("Target table name could not be determined. Check Lambda environment variables.")
                return {'statusCode': 500, 'body': json.dumps('Internal server error')}

            table = dynamodb.Table(target_table_name)
            written_count = 0
            
            # 25件ずつのバッチに分割 (batch_writerが自動で処理)
            try:
                with table.batch_writer() as batch:
                    for item in items_to_write:
                        batch.put_item(Item=item)
                    written_count = len(items_to_write) # batch_writerは自動で全件処理
                logger.info(f"Wrote batch of {written_count} items successfully.")
            except Exception as e:
                logger.error(f"Error during batch write operation: {e}")

            logger.info(f"Attempted to write {written_count} of {processed_count} processed rows to {target_table_name}.")
        else:
            logger.info("No valid items found in CSV to write.")

        return {'statusCode': 200, 'body': json.dumps('Processing complete.')}

    except Exception as e:
        logger.error(f"Unhandled error processing file {key}: {e}", exc_info=True)
        return {'statusCode': 500, 'body': json.dumps(f'Unhandled error: {str(e)}')}