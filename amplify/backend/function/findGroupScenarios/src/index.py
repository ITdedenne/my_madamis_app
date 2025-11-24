import json
import os
import boto3
import time
from concurrent.futures import ThreadPoolExecutor
from boto3.dynamodb.conditions import Key, Attr

# --- 環境変数 ---
ENV = os.environ['ENV']
REGION = os.environ['REGION']
API_ID = os.environ['API_MYMADAMISAPP_GRAPHQLAPIIDOUTPUT']
BUCKET_NAME = os.environ.get('STORAGE_MADAMISAPPS3_BUCKETNAME') 

# --- 定数 ---
SCENARIOS_JSON_KEY = 'Scenarios.json'
VERSION_JSON_KEY = 'version.json'
USER_SCENARIO_TABLE_NAME = f'UserScenario-{API_ID}-{ENV}'

# --- グローバルキャッシュ (コンテナ再利用時用) ---
_cached_scenarios = None
_cached_version = None

# --- AWS リソース ---
s3_client = boto3.client('s3', region_name=REGION)
dynamodb_resource = boto3.resource('dynamodb', region_name=REGION)
user_scenario_table = dynamodb_resource.Table(USER_SCENARIO_TABLE_NAME)

def get_master_data():
    """
    S3からマスターデータを取得し、キャッシュ制御を行う
    """
    global _cached_scenarios, _cached_version

    try:
        version_obj = s3_client.get_object(Bucket=BUCKET_NAME, Key=VERSION_JSON_KEY)
        current_version = json.loads(version_obj['Body'].read().decode('utf-8'))

        if _cached_scenarios and _cached_version == current_version:
            print("Using cached scenarios.json")
            return _cached_scenarios

        print("Downloading scenarios.json from S3...")
        scenarios_obj = s3_client.get_object(Bucket=BUCKET_NAME, Key=SCENARIOS_JSON_KEY)
        _cached_scenarios = json.loads(scenarios_obj['Body'].read().decode('utf-8'))
        _cached_version = current_version
        
        return _cached_scenarios

    except Exception as e:
        print(f"Error fetching master data: {e}")
        return _cached_scenarios if _cached_scenarios else []

def fetch_user_ng_list(user_id):
    """
    指定ユーザーのNGリスト（プレイ済/所持/GM検討）にあるシナリオIDセットを取得
    """
    try:
        # ProjectionExpression に wantsToPlay を追加（将来的な利用も考慮）
        # NG条件は変わらず: isPlayed OR isPossessed OR wantsToGm
        # wantsToPlay はNGリストには含まれない（未通過扱い）
        response = user_scenario_table.query(
            IndexName='byUser',
            KeyConditionExpression=Key('userId').eq(user_id),
            FilterExpression=Attr('isPlayed').eq(True) | Attr('isPossessed').eq(True) | Attr('wantsToGm').eq(True),
            ProjectionExpression='scenarioId'
        )
        return {item['scenarioId'] for item in response.get('Items', [])}
    except Exception as e:
        print(f"Error fetching NG list for user {user_id}: {e}")
        return set()

def fetch_my_target_list(user_id):
    """
    自分の対象リスト（所持 OR GM検討 OR PL希望）にあるシナリオIDセットを取得
    """
    try:
        # 検索対象条件に wantsToPlay == True を追加
        response = user_scenario_table.query(
            IndexName='byUser',
            KeyConditionExpression=Key('userId').eq(user_id),
            FilterExpression=Attr('isPossessed').eq(True) | Attr('wantsToGm').eq(True) | Attr('wantsToPlay').eq(True),
            ProjectionExpression='scenarioId'
        )
        return {item['scenarioId'] for item in response.get('Items', [])}
    except Exception as e:
        print(f"Error fetching target list for user {user_id}: {e}")
        return set()

def handler(event, context):
    print("=== findGroupScenarios START ===")

    try:
        arguments = event.get('arguments', {})
        identity = event.get('identity', {})
        
        requesting_user_id = identity.get('sub')
        friend_ids = arguments.get('friendIds', []) 

        if not requesting_user_id:
            raise ValueError("Unauthorized")
        
        if len(friend_ids) > 8:
             raise ValueError("Too many friends selected (Max 8).")

        with ThreadPoolExecutor(max_workers=10) as executor:
            my_list_future = executor.submit(fetch_my_target_list, requesting_user_id)
            
            friend_futures = {fid: executor.submit(fetch_user_ng_list, fid) for fid in friend_ids}

            my_target_scenarios = my_list_future.result()
            friends_ng_scenarios = set()
            for fid, future in friend_futures.items():
                ng_set = future.result()
                friends_ng_scenarios.update(ng_set)

        all_scenarios = get_master_data()

        matched_scenario_ids = []
        
        final_candidates = my_target_scenarios - friends_ng_scenarios
        
        result_list = list(final_candidates)
        
        print(f"Matched Scenarios Count: {len(result_list)}")

        return json.dumps(result_list)

    except Exception as e:
        print(f"[ERROR] {e}")
        return json.dumps([])