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
      errorMessage: errorMessage ?? this.errorMessage,
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
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final friends = await _useCase(scenarioId);
      state = state.copyWith(isLoading: false, unplayedFriends: friends);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}