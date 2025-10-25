// amplify/backend/custom/s3EventBridgeRule/cdk-stack.ts
import * as cdk from 'aws-cdk-lib';
import * as AmplifyHelpers from '@aws-amplify/cli-extensibility-helper';
import { Rule, EventPattern, RuleTargetInput } from 'aws-cdk-lib/aws-events';
import { LambdaFunction } from 'aws-cdk-lib/aws-events-targets';
import { Function as Lambda } from 'aws-cdk-lib/aws-lambda';
import { CfnPermission } from 'aws-cdk-lib/aws-lambda';

export class cdkStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string, props?: cdk.StackProps, amplifyResourceProps?: AmplifyHelpers.AmplifyResourceProps) {
    super(scope, id, props);
    /* Do not remove - Amplify CLI automatically injects the current deployment environment in this input parameter */
    new cdk.CfnParameter(this, 'env', {
      type: 'String',
      description: 'Current Amplify CLI env name',
    });

    // --- リソース名の取得 ---
    // Lambda関数名をAmplifyプロジェクト情報から構築
    const functionName = AmplifyHelpers.getProjectInfo().projectName + 'csvImporterFunction' + '-' + AmplifyHelpers.getProjectInfo().envName;

    // ★★★ 修正箇所: S3バケット名を CfnParameter から取得 ★★★
    // Amplify CLI が 'amplify push' 時に自動的にこのパラメータに値を注入します。
    // パラメータ名は amplify/backend/backend-config.json の custom リソースの dependsOn で指定した
    // storage リソース名 (`myMadamisAppS3storage`) + 'BucketName' という命名規則になります。
    const bucketNameParameter = new cdk.CfnParameter(this, 'storagemyMadamisAppS3storageBucketName', {
        type: 'String',
        description: 'Name of the S3 bucket created by Amplify Storage category'
    });
    const bucketName = bucketNameParameter.valueAsString;
    // ----------------------------------------------------

    // --- Lambda関数オブジェクトの取得 ---
    const lambdaFunction = Lambda.fromFunctionName(this, 'csvImporterLambdaFunction', functionName);

    // --- EventBridge ルールの定義 ---
    const eventPattern: EventPattern = {
      source: ['aws.s3'],
      detailType: ['Object Created'],
      detail: {
        bucket: {
          name: [bucketName] // パラメータから取得したバケット名を使用
        },
        // 必要であればフィルタリングを追加
        // object: {
        //   key: [{ suffix: '.csv' }]
        // }
      },
    };

    const rule = new Rule(this, 'S3CsvUploadRule', {
      ruleName: `s3-${AmplifyHelpers.getProjectInfo().projectName}-csv-upload-rule-${AmplifyHelpers.getProjectInfo().envName}`, // プロジェクト名を含むように修正
      description: 'Triggers Lambda when a CSV is uploaded to the specified S3 bucket',
      eventPattern: eventPattern,
    });

    // --- Lambdaターゲットの追加 ---
    rule.addTarget(new LambdaFunction(lambdaFunction, {
      // InputTransformer は前回同様コメントアウト (Lambda側でevent['detail']を処理するため)
      /*
      event: RuleTargetInput.fromObject({
        bucket: JsonPath.stringAt('$.detail.bucket.name'),
        key: JsonPath.stringAt('$.detail.object.key'),
      })
      */
    }));

    // --- EventBridge が Lambda を呼び出すための権限を明示的に付与 ---
    new CfnPermission(this, 'AllowEventBridgeInvokeLambdaPermission', {
        functionName: lambdaFunction.functionName,
        action: 'lambda:InvokeFunction',
        principal: 'events.amazonaws.com',
        sourceArn: rule.ruleArn,
    });

    // --- 不要になった可能性のあるパラメータ定義を削除 ---
    // Amplifyが自動生成したかもしれない他のリソースパラメータ (例: GraphQL API IDなど) で、
    // このスタック内で直接使用していないものは削除しても構いません。
    // ただし、'env' と 'storagemyMadamisAppS3storageBucketName' は必要です。
    // (functioncsvImporterFunctionArn なども不要です)

  }
}