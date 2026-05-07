// /workspaces/my_madamis_app/amplify/backend/function/mymadamisappb2bf781dPostConfirmation/src/custom.js

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');

// ★ 修正: 環境変数から動的にテーブル名を作成
const API_ID = process.env.API_MYMADAMISAPP_GRAPHQLAPIIDOUTPUT;
const ENV = process.env.ENV;
const USER_TABLE_NAME = `User-${API_ID}-${ENV}`;

const MAX_RETRIES = 5;

// DynamoDBクライアントの初期化
const client = new DynamoDBClient({ region: process.env.REGION });
const ddbDocClient = DynamoDBDocumentClient.from(client);

/**
 * (5.2.1) 7桁のランダムな数字IDを生成する
 * @returns {string} 7桁のランダムな数字の文字列
 */
function generatePublicUserId() {
  // 1000000 から 9999999 までの7桁のランダムな整数を生成
  const min = 1000000;
  const max = 9999999;
  return String(Math.floor(Math.random() * (max - min + 1)) + min);
}

/**
 * Cognito Post Confirmation トリガーハンドラ (5.2.1)
 * @type {import('@types/aws-lambda').PostConfirmationTriggerHandler}
 */
exports.handler = async (event) => {
  // 新規ユーザー登録イベント (ConfirmSignUp) 以外では処理をスキップ
  if (event.triggerSource !== 'PostConfirmation_ConfirmSignUp') {
    console.log(`Skipping Post Confirmation for triggerSource: ${event.triggerSource}`);
    return event;
  }

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