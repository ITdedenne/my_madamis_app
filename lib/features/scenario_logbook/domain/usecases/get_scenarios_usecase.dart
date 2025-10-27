// ファイルパス: lib/features/scenario_logbook/domain/usecases/get_scenarios_usecase.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';
import 'package:my_madamis_app/features/scenario_logbook/data/repositories/scenario_repository_impl.dart'; // ★追加: RepositoryImplをインポート

// ViewModelが要求する戻り値の型を定義
typedef ScenarioFetchResult = ({List<Scenario> scenarios, String? nextToken});

class GetScenariosUseCase {
  final ScenarioRepositoryImpl _repository; // ★修正: RepositoryImplの型を使用
  GetScenariosUseCase(ScenarioRepository repository) : _repository = repository as ScenarioRepositoryImpl; // ★修正: キャスト

  // ★★★ 修正: nextTokenを引数に取り、タプル (scenarios, nextToken) を返す ★★★
  Future<ScenarioFetchResult> call({
    required int page,
    int limit = 50,
    String? searchTerm,
    RangeValues? playerCountRange,
    GmRequirement? gmRequirement,
    String? authorName,
    String? startToken, // ★★★ ViewModelから渡された nextToken ★★★
  }) {
    // RepositoryImplの内部メソッドを呼び出す
    return _repository.fetchScenariosInternal(
      limit: limit,
      searchTerm: searchTerm,
      playerCountRange: playerCountRange,
      gmRequirement: gmRequirement,
      authorName: authorName,
      nextToken: startToken,
    );
  }
}