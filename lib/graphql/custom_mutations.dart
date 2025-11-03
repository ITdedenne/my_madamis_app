// lib/graphql/custom_mutations.dart (新規作成)

const updateUserScenarioStatusMutation = '''
mutation UpdateUserScenarioStatus(
  \$userId: ID!,
  \$scenarioId: ID!,
  \$isPlayed: Boolean!,
  \$isPossessed: Boolean!
) {
  updateUserScenarioStatusByLambda(
    userId: \$userId,
    scenarioId: \$scenarioId,
    isPlayed: \$isPlayed,
    isPossessed: \$isPossessed
  ) {
    id
    isPlayed
    isPossessed
    # Lambda関数が返さないフィールドは、リクエストしないことでエラーを回避できます
    # 必要に応じて user { id } や scenario { id } を追加しても良いですが、Lambda側でそれらを解決する必要があります。
  }
}
''';