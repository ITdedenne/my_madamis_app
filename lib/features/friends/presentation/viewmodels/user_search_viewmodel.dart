// ファイルパス: lib/features/friends/presentation/viewmodels/user_search_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/core/constants/app_constants.dart'; 
import 'package:my_madamis_app/features/friends/domain/repositories/friends_repository.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'package:my_madamis_app/providers.dart';

import 'friends_viewmodel.dart';

class UserSearchState {
  final bool isLoading;
  final bool isProcessing;
  final List<User> searchResults;
  final String? errorMessage;
  final String? successMessage;

  UserSearchState({
    this.isLoading = false,
    this.isProcessing = false,
    this.searchResults = const [],
    this.errorMessage,
    this.successMessage,
  });

  UserSearchState copyWith({
    bool? isLoading,
    bool? isProcessing,
    List<User>? searchResults,
    String? errorMessage,
    String? successMessage,
  }) {
    return UserSearchState(
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      searchResults: searchResults ?? this.searchResults,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// autoDisposeにより、画面破棄時に状態もリセット
final userSearchViewModelProvider = StateNotifierProvider.autoDispose<UserSearchViewModel, UserSearchState>((ref) {
  return UserSearchViewModel(ref.watch(friendsRepositoryProvider), ref);
});

class UserSearchViewModel extends StateNotifier<UserSearchState> {
  final FriendsRepository _repository;
  final Ref _ref;

  UserSearchViewModel(this._repository, this._ref) : super(UserSearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    
    state = state.copyWith(isLoading: true, errorMessage: null, searchResults: []);
    try {
      final results = await _repository.searchUsers(query);
      state = state.copyWith(isLoading: false, searchResults: results);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> followUser(User user) async {
    state = state.copyWith(isProcessing: true, errorMessage: null, successMessage: null);
    
    try {
      // 上限チェック
      final currentCount = await _repository.getFollowingCount();
      
      // ★ 修正: マジックナンバー(100)を定数に変更
      if (currentCount >= AppConstants.maxFriendsCount) {
        throw Exception('フレンズの上限（${AppConstants.maxFriendsCount}人）に達しているため、これ以上フォローできません。');
      }

      await _repository.followUser(user.id);
      
      state = state.copyWith(
        isProcessing: false, 
        successMessage: '${user.username}さんをフォローしました',
      );
      
      // フレンズ一覧を更新して、検索画面側のボタン状態（フォロー済）にも即座に反映させる
      await _ref.read(friendsViewModelProvider.notifier).loadFollowingUsers();

    } catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: e.toString());
    }
  }
  
  void clearMessages() {
    state = UserSearchState(
      isLoading: state.isLoading,
      isProcessing: state.isProcessing,
      searchResults: state.searchResults,
      errorMessage: null,
      successMessage: null,
    );
  }

  void clearSearch() {
    state = UserSearchState();
  }
}