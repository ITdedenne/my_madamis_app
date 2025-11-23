// ファイルパス: lib/features/group_search/presentation/viewmodels/group_search_settings_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/friends/domain/repositories/friends_repository.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'package:my_madamis_app/providers.dart';

class GroupSearchSettingsState {
  final bool isLoading;
  final List<User> friends;
  final Set<String> selectedFriendIds;
  final String? errorMessage;

  GroupSearchSettingsState({
    this.isLoading = false,
    this.friends = const [],
    this.selectedFriendIds = const {},
    this.errorMessage,
  });

  GroupSearchSettingsState copyWith({
    bool? isLoading,
    List<User>? friends,
    Set<String>? selectedFriendIds,
    String? errorMessage,
  }) {
    return GroupSearchSettingsState(
      isLoading: isLoading ?? this.isLoading,
      friends: friends ?? this.friends,
      selectedFriendIds: selectedFriendIds ?? this.selectedFriendIds,
      errorMessage: errorMessage,
    );
  }
  
  // 要件 4.5.1: 最大8人
  bool get isSelectionLimitReached => selectedFriendIds.length >= 8;
}

final groupSearchSettingsViewModelProvider = 
    StateNotifierProvider.autoDispose<GroupSearchSettingsViewModel, GroupSearchSettingsState>((ref) {
  return GroupSearchSettingsViewModel(ref.watch(friendsRepositoryProvider));
});

class GroupSearchSettingsViewModel extends StateNotifier<GroupSearchSettingsState> {
  final FriendsRepository _friendsRepository;

  GroupSearchSettingsViewModel(this._friendsRepository) : super(GroupSearchSettingsState()) {
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    state = state.copyWith(isLoading: true);
    try {
      // 全フレンズを取得 (ページネーション対応のリポジトリメソッドを使用)
      final friends = await _friendsRepository.fetchFollowingUsers();
      state = state.copyWith(isLoading: false, friends: friends);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'フレンズの読み込みに失敗しました: $e');
    }
  }

  void toggleSelection(String userId) {
    final currentSelection = Set<String>.from(state.selectedFriendIds);
    
    if (currentSelection.contains(userId)) {
      currentSelection.remove(userId);
    } else {
      if (state.isSelectionLimitReached) {
        // 上限到達時は追加しない（UI側でメッセージ表示等の制御を推奨）
        return;
      }
      currentSelection.add(userId);
    }
    
    state = state.copyWith(selectedFriendIds: currentSelection);
  }
}