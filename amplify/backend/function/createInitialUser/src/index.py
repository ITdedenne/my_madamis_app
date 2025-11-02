import json
import os
import random
import boto3
from botocore.exceptions import ClientError
from datetime import datetime, timezone

# DynamoDBクライアントを初期化
# AmplifyはLambdaにUSER_TABLE_NAMEとAWS_REGIONの環境変数を自動で設定します。
TABLE_NAME = os.environ.get('USER_TABLE_NAME') 
REGION = os.environ.get('AWS_REGION')

# boto3は環境に応じて適切にクライアントを作成します
dynamodb = boto3.resource('dynamodb', region_name=REGION)
# テーブル名は Amplify が生成するDynamoDBテーブル名（例: User-xxxxxxxxxxxxxxxxxxxx-env）が入ります。
user_table = dynamodb.Table(TABLE_NAME)

# AppSync/Amplify DataStoreとの互換性のため、タイムスタンプをISO 8601形式で生成
def get_iso_time():
    return datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z')

def generate_unique_friend_id():
    """
    DynamoDBのUserテーブルで一意な7桁の数字のフレンドIDを生成し、確認します。
    """
    # GSI名。Amplifyの命名規則に従って 'byFriendID' を使用。
    FRIEND_ID_GSI = 'byFriendID' 
    
    while True:
        # 7桁の数字を生成 (1000000から9999999)
        friend_id = str(random.randint(1000000, 9999999))
        
        try:
            # GSI (byFriendID) を使って、その friend_id が既に存在するかクエリでチェック
            response = user_table.query(
                IndexName=FRIEND_ID_GSI, 
                KeyConditionExpression=boto3.dynamodb.conditions.Key('friendID').eq(friend_id)
            )
            
            # 項目が見つからなければ一意
            if response['Count'] == 0:
                return friend_id
            
        except ClientError as e:
            print(f"DynamoDB query error: {e}")
            # エラー発生時は再試行（whileループが継続）
            # もし致命的なエラーならここで raise することも検討
            pass 
        except Exception as e:
            print(f"Unexpected error: {e}")
            # その他のエラー発生時は再試行
            pass


def handler(event, context):
    """
    Cognito Post Confirmationトリガーのハンドラ
    """
    print(json.dumps(event))

    # Cognitoからユーザー情報を取得
    user_id = event['request']['userAttributes']['sub'] # Cognitoの sub (UserテーブルのPK: id)
    # Cognitoのデフォルト設定では event['userName'] にユーザー名（またはメールアドレスなど）が入ります。
    username = event['userName'] 
    
    try:
        # 1. 一意のフレンドIDを生成
        friend_id = generate_unique_friend_id()

        # 2. DynamoDBのUserテーブルにユーザーレコードを作成
        user_table.put_item(
            Item={
                'id': user_id, 
                'username': username,
                'friendID': friend_id,
                '__typename': 'User', # AppSync/Amplify DataStoreの互換性のため
                'createdAt': get_iso_time(), 
                'updatedAt': get_iso_time(),
                'owner': user_id # @auth(rules: [{ allow: owner }]) のために必要
            }
        )
        
        print(f"Successfully created user {user_id} with friendID {friend_id}")
        
    except Exception as e:
        print(f"Error during Post Confirmation: {e}")
        # DynamoDBへの書き込み失敗は、Cognitoのフローを停止させない（ユーザーは認証される）
        # ただし、ログに残し、監視・アラートの対象とすべき
        pass

    # Post Confirmationトリガーは元のイベントをそのまま返す必要があります
    return event