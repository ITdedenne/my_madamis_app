// amplify/backend/custom/s3EventBridgeRule/cdk-stack.ts
import * as cdk from 'aws-cdk-lib';
import * as AmplifyHelpers from '@aws-amplify/cli-extensibility-helper';
import { Rule, EventPattern } from 'aws-cdk-lib/aws-events';
import { LambdaFunction } from 'aws-cdk-lib/aws-events-targets';
import { Function as Lambda } from 'aws-cdk-lib/aws-lambda';
import { CfnPermission } from 'aws-cdk-lib/aws-lambda';

export class cdkStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string, props?: cdk.StackProps, amplifyResourceProps?: AmplifyHelpers.AmplifyResourceProps) {
    super(scope, id, props);

    /* Do not remove - Amplify CLI automatically injects the current deployment environment in this input parameter */
    const env = new cdk.CfnParameter(this, 'env', {
      type: 'String',
      description: 'Current Amplify CLI env name',
    });

    // --- 1. S3バケット名を取得 (Amplifyが渡すパラメータ) ---
    // backend-config.json の dependsOn に基づき、Amplifyが自動で値を渡します
    // category: 'storage', resourceName: 'myMadamisAppS3storage' (-> MyMadamisAppS3storage), attribute: 'BucketName'
    // パラメータ名: storageMyMadamisAppS3storageBucketName
    const bucketNameParameter = new cdk.CfnParameter(this, 'storageMyMadamisAppS3storageBucketName', {
        type: 'String',
        description: 'Name of the S3 bucket (from dependsOn)'
    });
    const bucketName = bucketNameParameter.valueAsString;

    // --- 2. Lambda関数のARNを取得 (Amplifyが渡すパラメータ) ---
    // category: 'function', resourceName: 'csvImporterFunction' (-> CsvImporterFunction), attribute: 'Arn'
    // パラメータ名: functionCsvImporterFunctionArn
    const functionArnParameter = new cdk.CfnParameter(this, 'functionCsvImporterFunctionArn', {
        type: 'String',
        description: 'ARN of the csvImporterFunction (from dependsOn)'
    });
    const functionArn = functionArnParameter.valueAsString;

    // --- 3. Lambda関数名を取得 (Amplifyが渡すパラメータ) ---
    // CfnPermission で必要
    // category: 'function', resourceName: 'csvImporterFunction' (-> CsvImporterFunction), attribute: 'Name'
    // パラメータ名: functionCsvImporterFunctionName
    const functionNameParameter = new cdk.CfnParameter(this, 'functionCsvImporterFunctionName', {
        type: 'String',
        description: 'Name of the csvImporterFunction (from dependsOn)'
    });
    const functionName = functionNameParameter.valueAsString;

    // --- 4. ARNからLambda関数オブジェクトを取得 ---
    const lambdaFunction = Lambda.fromFunctionArn(this, 'csvImporterLambdaFunction', functionArn);

    // --- 5. EventBridge ルールの定義 ---
    const eventPattern: EventPattern = {
      source: ['aws.s3'],
      detailType: ['Object Created'], // オブジェクト作成イベント
      detail: {
        bucket: {
          name: [bucketName] // パラメータで受け取ったバケット名でフィルタ
        },
        // 必要に応じてCSVファイルのみに絞り込む (コメントアウト中)
        // object: {
        //   key: [{ suffix: '.csv' }]
        // }
      },
    };

    const rule = new Rule(this, 'S3CsvUploadRule', {
      // 環境名を含めてルール名を一意にする
      ruleName: cdk.Fn.join('-', [
        's3-csv-upload-rule',
        AmplifyHelpers.getProjectInfo().projectName, // "mymadamisapp"
        env.valueAsString // "dev" など
      ]),
      description: 'Triggers Lambda when a file is created in the S3 bucket',
      eventPattern: eventPattern,
    });

    // --- 6. Lambda関数をルールの一番目のターゲットとして追加 ---
    rule.addTarget(new LambdaFunction(lambdaFunction, {
        // 必要に応じてリトライポリシーやデッドレターキュー(DLQ)を設定
        // retryAttempts: 2,
    }));
    
    // --- 7. EventBridge が Lambda を呼び出すための権限を付与 ---
    // Lambda関数側にリソースベースポリシーが追加されます
    new CfnPermission(this, 'AllowEventBridgeInvokeLambdaPermission', {
        functionName: functionName, // ★ ARN ではなく Function *Name* を使用
        action: 'lambda:InvokeFunction',
        principal: 'events.amazonaws.com',
        sourceArn: rule.ruleArn, // このルールからの呼び出しのみを許可
    });

  }
}