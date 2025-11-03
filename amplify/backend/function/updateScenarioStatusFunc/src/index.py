import os
import boto3
from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError
from datetime import datetime, timezone

dynamodb = boto3.resource('dynamodb')

# 環境変数からテーブル名を取得
try:
    # 修正: USER_SCENARIO_TABLE_NAME の環境変数名を NewUserScenario に変更
    USER_SCENARIO_TABLE_NAME = os.environ['API_MYMADAMISAPP_NEWUSERSCENARIOTABLE_NAME']
    # USER_TABLE_NAME は User モデルの更新に使われるため、そのまま使用
    USER_TABLE_NAME = os.environ['API_MYMADAMISAPP_USERTABLE_NAME']
except KeyError:
    # Key エラーが発生した場合、権限設定と環境変数名をチェックするように促す
    raise Exception("環境変数が設定されていません。Lambdaの権限を確認してください。")

user_scenario_table = dynamodb.Table(USER_SCENARIO_TABLE_NAME)

def handler(event, context):
    """
    UserScenario のステータスを更新（または作成）し、更新されたレコードを返す。
    @function のため、引数は event['arguments'] から取得する。
    """
    try:
        args = event['arguments']
        
        user_id = args['userId']
        scenario_id = args['scenarioId']
        is_played = args['isPlayed']
        is_possessed = args = args['isPossessed']
        
        # 1. データの整合性チェック: 呼び出しユーザーがオーナーであることを確認
        # AppSyncの @auth で行われるが、コード側でも念のためログ出力
        calling_user_id = event['identity']['sub']
        if calling_user_id != user_id:
            print(f"セキュリティ警告: ユーザー {calling_user_id} がユーザー {user_id} のレコードを不正に更新しようとしました。")
            raise Exception("Unauthorized: You can only update your own scenario logbook entries.")

        # 2. 現在の日時を取得 (ISO 8601形式)
        now_iso = datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z')

        # 3. DynamoDB の UpdateItem を実行
        # NewUserScenario の PK は userId (Partition Key) と scenarioId (Sort Key) の複合キーです
        response = user_scenario_table.update_item(
            Key={
                'userId': user_id,
                'scenarioId': scenario_id
            },
            UpdateExpression="set isPlayed = :p, isPossessed = :s, updatedAt = :u, #ca = if_not_exists(#ca, :u)",
            ExpressionAttributeNames={
                '#ca': 'createdAt' # 'createdAt' が予約語に近いので安全のために別名を使用
            },
            ExpressionAttributeValues={
                ':p': is_played,
                ':s': is_possessed,
                ':u': now_iso
            },
            ReturnValues="ALL_NEW"
        )

        # 4. 更新されたアイテムを取得
        updated_item = response.get('Attributes')
        
        if not updated_item:
            raise Exception("レコードの更新に失敗しました。")

        print(f"更新完了: {user_id} - {scenario_id} のステータスを更新しました。")

        # 5. GraphQL のレスポンスとして返すために、型を合わせる (Lambdaが返すのはDBの属性)
        return updated_item

    except ClientError as e:
        error_code = e.response['Error']['Code']
        print(f"DynamoDB ClientError: {error_code} - {e}")
        raise Exception(f"DynamoDBへのアクセスに失敗しました: {error_code}")
    except Exception as e:
        print(f"致命的なエラー: {e}")
        raise Exception(f"シナリオステータスの更新に失敗しました: {e}")