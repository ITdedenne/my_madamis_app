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
    \$filter: String, 
    \$nextToken: String, 
    \$sort: String
  ) {
    listScenariosWithMyStatus(
      filter: \$filter, 
      nextToken: \$nextToken, 
      sort: \$sort
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