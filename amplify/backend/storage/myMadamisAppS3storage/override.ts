import { AmplifyS3ResourceTemplate } from '@aws-amplify/cli-extensibility-helper';
// import { CfnBucket } from 'aws-cdk-lib/aws-s3'; // ★★★ CfnBucketのimportを削除します

/**
 * @see https://docs.amplify.aws/cli/storage/override/
 */
export function override(resources: AmplifyS3ResourceTemplate) {
  
  // ★★★ 'as CfnBucket' の型キャストを削除します
  // const s3Bucket = resources.s3Bucket as CfnBucket; 
  
  // resources.s3Bucket オブジェクトに直接プロパティを追加します
  resources.s3Bucket.addPropertyOverride('NotificationConfiguration', {
    EventBridgeConfiguration: {
      EventBridgeEnabled: true,
    },
  });

}