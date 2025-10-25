// amplify/backend/storage/myMadamisAppS3storage/override.ts
import { AmplifyS3ResourceTemplate } from '@aws-amplify/cli-extensibility-helper';

/**
 * @see https://docs.amplify.aws/cli/storage/override/
 */
export function override(resources: AmplifyS3ResourceTemplate) {
  // S3バケットリソース (L1 Cfn Construct) に直接プロパティを追加
  // S3コンソールで「イベント通知」->「EventBridgeへ送信」を有効にするのと同じ設定
  resources.s3Bucket.addPropertyOverride('NotificationConfiguration', {
    EventBridgeConfiguration: {
      EventBridgeEnabled: true, // これを true に設定
    },
  });

  // 必要であれば他の S3 設定の override もここに追加できます
  // 例: バケットポリシー、ライフサイクルルールなど
  // resources.addCfnParameter(...);
  // resources.addCfnOutput(...);
  // resources.addCfnMapping(...);
  // resources.addCfnCondition(...);
  // resources.addCfnResource(...);
}