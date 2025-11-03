# amplify/backend/function/updateScenarioStatusFunc/src/index.py

import json
import os
import boto3
from boto3.dynamodb.conditions import Key
from datetime import datetime
import uuid # 新規作成時にUUIDを生成するために必要

# UserScenarioテーブル名を取得 (Amplifyによって環境変数に自動注入される)
# 例: UserScenarioTable-xxxxxxxx-env
USER_SCENARIO_TABLE_NAME = os.environ.get('USER_SCENARIO_TABLE_NAME')
DYNAMODB = boto3.resource('dynamodb')
TABLE = DYNAMODB.Table(USER_SCENARIO_TABLE_NAME)

def handler(event, context):
    print(f"Received event: {json.dumps(event)}")
    
    # AppSyncから渡される引数
    args = event.get('arguments', {})
    user_id = args.get('userId')
    scenario_id = args.get('scenarioId')
    is_played = args.get('isPlayed')
    is_possessed = args.get('isPossessed')
    
    # User IDはCognitoのUsernameから取得する (カスタムMutationのResolverで渡すことを前提)
    # ここではMutationの引数から取得するため、そのまま使用
    if not user_id or not scenario_id:
        raise Exception("userId and scenarioId must be provided")

    current_time_str = datetime.now().isoformat()
    
    # 1. 既存レコードを検索 (UserScenarioのGSI/Primary Keyが userId + scenarioId に対応していると仮定)
    # UserScenarioテーブルの実際のキー構造に合わせて調整が必要です。
    # ここでは UserScenario の primary key (id) ではなく、GSIである byUser の複合キーを使用すると想定します。
    # ただし、UserScenarioのDynamoDBテーブルは、通常 `id` が Primary Keyで、
    # `userId` と `scenarioId` はGSIとして扱われます。
    # 簡略化のため、DynamoDBのテーブルが id をPKとし、GSIとして (userId, scenarioId) を持つことを仮定して、GSIでクエリします。
    # ※ AppSyncの @model は DynamoDBのキー構造を複雑にするため、最も確実なのは GSI (byUser, byScenario) でクエリすることです。
    
    # DynamoDB Query: byUser GSI を使用して userId, scenarioId で検索
    # UserScenarioのGSI名とキーをAmplifyのバックエンド設定に合わせて調整してください。
    
    # UserScenarioのスキーマを見ると、インデックスは byUser (fields: ["userId"]) と byScenario (fields: ["scenarioId"]) のため、
    # 両方のキーで同時に検索するためには、Lambda内でFilterを使うか、複合GSIが必要です。
    # ここでは、簡略化のため、GSI byUser を使って userId で絞り込んだ後、FEの isPlayed/isPossessed の情報と比較します。
    
    # UserScenarioのDynamoDBテーブル名を取得
    user_scenario_table_name = [
        name for name in os.environ.keys() if name.endswith('NAME') and 'USERSCENARIO' in name.upper()
    ][0]
    USER_SCENARIO_TABLE = DYNAMODB.Table(os.environ.get(user_scenario_table_name))
    
    try:
        # UserScenarioTableのDynamoDBキーは 'id' のため、直接 Query はできない。
        # 代わりに scan (非推奨だが簡単なため) または index query を使う
        
        # GSI 'byUser' (userId) でクエリ
        query_response = USER_SCENARIO_TABLE.query(
            IndexName='byUser', # UserScenario.userId を Primary KeyとするGSI名
            KeyConditionExpression=Key('userId').eq(user_id)
        )
        
        # userIdで絞った後、scenarioIdでフィルタ
        existing_entries = [
            item for item in query_response['Items'] 
            if item.get('scenarioId') == scenario_id
        ]

    except Exception as e:
        print(f"DynamoDB Query Error: {e}")
        # DynamoDBエラーの場合、新規作成/更新に進まずにエラーを返す
        raise Exception(f"Failed to query UserScenario: {e}")

    existing_entry = existing_entries[0] if existing_entries else None
    
    if not is_played and not is_possessed:
        # 1. 両方 false の場合: レコードを削除 (「未登録」)
        if existing_entry:
            # DynamoDBのPrimary Key (id) を使って削除
            TABLE.delete_item(
                Key={'id': existing_entry['id']}
            )
            # 削除成功時は、GraphQLに null を返す
            return None
    else:
        # 2. どちらか true の場合: 更新または新規作成
        if existing_entry:
            # 既存レコードを更新
            update_expression = "SET isPlayed = :ip, isPossessed = :is, updatedAt = :t"
            expression_attribute_values = {
                ':ip': is_played,
                ':is': is_possessed,
                ':t': current_time_str
            }
            
            response = TABLE.update_item(
                Key={'id': existing_entry['id']}, # PKで更新
                UpdateExpression=update_expression,
                ExpressionAttributeValues=expression_attribute_values,
                ReturnValues="ALL_NEW"
            )
            
            # GraphQLが期待する形式（User, Scenarioオブジェクトは省略）で返す
            updated_item = response['Attributes']
            return {
                'id': updated_item['id'],
                'isPlayed': updated_item.get('isPlayed', False),
                'isPossessed': updated_item.get('isPossessed', False),
                # 他の必須フィールドも返す必要がある (user/scenarioオブジェクトはLambda内で解決しない限り空でOK)
                'userId': user_id,
                'scenarioId': scenario_id,
            }
            
        else:
            # 新規レコードを作成
            new_uuid = str(uuid.uuid4())
            new_item = {
                'id': new_uuid,
                'userId': user_id,
                'scenarioId': scenario_id,
                'isPlayed': is_played,
                'isPossessed': is_possessed,
                'createdAt': current_time_str,
                'updatedAt': current_time_str,
                # __typename は AppSyncの返却形式に必要だが、DynamoDB直接書き込みでは不要な場合がある
                '__typename': 'UserScenario' 
            }
            
            TABLE.put_item(Item=new_item)
            
            # GraphQLが期待する形式で返す
            return {
                'id': new_uuid,
                'isPlayed': is_played,
                'isPossessed': is_possessed,
                'userId': user_id,
                'scenarioId': scenario_id,
            }

    return None # 削除またはエラー時