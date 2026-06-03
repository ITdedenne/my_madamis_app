import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/update_user_scenario_status_usecase.dart';

import 'update_user_scenario_status_usecase_test.mocks.dart';

@GenerateMocks([ScenarioRepository])
void main() {
  late UpdateUserScenarioStatusUseCase useCase;
  late MockScenarioRepository mockRepository;

  setUp(() {
    mockRepository = MockScenarioRepository();
    useCase = UpdateUserScenarioStatusUseCase(mockRepository);
  });

  group('UpdateUserScenarioStatusUseCase', () {
    test('【正常系】ステータスが未登録(すべてfalse)でない場合、updateUserScenarioStatusが呼ばれること', () async {
      when(mockRepository.updateUserScenarioStatus(any, any))
          .thenAnswer((_) async => {});

      // 少なくとも1つがtrueの状態
      const status = UserScenarioStatus(isPlayed: true);
      await useCase('scenario_1', status);

      // updateが呼ばれ、removeは呼ばれないことを検証
      verify(mockRepository.updateUserScenarioStatus('scenario_1', status)).called(1);
      verifyNever(mockRepository.removeUserScenarioStatus(any));
    });

    test('【正常系】ステータスが未登録(すべてfalse)の場合、removeUserScenarioStatusが呼ばれること', () async {
      when(mockRepository.removeUserScenarioStatus(any))
          .thenAnswer((_) async => {});

      // すべてfalseの状態 (isUnregistered == true)
      const status = UserScenarioStatus(); 
      await useCase('scenario_1', status);

      // removeが呼ばれ、updateは呼ばれないことを検証
      verify(mockRepository.removeUserScenarioStatus('scenario_1')).called(1);
      verifyNever(mockRepository.updateUserScenarioStatus(any, any));
    });
  });
}