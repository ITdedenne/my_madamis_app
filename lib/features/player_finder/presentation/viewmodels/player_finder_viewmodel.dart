// ファイルパス: lib/features/player_finder/presentation/viewmodels/player_finder_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/player_finder/domain/usecases/find_unplayed_friends_usecase.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'package:my_madamis_app/providers.dart';

class PlayerFinderState {
  final bool isLoading;
  final List<User> unplayedFriends;
  final String? errorMessage;

  PlayerFinderState({
    this.isLoading = false,
    this.unplayedFriends = const [],
    this.errorMessage,
  });

  PlayerFinderState copyWith({
    bool? isLoading,
    List<User>? unplayedFriends,
    String? errorMessage,
  }) {
    return PlayerFinderState(
      isLoading: isLoading ?? this.isLoading,
      unplayedFriends: unplayedFriends ?? this.unplayedFriends,
      errorMessage: errorMessage, // nullを渡せばクリアされるようにする
    );
  }
}

final findUnplayedFriendsUseCaseProvider = Provider<FindUnplayedFriendsUseCase>((ref) {
  return FindUnplayedFriendsUseCase(ref.watch(playerFinderRepositoryProvider));
});

final playerFinderViewModelProvider = StateNotifierProvider.autoDispose<PlayerFinderViewModel, PlayerFinderState>((ref) {
  return PlayerFinderViewModel(ref.watch(findUnplayedFriendsUseCaseProvider));
});

class PlayerFinderViewModel extends StateNotifier<PlayerFinderState> {
  final FindUnplayedFriendsUseCase _useCase;

  PlayerFinderViewModel(this._useCase) : super(PlayerFinderState());

  Future<void> loadUnplayedFriends(String scenarioId) async {
    // ローディング開始、エラーメッセージはクリア
    // ★重要: errorMessageにnullを明示的に渡してリセットする
    state = PlayerFinderState(
      isLoading: true,
      unplayedFriends: state.unplayedFriends, // 前のリストを維持するか空にするかは要件次第（ここでは維持）
      errorMessage: null,
    );
    
    try {
      final friends = await _useCase(scenarioId);
      
      // 成功時: エラーなし、リスト更新
      state = state.copyWith(
        isLoading: false,
        unplayedFriends: friends,
      );
    } catch (e) {
      // ★改善: エラー発生時、errorMessageを設定
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'データの取得に失敗しました: ${e.toString()}',
        // エラー時はリストを空にするか、古いデータを残すか。ここでは誤解を防ぐため空にするか検討
        // 今回は「取得失敗」を表示するので、リスト更新は行わない（copyWithのデフォルト動作）
      );
    }
  }
}