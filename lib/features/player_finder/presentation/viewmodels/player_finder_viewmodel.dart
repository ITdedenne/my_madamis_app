import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/player_finder/domain/entities/searched_user.dart'; // ★ 追加
import 'package:my_madamis_app/features/player_finder/domain/usecases/find_unplayed_friends_usecase.dart';
import 'package:my_madamis_app/providers.dart';

// Providerを作成
final findUnplayedFriendsUseCaseProvider = Provider<FindUnplayedFriendsUseCase>((ref) {
  return FindUnplayedFriendsUseCase(ref.watch(playerFinderRepositoryProvider));
});

// Stateの型を AsyncValue<List<SearchedUser>> に変更
final playerFinderProvider = StateNotifierProvider.autoDispose
    .family<PlayerFinderViewModel, AsyncValue<List<SearchedUser>>, String>((ref, scenarioId) {
  return PlayerFinderViewModel(
    ref.watch(findUnplayedFriendsUseCaseProvider),
    scenarioId,
  );
});

class PlayerFinderViewModel extends StateNotifier<AsyncValue<List<SearchedUser>>> {
  final FindUnplayedFriendsUseCase _useCase;
  final String _scenarioId;

  PlayerFinderViewModel(this._useCase, this._scenarioId) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = await AsyncValue.guard(() async {
      final users = await _useCase(_scenarioId);
      
      // ★ ソートロジック: wantsToPlay == true を先頭に
      users.sort((a, b) {
        if (a.wantsToPlay && !b.wantsToPlay) return -1;
        if (!a.wantsToPlay && b.wantsToPlay) return 1;
        return 0; 
      });
      
      return users;
    });
  }
  
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _init(); 
  }
}