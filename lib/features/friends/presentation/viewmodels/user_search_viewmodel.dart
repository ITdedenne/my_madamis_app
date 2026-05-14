// ファイルパス: lib/features/friends/presentation/viewmodels/user_search_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/core/constants/app_constants.dart'; 
import 'package:my_madamis_app/features/friends/domain/repositories/friends_repository.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'package:my_madamis_app/providers.dart';

import 'friends_viewmodel.dart';

class UserSearchState {
  final bool isLoading;
  final String? processingUserId;
  final List<User> searchResults;
  final String? errorMessage;
  final String? successMessage;

  UserSearchState({
    this.isLoading = false,
    this.processingUserId,
    this.searchResults = const [],
    this.errorMessage,
    this.successMessage,
  });

  UserSearchState copyWith({
    bool? isLoading,
    String? processingUserId,
    bool clearProcessing = false,
    List<User>? searchResults,
    String? errorMessage,
    String? successMessage,
  }) {
    return UserSearchState(
      isLoading: isLoading ?? this.isLoading,
      processingUserId: clearProcessing ? null : (processingUserId ?? this.processingUserId),
      searchResults: searchResults ?? this.searchResults,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

final userSearchViewModelProvider = StateNotifierProvider.autoDispose<UserSearchViewModel, UserSearchState>((ref) {
  return UserSearchViewModel(ref.watch(friendsRepositoryProvider), ref);
});

class UserSearchViewModel extends StateNotifier<UserSearchState> {
  final FriendsRepository _repository;
  final Ref _ref;

  UserSearchViewModel(this._repository, this._ref) : super(UserSearchState());

  Future<void> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    // 検索のバリデーション: 2文字以上
    if (trimmedQuery.length < 2) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '検索キーワードは2文字以上入力してください',
        searchResults: [],
      );
      return;
    }
    
    state = state.copyWith(isLoading: true, errorMessage: null, searchResults: []);
    try {
      final results = await _repository.searchUsers(trimmedQuery);
      state = state.copyWith(isLoading: false, searchResults: results);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> followUser(User user) async {
    state = state.copyWith(processingUserId: user.id, errorMessage: null, successMessage: null);
    
    try {
      final currentCount = await _repository.getFollowingCount();
      
      if (currentCount >= AppConstants.maxFriendsCount) {
        throw Exception('フレンズの上限（${AppConstants.maxFriendsCount}人）に達しているため、これ以上フォローできません。');
      }

      await _repository.followUser(user.id);
      
      // ★ 重要: ぐるぐる（回転）を止める前に、最新のフォローリストをロードする
      // これにより、UI側の isFollowing が true になってから回転が止まるため、表示が戻るフリッカーを防げます
      await _ref.read(friendsViewModelProvider.notifier).loadFollowingUsers();

      state = state.copyWith(
        clearProcessing: true, 
        successMessage: '${user.username}さんをフォローしました',
      );

    } catch (e) {
      state = state.copyWith(clearProcessing: true, errorMessage: e.toString());
    }
  }
  
  void clearMessages() {
    state = UserSearchState(
      isLoading: state.isLoading,
      processingUserId: state.processingUserId,
      searchResults: state.searchResults,
      errorMessage: null,
      successMessage: null,
    );
  }

  void clearSearch() {
    state = UserSearchState();
  }
}