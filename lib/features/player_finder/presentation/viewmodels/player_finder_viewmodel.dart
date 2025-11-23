// ファイルパス: lib/features/player_finder/presentation/viewmodels/player_finder_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/player_finder/domain/usecases/find_unplayed_friends_usecase.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'package:my_madamis_app/providers.dart';

// UseCaseのプロバイダー
final findUnplayedFriendsUseCaseProvider = Provider<FindUnplayedFriendsUseCase>((ref) {
  return FindUnplayedFriendsUseCase(ref.watch(playerFinderRepositoryProvider));
});

// familyを使ってシナリオIDごとに状態を管理する (AutoDisposeで自動破棄)
// AsyncValue<List<User>> が状態となるため、独自のStateクラスは廃止
final playerFinderProvider = StateNotifierProvider.autoDispose
    .family<PlayerFinderViewModel, AsyncValue<List<User>>, String>((ref, scenarioId) {
  return PlayerFinderViewModel(
    ref.watch(findUnplayedFriendsUseCaseProvider),
    scenarioId,
  );
});

class PlayerFinderViewModel extends StateNotifier<AsyncValue<List<User>>> {
  final FindUnplayedFriendsUseCase _useCase;
  final String _scenarioId;

  // 初期化時に loading 状態にする
  PlayerFinderViewModel(this._useCase, this._scenarioId) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    // AsyncValue.guard が try-catch を代行し、エラー時は AsyncError に変換してくれる
    state = await AsyncValue.guard(() => _useCase(_scenarioId));
  }
  
  // リトライなどのために手動で再取得するメソッド
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _useCase(_scenarioId));
  }
}