// lib/features/scenario_logbook/domain/usecases/get_my_list_usecase.dart

import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';
import 'package:my_madamis_app/models/ModelProvider.dart'; // Amplifyモデルを import

// クラス名を GetMyListUseCase (Cを大文字) にします
class GetMyListUseCase {
  final ScenarioRepository _repository;
  GetMyListUseCase(this._repository);

  // 引数で userId を受け取り、リポジトリの新しいメソッドを呼ぶ
  Future<List<ScenarioLogbookEntry>> call(String userId) {
    return _repository.getMyScenarioLogbook(userId);
  }
}