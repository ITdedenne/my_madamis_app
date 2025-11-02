// lib/features/scenario_logbook/domain/usecases/update_user_scenario_status_usecase.dart

// 古い import を削除
// import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';

// クラス名を Usecase に修正
class UpdateUserScenarioStatusUsecase {
  final ScenarioRepository _repository;
  UpdateUserScenarioStatusUsecase(this._repository);

  // call メソッドの引数を ViewModel から渡される形に修正
  Future<void> call({
    required String userId,
    required String scenarioId,
    required bool isPlayed,
    required bool isPossessed,
  }) {
    // リポジトリの新しいメソッドを呼び出すように修正
    return _repository.updateUserScenarioStatus(
      userId: userId,
      scenarioId: scenarioId,
      isPlayed: isPlayed,
      isPossessed: isPossessed,
    );
  }
}