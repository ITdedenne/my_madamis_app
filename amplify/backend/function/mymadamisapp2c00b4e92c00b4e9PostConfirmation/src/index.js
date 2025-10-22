/*
  このLambda関数は、Cognitoでのユーザー本登録（Post Confirmation）時にトリガーされます。
  AWS SDK v3 を使用して DynamoDB にユーザー情報を書き込みます。
*/

// AWS SDK v3 クライアントをインポート
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand, QueryCommand } = require("@aws-sdk/lib-dynamodb"); // QueryCommand を追加

// DynamoDBクライアントの初期化
// リージョンはLambda実行環境から自動的に取得されます
const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

/**
 * @type {import('@types/aws-lambda').PostConfirmationTriggerHandler}
 */
exports.handler = async (event) => {
  
  // 1. 環境変数のチェック
  // API名は 'mymadamisapp', モデル名は 'User' なので、環境変数は 'API_MYMADAMISAPP_USERTABLE_NAME'
  const tableName = process.env.API_MYMADAMISAPP_USERTABLE_NAME;
  if (!tableName) {
    console.error("[FATAL] Environment variable API_MYMADAMISAPP_USERTABLE_NAME is not set.");
    console.log("Ensure Lambda function has permissions to access the API/DynamoDB table via 'amplify update function'.");
    // 環境変数がない場合は処理を中断（Cognito登録自体は成功）
    return event;
  }
  console.log(`[INFO] Target DynamoDB Table: ${tableName}`);
  console.log('[INFO] Received Cognito event:', JSON.stringify(event, null, 2));


  // 2. ユニークなfriendIDの生成
  let friendID;
  let isTaken = true;
  let attempts = 0;
  const maxAttempts = 10;

  console.log('[INFO] Generating unique friendID...');

  while (isTaken && attempts < maxAttempts) {
    friendID = generateFriendID();
    console.log(`[INFO] Attempt ${attempts + 1}: Generated friendID: ${friendID}`);
    isTaken = await isFriendIDTaken(ddbDocClient, tableName, friendID);
    attempts++;
  }

  if (isTaken) {
    // 10回試行してもユニークなIDが見つからなかった場合（通常ありえない）
    console.error(`[ERROR] Failed to find unique friendID after ${maxAttempts} attempts.`);
    // エラーが発生してもCognitoプロセスは中断しない
    return event; 
  }

  console.log(`[SUCCESS] Unique friendID generated: ${friendID}`);

  // 3. Cognitoイベントからユーザー情報を取得
  // 'userAttributes'が存在するか確認
  if (!event.request || !event.request.userAttributes) {
      console.error('[ERROR] event.request.userAttributes is missing.');
      return event;
  }
  const userAttributes = event.request.userAttributes;
  
  const userId = userAttributes.sub; // 必須
  const username = userAttributes.preferred_username; // 必須 (schema.graphqlで String! のため)
  const userEmail = userAttributes.email; // 必須 (schema.graphqlにはないが、テーブルにあると便利)
  const customBio = userAttributes['custom:bio']; // カスタム属性 (存在しない可能性あり)
  
  // 必須属性が取得できているか確認
  if (!userId || !username || !userEmail) {
      console.error(`[ERROR] Missing essential user attributes: sub=${userId}, preferred_username=${username}, email=${userEmail}`);
      return event;
  }

  console.log(`[INFO] Processing user: ID=${userId}, Username=${username}, Email=${userEmail}`);

  // 4. DynamoDBに書き込むアイテムを作成
  const now = new Date().toISOString();
  const itemToPut = {
    id: userId,
    username: username,
    friendID: friendID,
    bio: customBio || null, // なければ null を設定
    email: userEmail,
    createdAt: now,         // @modelが自動付与するフィールド
    updatedAt: now,         // @modelが自動付与するフィールド
    // DataStore用フィールド (もしDataStoreを使う場合は必須)
    __typename: 'User',     // DataStore用に型名を指定
    _version: 1,            // DataStore用に初期バージョンを設定
    _lastChangedAt: Math.floor(Date.now() / 1000), // DataStore用にUnixタイムスタンプ(秒)
    _deleted: null,         // DataStore用に論理削除フラグ (nullは削除されていない)
  };

  // 5. DynamoDBに書き込み実行 (PutCommand を使用)
  const putParams = {
    TableName: tableName,
    Item: itemToPut,
  };

  try {
    console.log(`[INFO] Attempting to put item into ${tableName}:`, JSON.stringify(itemToPut));
    // PutCommand を使ってアイテムを書き込む
    const command = new PutCommand(putParams);
    await ddbDocClient.send(command);
    console.log(`[SUCCESS] Successfully added user ${userId} (FriendID: ${friendID}) to table ${tableName}`);
  } catch (err) {
    console.error(`[ERROR] Error adding user to table ${tableName}:`, err);
    // エラーの詳細を出力
    console.error("Error Name:", err.name);
    console.error("Error Message:", err.message);
    console.error("Error Stack:", err.stack);
    // エラーが発生してもCognitoプロセスは中断しない
  }

  // 6. Cognitoにイベントを返す (重要: 必ずeventオブジェクトを返す)
  console.log('[INFO] PostConfirmation Lambda finished successfully.');
  return event;
};


// --- ヘルパー関数 ---

/**
 * 7桁のランダムな数字文字列を生成します (例: "1234567")
 */
function generateFriendID() {
  const min = 1000000; 
  const max = 9999999; 
  const id = Math.floor(Math.random() * (max - min + 1)) + min;
  return id.toString();
}

/**
 * GSI (byFriendID) を検索し、指定されたfriendIDが既に使用されているか確認します。
 * AWS SDK v3 の QueryCommand を使用します。
 * @param {DynamoDBDocumentClient} docClient - AWS SDK v3 Document Client
 * @param {string} tableName - DynamoDBのテーブル名
 * @param {string} friendID - チェックするID
 * @returns {Promise<boolean>} - true (使用済み) / false (未使用)
 */
async function isFriendIDTaken(docClient, tableName, friendID) {
  // GSI (byFriendID) をクエリするためのパラメータ
   const params = {
    TableName: tableName,
    IndexName: 'byFriendID', // schema.graphqlで指定した @index の name
    KeyConditionExpression: 'friendID = :friendID', // GSIのパーティションキーで検索
    ExpressionAttributeValues: {
      ':friendID': friendID // プレースホルダーに値をセット
    },
    // GSIから取得する属性を最小限に絞る（Countだけでも良いが、念のため）
    ProjectionExpression: 'friendID' 
  };

  try {
    console.log(`[INFO] Querying GSI 'byFriendID' for friendID: ${friendID}`);
    // QueryCommand を使ってGSIを検索
    const command = new QueryCommand(params);
    const data = await docClient.send(command);
    
    // Items配列が存在し、かつ要素数が0より大きい場合は「使用済み」
    const count = data.Items?.length ?? 0;
    console.log(`[INFO] GSI Query result count for ${friendID}: ${count}`);
    return count > 0; 
    
  } catch (err) {
    console.error('[ERROR] Error querying GSI (byFriendID):', err);
     // エラーの詳細を出力
    console.error("Error Name:", err.name);
    console.error("Error Message:", err.message);
   // エラーが発生した場合は、安全のために「使用済み」とみなして再試行させます
    return true; 
  }
}