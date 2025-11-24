import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/player_finder/domain/entities/searched_user.dart';
import 'package:my_madamis_app/features/player_finder/domain/usecases/find_unplayed_friends_usecase.dart';
import 'package:my_madamis_app/providers.dart';

// ★ 検索モード定義
enum PlayerFinderMode { player, gm }

// ★ 状態クラスを作成してモードも管理
class PlayerFinderState {
  final AsyncValue<List<SearchedUser>> users;
  final PlayerFinderMode mode;

  PlayerFinderState({
    required this.users,
    this.mode = PlayerFinderMode.player,
  });

  PlayerFinderState copyWith({
    AsyncValue<List<SearchedUser>>? users,
    PlayerFinderMode? mode,
  }) {
    return PlayerFinderState(
      users: users ?? this.users,
      mode: mode ?? this.mode,
    );
  }
}

// Provider
final findUnplayedFriendsUseCaseProvider = Provider<FindUnplayedFriendsUseCase>((ref) {
  return FindUnplayedFriendsUseCase(ref.watch(playerFinderRepositoryProvider));
});

// ★ StateNotifierの型を変更
final playerFinderProvider = StateNotifierProvider.autoDispose
    .family<PlayerFinderViewModel, PlayerFinderState, String>((ref, scenarioId) {
  return PlayerFinderViewModel(
    ref.watch(findUnplayedFriendsUseCaseProvider),
    scenarioId,
  );
});

class PlayerFinderViewModel extends StateNotifier<PlayerFinderState> {
  final FindUnplayedFriendsUseCase _useCase;
  final String _scenarioId;

  PlayerFinderViewModel(this._useCase, this._scenarioId) 
      : super(PlayerFinderState(users: const AsyncValue.loading())) {
    _search();
  }

  Future<void> _search() async {
    state = state.copyWith(users: const AsyncValue.loading());
    
    final modeString = state.mode == PlayerFinderMode.gm ? 'gm' : 'player';

    final result = await AsyncValue.guard(() async {
      // ソートはLambda側で実行されるため、クライアント側でのソートは不要
      return await _useCase(_scenarioId, mode: modeString);
    });
    
    if (mounted) {
      state = state.copyWith(users: result);
    }
  }
  
  // ★ モード切り替えメソッド
  void setMode(PlayerFinderMode mode) {
    if (state.mode != mode) {
      state = state.copyWith(mode: mode);
      _search(); // モードが変わったら再検索
    }
  }

  Future<void> refresh() async {
    await _search(); 
  }
}