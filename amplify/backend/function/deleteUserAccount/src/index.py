import json
import os
import boto3
from boto3.dynamodb.conditions import Key

# --- 環境変数 ---
ENV = os.environ['ENV']
REGION = os.environ['REGION']
API_ID = os.environ['API_MYMADAMISAPP_GRAPHQLAPIIDOUTPUT']
USER_POOL_ID = os.environ['AUTH_MYMADAMISAPPB2BF781D_USERPOOLID']

# --- テーブル名 ---
USER_TABLE = f'User-{API_ID}-{ENV}'
SCENARIO_TABLE = f'UserScenario-{API_ID}-{ENV}'
RELATIONSHIP_TABLE = f'UserRelationship-{API_ID}-{ENV}'

# --- クライアント初期化 ---
cognito = boto3.client('cognito-idp', region_name=REGION)
dynamodb = boto3.resource('dynamodb', region_name=REGION)

def handler(event, context):
    print(f"=== deleteUserAccount START ===")
    
    try:
        # 1. ユーザーIDの取得 (Owner認証)
        identity = event.get('identity', {})
        user_id = identity.get('sub')
        username = identity.get('username')

        if not user_id:
            raise Exception("Unauthorized: No user ID found.")

        print(f"Deleting account for UserID: {user_id}, Username: {username}")

        # 2. DynamoDBデータの削除 (関連データのクリーンアップ)
        
        # A. UserScenario (シナリオ手帳) の削除
        # PK: userId なので Query して BatchWrite で削除
        table_scenario = dynamodb.Table(SCENARIO_TABLE)
        _delete_all_items_by_pk(table_scenario, 'userId', user_id, 'scenarioId')

        # B. UserRelationship (フォロー情報: 自分がフォローしているレコード) の削除
        # PK: followingId
        table_relationship = dynamodb.Table(RELATIONSHIP_TABLE)
        _delete_all_items_by_pk(table_relationship, 'followingId', user_id, 'followedId')
        
        # (Option: 被フォロー情報の削除は、整合性維持のため必要であればここで行うが、
        #  今回は「自分のデータ」の削除を優先する。GSI検索が必要になるため)

        # C. User (プロフィール) の削除
        table_user = dynamodb.Table(USER_TABLE)
        table_user.delete_item(Key={'id': user_id})
        print(f"Deleted User profile for {user_id}")

        # 3. Cognitoユーザーの削除
        cognito.admin_delete_user(
            UserPoolId=USER_POOL_ID,
            Username=username
        )
        print(f"Deleted Cognito user: {username}")

        return json.dumps("Account deleted successfully")

    except Exception as e:
        print(f"[ERROR] Failed to delete account: {e}")
        # エラー内容をクライアントに返す
        raise Exception(f"Failed to delete account: {str(e)}")

def _delete_all_items_by_pk(table, pk_name, pk_value, sk_name):
    """指定したPKを持つアイテムを全て削除するヘルパー関数"""
    try:
        scan_kwargs = {
            'KeyConditionExpression': Key(pk_name).eq(pk_value),
            'ProjectionExpression': f"{pk_name}, {sk_name}"
        }
        done = False
        start_key = None
        
        with table.batch_writer() as batch:
            while not done:
                if start_key:
                    scan_kwargs['ExclusiveStartKey'] = start_key
                response = table.query(**scan_kwargs)
                
                items = response.get('Items', [])
                for item in items:
                    batch.delete_item(Key={
                        pk_name: item[pk_name],
                        sk_name: item[sk_name]
                    })
                
                start_key = response.get('LastEvaluatedKey', None)
                done = start_key is None
        
        print(f"Deleted items from {table.name} where {pk_name}={pk_value}")

    except Exception as e:
        print(f"Error deleting items from {table.name}: {e}")
        raise