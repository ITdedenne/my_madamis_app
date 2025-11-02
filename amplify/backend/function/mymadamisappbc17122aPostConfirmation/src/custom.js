/**
 * Cognito Post Confirmation Trigger:
 * 認証完了後、ユーザーのSubIDをDynamoDBのUserテーブルに追加し、一意の7桁のfriendIDを生成します。
 * * @type {import('@types/aws-lambda').PostConfirmationTriggerHandler}
 */
const aws = require('aws-sdk');
const crypto = require('crypto');
const docClient = new aws.DynamoDB.DocumentClient();

// 環境変数からDynamoDBテーブル名を取得します。
// AmplifyはLambdaの実行ロールにこのテーブルへのアクセス権限を付与する必要があります。
const tableName = process.env.USER_TABLE_NAME;

// ----------------------------------------------------------------------
// 1. ユーティリティ関数
// ----------------------------------------------------------------------

/**
 * ISO 8601形式のタイムスタンプ ('Z'付き) を生成します。
 * AppSync/DataStoreとの互換性のため。
 * @returns {string} ISO 8601形式の時刻文字列
 */
const getIsoTime = () => {
    return new Date().toISOString().replace(/\.000Z$/, 'Z');
};

/**
 * 7桁の一意なフレンドIDを生成し、DynamoDBで重複がないか確認します。
 * @returns {Promise<string>} 一意な7桁の数字の文字列
 */
const generateUniqueFriendId = async () => {
    const FRIEND_ID_GSI = 'byFriendID';

    while (true) {
        // 7桁の数字を生成 (1000000 から 9999999)
        const friendId = String(Math.floor(1000000 + Math.random() * 9000000));
        
        const params = {
            TableName: tableName,
            IndexName: FRIEND_ID_GSI,
            KeyConditionExpression: 'friendID = :id',
            ExpressionAttributeValues: {
                ':id': friendId
            },
            Limit: 1
        };

        try {
            const data = await docClient.query(params).promise();

            // 項目が見つからなければ、一意と判断
            if (data.Count === 0) {
                return friendId;
            }
        } catch (error) {
            console.error('DynamoDB query error during friendID generation:', error);
            // エラーが発生した場合は、念のためループを継続（リトライ）
            // 致命的なエラーであればここで例外を投げることも検討
        }
    }
};

// ----------------------------------------------------------------------
// 2. Lambdaハンドラ関数
// ----------------------------------------------------------------------

exports.handler = async (event) => {
    console.log('Cognito Post Confirmation Event:', JSON.stringify(event, null, 2));

    // Cognitoからユーザー情報を取得
    const userId = event.request.userAttributes.sub; // SubID (UserテーブルのPK: id)
    const username = event.userName; // ユーザー名 (通常、Cognitoのユーザー名)

    // テーブル名が定義されていない場合はエラー
    if (!tableName) {
        console.error('Error: USER_TABLE_NAME environment variable is not set.');
        // 認証フローは続行させるため、イベントを返却
        return event;
    }

    try {
        // 1. 一意のフレンドIDを生成
        const friendId = await generateUniqueFriendId();

        // 2. DynamoDBのUserテーブルにユーザーレコードを作成
        const item = {
            id: userId,
            username: username,
            friendID: friendId,
            __typename: 'User', // AppSync/DataStore互換
            createdAt: getIsoTime(),
            updatedAt: getIsoTime(),
            owner: userId // @auth(owner) 互換
        };
        
        const putParams = {
            TableName: tableName,
            Item: item
        };

        await docClient.put(putParams).promise();
        
        console.log(`Successfully created user ${userId} with friendID ${friendId}`);

    } catch (error) {
        console.error('Error during DynamoDB put operation:', error);
        // 認証フローは続行させるため、例外を投げずにイベントを返却
    }

    // Post Confirmationトリガーは元のイベントをそのまま返す必要があります
    return event;
};