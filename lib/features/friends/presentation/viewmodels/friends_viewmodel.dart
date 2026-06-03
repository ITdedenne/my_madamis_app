// ファイルパス: lib/features/friends/presentation/viewmodels/friends_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/friends/domain/repositories/friends_repository.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'package:my_madamis_app/providers.dart';

class FriendsState {
  final bool isLoading;
  final List<User> followingUsers;
  final String? errorMessage;
  final String? successMessage;

  FriendsState({
    this.isLoading = false,
    this.followingUsers = const [],
    this.errorMessage,
    this.successMessage,
  });

  FriendsState copyWith({
    bool? isLoading,
    List<User>? followingUsers,
    String? errorMessage,
    String? successMessage,
  }) {
    return FriendsState(
      isLoading: isLoading ?? this.isLoading,
      followingUsers: followingUsers ?? this.followingUsers,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

final friendsViewModelProvider = StateNotifierProvider<FriendsViewModel, FriendsState>((ref) {
  return FriendsViewModel(ref.watch(friendsRepositoryProvider));
});

class FriendsViewModel extends StateNotifier<FriendsState> {
  final FriendsRepository _repository;

  FriendsViewModel(this._repository) : super(FriendsState()) {
    loadFollowingUsers();
  }

  Future<void> loadFollowingUsers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final users = await _repository.fetchFollowingUsers();
      state = state.copyWith(isLoading: false, followingUsers: users);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> unfollowUser(String userId) async {

    state = FriendsState(
      isLoading: state.isLoading,
      followingUsers: state.followingUsers,
    );

    try {
      await _repository.unfollowUser(userId);
      
      final updatedList = state.followingUsers.where((u) => u.id != userId).toList();
      
      state = state.copyWith(
        followingUsers: updatedList,
        successMessage: '解除しました',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'フォロー解除に失敗しました: $e');
    }
  }

  void clearMessages() {
    state = FriendsState(
      isLoading: state.isLoading,
      followingUsers: state.followingUsers,
      errorMessage: null,
      successMessage: null,
    );
  }
}