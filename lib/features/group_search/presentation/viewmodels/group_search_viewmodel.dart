// ファイルパス: lib/features/group_search/presentation/viewmodels/group_search_viewmodel.dart

import 'package:amplify_flutter/amplify_flutter.dart'; // ★ 追加: 自分のID取得用
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart'; // ★ 追加: 自分の名前取得用
import 'package:my_madamis_app/features/friends/domain/repositories/friends_repository.dart';
import 'package:my_madamis_app/features/group_search/domain/usecases/find_group_scenarios_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'package:my_madamis_app/providers.dart';

// ソート順定義
enum GroupSearchSortOrder {
  wantsToPlayDesc, // PL希望順
  possessedDesc,   // 所持順
  wantsToGmDesc,   // 購入検討順
  externalGmDesc,  // GM候補順 (所持+検討)
  titleAsc,        // 名前順
}

// 表示用アイテム
class GroupSearchDisplayItem {
  final Scenario scenario;
  final List<String> ngUserNames;
  final List<String> wantsToPlayNames;
  final List<String> possessedNames;
  final List<String> wantsToGmNames;

  GroupSearchDisplayItem({
    required this.scenario,
    this.ngUserNames = const [],
    this.wantsToPlayNames = const [],
    this.possessedNames = const [],
    this.wantsToGmNames = const [],
  });

  bool get isPlayable => ngUserNames.isEmpty;
  bool get hasWantsToPlay => wantsToPlayNames.isNotEmpty;
  int get totalGmCandidates => possessedNames.length + wantsToGmNames.length;
}

class GroupSearchState {
  final bool isLoadingFriends;
  final bool isSearching;
  final List<User> friends;
  final Set<String> selectedFriendIds;
  final String friendNameFilter;
  final List<GroupSearchDisplayItem>? searchResults;
  final GroupSearchSortOrder sortOrder;
  final String? errorMessage;

  GroupSearchState({
    this.isLoadingFriends = false,
    this.isSearching = false,
    this.friends = const [],
    this.selectedFriendIds = const {},
    this.friendNameFilter = '',
    this.searchResults,
    this.sortOrder = GroupSearchSortOrder.wantsToPlayDesc,
    this.errorMessage,
  });

  GroupSearchState copyWith({
    bool? isLoadingFriends,
    bool? isSearching,
    List<User>? friends,
    Set<String>? selectedFriendIds,
    String? friendNameFilter,
    List<GroupSearchDisplayItem>? searchResults,
    GroupSearchSortOrder? sortOrder,
    String? errorMessage,
  }) {
    return GroupSearchState(
      isLoadingFriends: isLoadingFriends ?? this.isLoadingFriends,
      isSearching: isSearching ?? this.isSearching,
      friends: friends ?? this.friends,
      selectedFriendIds: selectedFriendIds ?? this.selectedFriendIds,
      friendNameFilter: friendNameFilter ?? this.friendNameFilter,
      searchResults: searchResults ?? this.searchResults,
      sortOrder: sortOrder ?? this.sortOrder,
      errorMessage: errorMessage,
    );
  }

  List<User> get filteredFriends {
    if (friendNameFilter.isEmpty) return friends;
    final term = friendNameFilter.toLowerCase();
    return friends.where((f) => 
      f.username.toLowerCase().contains(term) || f.publicUserId.contains(term)
    ).toList();
  }
  
  bool get isSelectionLimitReached => selectedFriendIds.length >= 8;
}

final groupSearchViewModelProvider = StateNotifierProvider.autoDispose<GroupSearchViewModel, GroupSearchState>((ref) {
  return GroupSearchViewModel(
    ref.watch(friendsRepositoryProvider),
    FindGroupScenariosUseCase(ref.watch(groupSearchRepositoryProvider)),
    ref,
  );
});

class GroupSearchViewModel extends StateNotifier<GroupSearchState> {
  final FriendsRepository _friendsRepository;
  final FindGroupScenariosUseCase _findGroupScenariosUseCase;
  final Ref _ref;
  List<GroupSearchDisplayItem> _rawResults = [];

  GroupSearchViewModel(this._friendsRepository, this._findGroupScenariosUseCase, this._ref) : super(GroupSearchState()) {
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    state = state.copyWith(isLoadingFriends: true);
    try {
      final friends = await _friendsRepository.fetchFollowingUsers();
      state = state.copyWith(isLoadingFriends: false, friends: friends);
    } catch (e) {
      state = state.copyWith(isLoadingFriends: false, errorMessage: '$e');
    }
  }

  void updateFriendFilter(String query) => state = state.copyWith(friendNameFilter: query);

  void toggleSelection(String userId) {
    final current = Set<String>.from(state.selectedFriendIds);
    if (current.contains(userId)) {
      current.remove(userId);
    } else if (!state.isSelectionLimitReached) {
      current.add(userId);
    }
    state = state.copyWith(selectedFriendIds: current);
  }

  void clearResults() {
    _rawResults = [];
    state = state.copyWith(searchResults: null);
  }

  void changeSortOrder(GroupSearchSortOrder order) {
    state = state.copyWith(sortOrder: order);
    _applySort();
  }

  void _applySort() {
    final sorted = List<GroupSearchDisplayItem>.from(_rawResults);
    sorted.sort((a, b) {
      // 1. 遊べるかどうか
      if (a.isPlayable != b.isPlayable) return a.isPlayable ? -1 : 1;

      // 2. ソート順
      switch (state.sortOrder) {
        case GroupSearchSortOrder.wantsToPlayDesc:
          int diff = b.wantsToPlayNames.length.compareTo(a.wantsToPlayNames.length);
          if (diff != 0) return diff;
          int gmDiff = b.totalGmCandidates.compareTo(a.totalGmCandidates);
          if (gmDiff != 0) return gmDiff;
          break;

        case GroupSearchSortOrder.possessedDesc:
          int diff = b.possessedNames.length.compareTo(a.possessedNames.length);
          if (diff != 0) return diff;
          break;

        case GroupSearchSortOrder.wantsToGmDesc:
          int diff = b.wantsToGmNames.length.compareTo(a.wantsToGmNames.length);
          if (diff != 0) return diff;
          break;

        case GroupSearchSortOrder.externalGmDesc:
          int diff = b.totalGmCandidates.compareTo(a.totalGmCandidates);
          if (diff != 0) return diff;
          break;

        case GroupSearchSortOrder.titleAsc:
          return a.scenario.title.compareTo(b.scenario.title);
      }
      // サブソート: 名前
      return a.scenario.title.compareTo(b.scenario.title);
    });
    state = state.copyWith(searchResults: sorted);
  }

  Future<void> search() async {
    if (state.selectedFriendIds.isEmpty) return;
    state = state.copyWith(isSearching: true, errorMessage: null);

    try {
      final friendIds = state.selectedFriendIds.toList();
      
      // 1. Lambda呼び出し
      final results = await _findGroupScenariosUseCase(friendIds);
      
      // 2. 全シナリオマスタ
      final allScenarios = await _ref.read(allScenariosProvider.future);
      
      // 3. マッピング準備
      final friendMap = {for (var f in state.friends) f.id: f};
      
      // ★ 改善: 自分のIDと名前を取得して、「不明」になるのを防ぐ
      String myId = '';
      String myName = '自分';
      try {
        final user = await Amplify.Auth.getCurrentUser();
        myId = user.userId;
        // AuthStateから現在のユーザー名を取得
        final authState = _ref.read(authStateNotifierProvider);
        if (authState.username != null) {
           myName = authState.username!;
        }
      } catch (_) {
        // 取得できない場合はデフォルトの'自分'を使用
      }

      final metaMap = {for (var r in results) r.scenarioId: r};
      final totalPlayers = friendIds.length + 1;

      // ヘルパー: ID -> 名前
      List<String> toNames(List<String> ids) {
        return ids.map((uid) {
          if (uid == myId) return myName; // ★ 自分自身の場合は名前を返す
          return friendMap[uid]?.username ?? '不明'; // 見つからない場合は不明
        }).toList();
      }

      final List<GroupSearchDisplayItem> displayItems = [];

      for (var scenario in allScenarios) {
        final meta = metaMap[scenario.id];
        
        if (scenario.maxPlayerCount < totalPlayers) continue;

        displayItems.add(GroupSearchDisplayItem(
          scenario: scenario,
          ngUserNames: meta != null ? toNames(meta.ngUserIds) : [],
          wantsToPlayNames: meta != null ? toNames(meta.wantsToPlayUserIds) : [],
          possessedNames: meta != null ? toNames(meta.possessedUserIds) : [],
          wantsToGmNames: meta != null ? toNames(meta.wantsToGmUserIds) : [],
        ));
      }

      _rawResults = displayItems;
      _applySort();
      state = state.copyWith(isSearching: false);

    } catch (e) {
      state = state.copyWith(isSearching: false, errorMessage: '$e');
    }
  }
}