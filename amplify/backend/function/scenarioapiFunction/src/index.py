import json

def handler(event, context):
    # TODO: ここに実行したい処理を記述します
    
    print("Lambda function invoked")
    print(f"Event received: {event}")
    
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Headers': '*',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'body': json.dumps('Hello from Lambda!')
    }