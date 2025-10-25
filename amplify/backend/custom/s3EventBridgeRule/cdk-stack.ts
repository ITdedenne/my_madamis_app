import * as cdk from 'aws-cdk-lib';
import * as AmplifyHelpers from '@aws-amplify/cli-extensibility-helper';
import { Rule, EventPattern } from 'aws-cdk-lib/aws-events';
import { LambdaFunction } from 'aws-cdk-lib/aws-events-targets';
import { Function as Lambda } from 'aws-cdk-lib/aws-lambda';

export class cdkStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string, props?: cdk.StackProps, amplifyResourceProps?: AmplifyHelpers.AmplifyResourceProps) {
    super(scope, id, props);
    new cdk.CfnParameter(this, 'env', { type: 'String' });

    // 1. LambdaのARNを取得
    const lambdaArnParameter = new cdk.CfnParameter(this, 'functioncsvImporterFunctionArn', { type: 'String' });
    const lambdaArn = lambdaArnParameter.valueAsString;
    
    // 2. S3バケット名を取得
    const bucketNameParameter = new cdk.CfnParameter(this, 'storagemyMadamisAppS3storageBucketName', { type: 'String' });
    const bucketName = bucketNameParameter.valueAsString;

    // ★ エラー回避のための「使用しない」パラメータ ★
    new cdk.CfnParameter(this, 'functioncsvImporterFunctionRegion', { type: 'String' });
    new cdk.CfnParameter(this, 'storagemyMadamisAppS3storageRegion', { type: 'String' });
    new cdk.CfnParameter(this, 'functioncsvImporterFunctionLambdaExecutionRoleArn', { type: 'String' });
    new cdk.CfnParameter(this, 'functioncsvImporterFunctionName', { type: 'String' });
    new cdk.CfnParameter(this, 'functioncsvImporterFunctionLambdaExecutionRole', { type: 'String' });

    const lambdaFunction = Lambda.fromFunctionArn(this, 'csvImporterFunction', lambdaArn);
    
    const eventPattern: EventPattern = {
      source: ['aws.s3'],
      detailType: ['Object Created'], 
      detail: { bucket: { name: [bucketName] } },
    };

    const rule = new Rule(this, 'S3EventBridgeRule', {
      eventPattern: eventPattern,
      description: 'S3 Object Created event trigger (Direct)',
    });

    rule.addTarget(new LambdaFunction(lambdaFunction));
  }
}