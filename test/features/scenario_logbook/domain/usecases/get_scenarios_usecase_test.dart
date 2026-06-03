import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_scenarios_usecase.dart';

import 'get_scenarios_usecase_test.mocks.dart';

@GenerateMocks([ScenarioRepository])
void main() {
  late GetScenariosUseCase useCase;
  late MockScenarioRepository mockRepository;

  setUp(() {
    mockRepository = MockScenarioRepository();
    useCase = GetScenariosUseCase(mockRepository);
  });

  final tScenarioList = [
    Scenario(
      id: '1',
      title: 'テストシナリオ1',
      authorName: '作者A',
      authorId: 'auth_1',
      minPlayerCount: 2,
      maxPlayerCount: 4,
      gmRequirement: GmRequirement.required,
      titleLower: 'テストシナリオ1',
      authorNameLower: '作者a',
    )
  ];

  group('GetScenariosUseCase', () {
    test('【正常系】リポジトリからシナリオ一覧を正しく取得できること', () async {

      when(mockRepository.fetchScenarios(
        page: 1,
        limit: 50,
      )).thenAnswer((_) async => tScenarioList);

      final result = await useCase(page: 1);

      expect(result, equals(tScenarioList));
      verify(mockRepository.fetchScenarios(page: 1, limit: 50)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('【異常系】リポジトリで例外が発生した場合、ユースケースも例外をスローすること', () async {

      when(mockRepository.fetchScenarios(page: 1, limit: 50))
          .thenThrow(Exception('Server Error'));

      expect(() => useCase(page: 1), throwsException);
    });
  });
}