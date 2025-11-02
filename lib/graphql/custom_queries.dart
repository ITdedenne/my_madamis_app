// lib/graphql/custom_queries.dart

const String getMyScenarioLogbookQuery = '''
  query GetMyScenarioLogbook {
    getMyScenarioLogbook {
      id
      title
      minPlayerCount
      maxPlayerCount
      gmRequirement
      storeUrl
      authorId
      authorName
      isPlayed
      isPossessed
      createdAt
      updatedAt
    }
  }
''';

const String listScenariosWithMyStatusQuery = '''
  query ListScenariosWithMyStatus(
    \$userId: ID!, 
    \$filter: ModelScenarioFilterInput, 
    \$limit: Int, 
    \$nextToken: String, 
    \$sortDirection: ModelSortDirection
  ) {
    listScenariosWithMyStatus(
      userId: \$userId, 
      filter: \$filter, 
      limit: \$limit, 
      nextToken: \$nextToken, 
      sortDirection: \$sortDirection
    ) {
      items {
        id
        title
        minPlayerCount
        maxPlayerCount
        gmRequirement
        storeUrl
        authorId
        author {
          id
          authorName
          createdAt
          updatedAt
        }
        isPlayed
        isPossessed
        createdAt
        updatedAt
      }
      nextToken
    }
  }
''';