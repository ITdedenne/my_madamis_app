const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');

// =================================================================
// ★ 修正箇所: 環境非依存の定義を削除し、直値でテーブル名を指定
// WARNING: 本番環境デプロイ前にこの直値を動的変数に戻してください
const USER_TABLE_NAME = 'User-eju77evq3javlfhhc6o5pecapy-dev'; 
// =================================================================
const MAX_RETRIES = 5;

// DynamoDBクライアントの初期化
const client = new DynamoDBClient({ region: process.env.REGION });
const ddbDocClient = DynamoDBDocumentClient.from(client);

/**
 * 7桁のユニークな publicUserId を生成する (5.2.1)
 * @returns {string} 7桁の数字文字列
 */
function generatePublicUserId() {
  // 1000000 から 9999999 の範囲でランダムな整数を生成
  return (Math.floor(Math.random() * 9000000) + 1000000).toString();
}

/**
 * Cognito Post Confirmation トリガーハンドラ (5.2.1)
 * @type {import('@types/aws-lambda').PostConfirmationTriggerHandler}
 */
exports.handler = async (event) => {
  if (!event.request.userAttributes.sub) {
    console.error("No Cognito Sub ID found in event.");
    return event; 
  }

  const subId = event.request.userAttributes.sub;
  const username = event.request.userAttributes['preferred_username'];

  for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
    const publicUserId = generatePublicUserId();
    
    const params = {
      TableName: USER_TABLE_NAME, 
      Item: {
        id: subId, 
        username: username, 
        publicUserId: publicUserId, 
        bio: '', 
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      },
      // (6.3.1) ID重複排除のためのConditionExpression
      ConditionExpression: 'attribute_not_exists(publicUserId)', 
    };

    try {
      await ddbDocClient.send(new PutCommand(params));
      console.log(`Successfully created User record for sub: ${subId} with publicUserId: ${publicUserId}`);
      return event;
    } catch (error) {
      if (error.name === 'ConditionalCheckFailedException') {
        console.warn(`publicUserId: ${publicUserId} already exists. Retrying... (Attempt ${attempt + 1})`);
        if (attempt === MAX_RETRIES - 1) {
           console.error(`Failed to generate unique publicUserId after ${MAX_RETRIES} attempts for sub: ${subId}`);
           throw new Error("Failed to generate unique publicUserId due to too many collisions.");
        }
      } else {
        console.error(`DynamoDB PutItem error for sub: ${subId}`, error);
        throw new Error(`Error putting item to DynamoDB: ${error.message}`);
      }
    }
  }
};