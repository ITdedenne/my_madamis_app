import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/group_search/domain/repositories/group_search_repository.dart';
import 'package:my_madamis_app/features/group_search/domain/usecases/find_group_scenarios_usecase.dart';

import 'find_group_scenarios_usecase_test.mocks.dart';

@GenerateMocks([GroupSearchRepository])
void main() {
  late FindGroupScenariosUseCase usecase;
  late MockGroupSearchRepository mockRepository;

  setUp(() {
    mockRepository = MockGroupSearchRepository();
    usecase = FindGroupScenariosUseCase(mockRepository);
  });

  test('正常系: 指定メンバーが8人以下の場合はRepositoryを呼び出して結果を返す', () async {
    final friendIds = ['user1', 'user2'];
    when(mockRepository.findGroupScenarios(friendIds)).thenAnswer((_) async => []);

    final result = await usecase(friendIds);
    expect(result, []);
    verify(mockRepository.findGroupScenarios(friendIds)).called(1);
  });

  test('異常系: 9人以上のフレンドIDを渡した場合、通信を行わずにExceptionがスローされる', () async {
    final friendIds = List.generate(9, (index) => 'user$index');

    expect(
      () => usecase(friendIds),
      throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('最大8人までです'))),
    );
    verifyNever(mockRepository.findGroupScenarios(any));
  });
}