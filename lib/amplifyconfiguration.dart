const amplifyconfig = '''{
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "api": {
        "plugins": {
            "awsAPIPlugin": {
                "mymadamisapp": {
                    "endpointType": "GraphQL",
                    "endpoint": "https://blfnjgvjsvf3de5sjofhdovuye.appsync-api.ap-northeast-1.amazonaws.com/graphql",
                    "region": "ap-northeast-1",
                    "authorizationType": "AMAZON_COGNITO_USER_POOLS"
                }
            }
        }
    },
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "UserAgent": "aws-amplify-cli/0.1.0",
                "Version": "0.1.0",
                "IdentityManager": {
                    "Default": {}
                },
                "AppSync": {
                    "Default": {
                        "ApiUrl": "https://blfnjgvjsvf3de5sjofhdovuye.appsync-api.ap-northeast-1.amazonaws.com/graphql",
                        "Region": "ap-northeast-1",
                        "AuthMode": "AMAZON_COGNITO_USER_POOLS",
                        "ClientDatabasePrefix": "mymadamisapp_AMAZON_COGNITO_USER_POOLS"
                    }
                },
                "CredentialsProvider": {
                    "CognitoIdentity": {
                        "Default": {
                            "PoolId": "ap-northeast-1:7d052071-c231-4570-b91d-90c52f3d9f84",
                            "Region": "ap-northeast-1"
                        }
                    }
                },
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "ap-northeast-1_62bofFfAm",
                        "AppClientId": "5gaap8iqv0l2akgvh05t1n1niq",
                        "Region": "ap-northeast-1"
                    }
                },
                "Auth": {
                    "Default": {
                        "authenticationFlowType": "USER_SRP_AUTH",
                        "mfaConfiguration": "OFF",
                        "mfaTypes": [
                            "SMS"
                        ],
                        "passwordProtectionSettings": {
                            "passwordPolicyMinLength": 8,
                            "passwordPolicyCharacters": []
                        },
                        "signupAttributes": [
                            "EMAIL",
                            "PREFERRED_USERNAME"
                        ],
                        "socialProviders": [],
                        "usernameAttributes": [
                            "EMAIL"
                        ],
                        "verificationMechanisms": [
                            "EMAIL"
                        ]
                    }
                },
                "S3TransferUtility": {
                    "Default": {
                        "Bucket": "mymadamisapp-master-data7ec08-dev",
                        "Region": "ap-northeast-1"
                    }
                }
            }
        }
    },
    "storage": {
        "plugins": {
            "awsS3StoragePlugin": {
                "bucket": "mymadamisapp-master-data7ec08-dev",
                "region": "ap-northeast-1",
                "defaultAccessLevel": "guest"
            }
        }
    }
}''';
