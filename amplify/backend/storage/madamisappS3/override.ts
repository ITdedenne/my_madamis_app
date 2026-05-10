// amplify/backend/storage/madamisappS3/overrides.ts
import { AmplifyS3ResourceTemplate } from '@aws-amplify/cli-extensibility-helper';

export function override(resources: AmplifyS3ResourceTemplate) {
  // s3Bucketが存在する場合のみ設定を行うようにガードを入れます
  if (resources.s3Bucket) {
    resources.s3Bucket.corsConfiguration = {
      corsRules: [
        {
          allowedHeaders: ['*'],
          allowedMethods: ['GET', 'HEAD'],
          allowedOrigins: ['*'],
          exposedHeaders: ['ETag'],
          maxAge: 3000
        },
      ],
    };
  }
}