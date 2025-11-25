import json
import os
import boto3
from concurrent.futures import ThreadPoolExecutor
from boto3.dynamodb.conditions import Key, Attr

# --- 環境変数 ---
ENV = os.environ['ENV']
REGION = os.environ['REGION']
API_ID = os.environ['API_MYMADAMISAPP_GRAPHQLAPIIDOUTPUT']

# --- 定数 ---
USER_SCENARIO_TABLE_NAME = f'UserScenario-{API_ID}-{ENV}'
USER_RELATIONSHIP_TABLE_NAME = f'UserRelationship-{API_ID}-{ENV}'

# --- AWS リソース ---
dynamodb = boto3.resource('dynamodb', region_name=REGION)
user_scenario_table = dynamodb.Table(USER_SCENARIO_TABLE_NAME)
user_relationship_table = dynamodb.Table(USER_RELATIONSHIP_TABLE_NAME)

def fetch_user_status(user_id):
    """
    指定ユーザーのステータスを取得
    """
    try:
        response = user_scenario_table.query(
            IndexName='byUser',
            KeyConditionExpression=Key('userId').eq(user_id),
            FilterExpression=Attr('isPlayed').eq(True) | Attr('isPossessed').eq(True) | Attr('wantsToGm').eq(True) | Attr('wantsToPlay').eq(True),
            ProjectionExpression='scenarioId, isPlayed, isPossessed, wantsToGm, wantsToPlay'
        )
        return user_id, response.get('Items', [])
    except Exception as e:
        print(f"Error fetching status for user {user_id}: {e}")
        return user_id, []

def handler(event, context):
    print("=== findGroupScenarios START (V3 Full Search) ===")
    
    try:
        arguments = event.get('arguments', {})
        identity = event.get('identity', {})
        
        requesting_user_id = identity.get('sub')
        # 選択されたメンバー（自分以外）
        selected_friend_ids = set(arguments.get('friendIds', []))
        
        if not requesting_user_id:
            raise ValueError("Unauthorized")

        # 1. 全フレンドを取得 (外部GM候補を探すため)
        # ページネーション対応が必要だが、一旦簡易実装とする
        rel_response = user_relationship_table.query(
            KeyConditionExpression=Key('followingId').eq(requesting_user_id)
        )
        all_friend_ids = {item['followedId'] for item in rel_response.get('Items', [])}
        
        # 検索対象ユーザー群
        # A: 選択メンバー (自分 + 選択したフレンド) -> NG判定対象
        target_members = selected_friend_ids | {requesting_user_id}
        # B: 選択外フレンド -> 外部GM候補対象
        other_friends = all_friend_ids - selected_friend_ids

        # 2. 並列で全対象のステータス取得
        # コスト注意: フレンド100人いると100並列になるため、適度にワーカー数を制限
        all_targets = target_members | other_friends
        
        user_status_map = {}
        with ThreadPoolExecutor(max_workers=20) as executor:
            futures = [executor.submit(fetch_user_status, uid) for uid in all_targets]
            for future in futures:
                uid, items = future.result()
                user_status_map[uid] = items

        # 3. 集計
        ng_scenario_ids = set()
        metadata = {} 
        # metadata structure: 
        # { 
        #   scenarioId: { 
        #     wantsToPlay: [uid...], 
        #     externalHolders: [uid...] 
        #   } 
        # }

        # A. 選択メンバーの判定 (NG or PL希望)
        for uid in target_members:
            items = user_status_map.get(uid, [])
            for item in items:
                sid = item['scenarioId']
                
                # NG判定: 通過済 or 所持 or GM検討
                # ※「所持・GM検討」もネタバレありとみなしてNGにするのが一般的
                if item.get('isPlayed') or item.get('isPossessed') or item.get('wantsToGm'):
                    ng_scenario_ids.add(sid)
                
                # PL希望判定 (NGリストに入っていても、希望情報は記録しておく)
                if item.get('wantsToPlay'):
                    if sid not in metadata: metadata[sid] = {'wantsToPlay': [], 'externalHolders': []}
                    metadata[sid]['wantsToPlay'].append(uid)

        # B. 選択外フレンドの判定 (外部GM候補)
        for uid in other_friends:
            items = user_status_map.get(uid, [])
            for item in items:
                sid = item['scenarioId']
                # 所持 or GM検討 なら候補
                if item.get('isPossessed') or item.get('wantsToGm'):
                    if sid not in metadata: metadata[sid] = {'wantsToPlay': [], 'externalHolders': []}
                    metadata[sid]['externalHolders'].append(uid)

        # 4. レスポンス整形
        # クライアント側で「全シナリオ - NG」をするため、
        # ここでは「NGリスト」と「ポジティブ情報(PL希望/外部GM)」のみを返す。
        
        response_metadata = []
        for sid, data in metadata.items():
            # データがあるものだけ返す
            if data['wantsToPlay'] or data['externalHolders']:
                response_metadata.append({
                    'scenarioId': sid,
                    'wantsToPlayUserIds': data['wantsToPlay'],
                    'externalHolderUserIds': data['externalHolders']
                })

        result = {
            'ngScenarioIds': list(ng_scenario_ids),
            'metadata': response_metadata
        }
        
        print(f"NG Count: {len(ng_scenario_ids)}, Metadata Count: {len(response_metadata)}")
        return json.dumps(result)

    except Exception as e:
        print(f"[ERROR] {e}")
        return json.dumps({'ngScenarioIds': [], 'metadata': []})