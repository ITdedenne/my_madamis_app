import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_my_list_usecase.dart';

import 'get_my_list_usecase_test.mocks.dart';

@GenerateMocks([ScenarioRepository])
void main() {
  late GetMyListUseCase useCase;
  late MockScenarioRepository mockRepository;

  setUp(() {
    mockRepository = MockScenarioRepository();
    useCase = GetMyListUseCase(mockRepository);
  });

  // UserScenario に渡すための Scenario モックデータ
  final tScenario = Scenario(
    id: '1',
    title: 'テストシナリオ1',
    authorName: '作者A',
    authorId: 'auth_1',
    minPlayerCount: 2,
    maxPlayerCount: 4,
    gmRequirement: GmRequirement.required,
    titleLower: 'テストシナリオ1',
    authorNameLower: '作者a',
  );

  final tUserScenarioList = [
    UserScenario(
      scenario: tScenario,
      status: const UserScenarioStatus(isPlayed: true), 
    )
  ];

  group('GetMyListUseCase', () {
    test('【正常系】リポジトリからマイリストを正しく取得できること', () async {
      when(mockRepository.fetchMyList()).thenAnswer((_) async => tUserScenarioList);

      final result = await useCase();

      expect(result, equals(tUserScenarioList));
      verify(mockRepository.fetchMyList()).called(1);
    });

    test('【異常系】リポジトリで例外が発生した場合、例外がスローされること', () async {
      when(mockRepository.fetchMyList()).thenThrow(Exception('DB Error'));

      expect(() => useCase(), throwsException);
    });
  });
}