import json
import os
import boto3
from html.parser import HTMLParser
from decimal import Decimal

# DynamoDB/Cognito クライアントの初期化
REGION = os.environ.get('REGION')
COGNITO_USER_POOL_ID = os.environ.get('AUTH_MYMADAMISAPPB2BF781D_USERPOOLID')
# DynamoDB テーブル名を環境変数から動的に構築
USER_TABLE_NAME = f"User-{os.environ.get('API_MYMADAMISAPP_GRAPHQLAPIIDOUTPUT')}-{os.environ.get('ENV')}"

cognito_client = boto3.client('cognito-idp', region_name=REGION)
dynamodb_client = boto3.resource('dynamodb', region_name=REGION)
user_table = dynamodb_client.Table(USER_TABLE_NAME)

# =================================================================
# (6.2.7) UGCの無害化（サニタイズ）のためのヘルパークラス
# =================================================================
class HTMLStripper(HTMLParser):
    """HTMLタグをすべて除去し、プレーンテキストを抽出するパーサー (6.2.7)"""
    def __init__(self):
        super().__init__()
        self.reset()
        self.strict = False
        self.convert_charrefs= True
        self.text = []

    def handle_data(self, data):
        self.text.append(data)

    def get_data(self):
        return ''.join(self.text)

def sanitize_bio(html_string):
    """
    (5.2.5, 6.2.7) bioの文字列からHTMLタグをすべて除去し、プレーンテキスト化する。
    """
    stripper = HTMLStripper()
    stripper.feed(html_string)
    # 前後の空白を除去
    return stripper.get_data().strip()

# =================================================================
# メインハンドラ (5.2.5)
# =================================================================
def handler(event, context):
    try:
        # (1) リクエストデータと認証情報を取得
        arguments = event['arguments']
        identity = event['identity']

        # DynamoDBのPKである id (Cognito Sub ID) を取得
        user_id = identity['sub'] 
        # Cognitoのユーザー名 (通常はemail)
        cognito_username = identity['username']
        
        # (2) 入力値の取得とバリデーション (5.2.5)
        new_username = arguments.get('username')
        new_bio = arguments.get('bio') or ""

        if not new_username or new_username.strip() == "":
            raise ValueError("ユーザー名は必須です。")
        
        # (3) bioのサニタイズとバリデーション (5.2.5, 6.2.7)
        sanitized_bio = sanitize_bio(new_bio)
        if len(sanitized_bio) > 160: # (5.3 DynamoDB 定義に基づく)
            raise ValueError("自己紹介は160文字以下である必要があります。")

        # (4) Cognito User Pool の更新 (5.2.5 - preferred_username の同期)
        cognito_client.admin_update_user_attributes(
            UserPoolId=COGNITO_USER_POOL_ID,
            Username=cognito_username,
            UserAttributes=[
                {
                    'Name': 'preferred_username',
                    'Value': new_username
                },
                # bio, twitter_id は Cognito カスタム属性の廃止 (6.3.3) により更新しない
            ]
        )

        # (5) DynamoDB の更新 (5.2.5 - username/bio の同期)
        update_expression = "SET #un = :new_un, #bio = :new_bio, updatedAt = :updatedAt"
        expression_attribute_names = {
            '#un': 'username',
            '#bio': 'bio',
        }
        expression_attribute_values = {
            ':new_un': new_username,
            ':new_bio': sanitized_bio,
            # Amplify の自動更新タイムスタンプを模倣するため、現在時刻を使用
            ':updatedAt': str(int(context.get_remaining_time_in_millis() / 1000)),
        }
        
        user_table.update_item(
            Key={'id': user_id},
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values,
        )

        # (6) 成功応答
        return json.dumps({
            "message": "Profile updated successfully",
            "username": new_username,
            "bio": sanitized_bio
        })

    except ValueError as e:
        # バリデーションエラー
        print(f"Validation Error: {e}")
        return json.dumps({"error": str(e)})

    except Exception as e:
        # その他のエラー
        print(f"An unexpected error occurred: {e}")
        return json.dumps({"error": f"プロフィールの更新に失敗しました: {e}"})