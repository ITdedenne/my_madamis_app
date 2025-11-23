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
# backend-config.json で依存関係を追加することで注入されるバケット名
BUCKET_NAME = os.environ.get('STORAGE_MADAMISAPPS3_BUCKETNAME') 

# --- 定数 ---
SCENARIOS_JSON_KEY = 'Scenarios.json'
VERSION_JSON_KEY = 'version.json'
USER_SCENARIO_TABLE_NAME = f'UserScenario-{API_ID}-{ENV}'

# --- グローバルキャッシュ (コンテナ再利用時用) ---
# Lambdaの実行コンテキストが維持される限り、メモリ上に保持される
_cached_scenarios = None
_cached_version = None

# --- AWS リソース ---
s3_client = boto3.client('s3', region_name=REGION)
dynamodb_resource = boto3.resource('dynamodb', region_name=REGION)
user_scenario_table = dynamodb_resource.Table(USER_SCENARIO_TABLE_NAME)

def get_master_data():
    """
    S3からマスターデータを取得し、キャッシュ制御を行う (要件 5.2.3)
    """
    global _cached_scenarios, _cached_version

    try:
        # 1. version.json を取得
        version_obj = s3_client.get_object(Bucket=BUCKET_NAME, Key=VERSION_JSON_KEY)
        current_version = json.loads(version_obj['Body'].read().decode('utf-8'))

        # 2. キャッシュ確認
        if _cached_scenarios and _cached_version == current_version:
            print("Using cached scenarios.json")
            return _cached_scenarios

        # 3. キャッシュが古い、または無い場合は scenarios.json をダウンロード
        print("Downloading scenarios.json from S3...")
        scenarios_obj = s3_client.get_object(Bucket=BUCKET_NAME, Key=SCENARIOS_JSON_KEY)
        _cached_scenarios = json.loads(scenarios_obj['Body'].read().decode('utf-8'))
        _cached_version = current_version
        
        return _cached_scenarios

    except Exception as e:
        print(f"Error fetching master data: {e}")
        # エラー時はキャッシュがあればそれを使う、なければ空リスト
        return _cached_scenarios if _cached_scenarios else []

def fetch_user_ng_list(user_id):
    """
    指定ユーザーのNGリスト（プレイ済/所持/GM検討）にあるシナリオIDセットを取得
    """
    try:
        # GSI 'byUser' を使用
        # ProjectionExpression で転送量を削減 (要件 7.3)
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
    自分の対象リスト（所持 OR GM検討）にあるシナリオIDセットを取得
    """
    try:
        response = user_scenario_table.query(
            IndexName='byUser',
            KeyConditionExpression=Key('userId').eq(user_id),
            # 自分が「所持」または「GM検討中」のものを対象とする
            FilterExpression=Attr('isPossessed').eq(True) | Attr('wantsToGm').eq(True),
            ProjectionExpression='scenarioId'
        )
        return {item['scenarioId'] for item in response.get('Items', [])}
    except Exception as e:
        print(f"Error fetching target list for user {user_id}: {e}")
        return set()

def handler(event, context):
    print("=== findGroupScenarios START ===")
    # print(json.dumps(event)) # デバッグ用

    try:
        arguments = event.get('arguments', {})
        identity = event.get('identity', {})
        
        requesting_user_id = identity.get('sub')
        friend_ids = arguments.get('friendIds', []) # List<String>

        if not requesting_user_id:
            raise ValueError("Unauthorized")
        
        # 最大人数のバリデーション (要件 4.5.1: 8人まで)
        if len(friend_ids) > 8:
             raise ValueError("Too many friends selected (Max 8).")

        # 1. 並列実行でDBクエリを行う (要件 5.2.3)
        # 自分: 対象リスト取得
        # フレンズ: NGリスト取得
        with ThreadPoolExecutor(max_workers=10) as executor:
            # 自分のリスト取得タスク
            my_list_future = executor.submit(fetch_my_target_list, requesting_user_id)
            
            # フレンズのNGリスト取得タスク (人数分)
            friend_futures = {fid: executor.submit(fetch_user_ng_list, fid) for fid in friend_ids}

            # 結果取得
            my_target_scenarios = my_list_future.result()
            friends_ng_scenarios = set()
            for fid, future in friend_futures.items():
                ng_set = future.result()
                # print(f"Friend {fid} NG count: {len(ng_set)}")
                friends_ng_scenarios.update(ng_set)

        # 2. マスターデータの取得 (S3キャッシュ活用)
        all_scenarios = get_master_data()

        # 3. メモリ上での突合 (要件 5.2.3)
        # 条件: 「自分の対象リスト」に含まれる AND 「フレンズのNGリスト」に含まれない
        matched_scenario_ids = []
        
        # 注意: scenarios.jsonの構造依存。ここではフラットなリストと仮定
        # もし scenarios.json がID検索に最適化されていない場合、ループで判定
        
        # 高速化のため、my_target_scenarios に含まれるものだけをチェック
        # ただし scenarios.json に詳細情報があるため、そこからフィルタする形でもよいが、
        # ここでは最終的にIDのリストを返すため、集合演算を行う
        
        final_candidates = my_target_scenarios - friends_ng_scenarios
        
        # 結果リスト作成 (順序は保証されないため、クライアント側でソート推奨)
        result_list = list(final_candidates)
        
        print(f"Matched Scenarios Count: {len(result_list)}")

        # JSON文字列として返す
        return json.dumps(result_list)

    except Exception as e:
        print(f"[ERROR] {e}")
        return json.dumps([]) # エラー時は空リストを返す