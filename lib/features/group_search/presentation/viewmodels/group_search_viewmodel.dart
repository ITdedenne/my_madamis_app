// ファイルパス: lib/features/group_search/presentation/viewmodels/group_search_viewmodel.dart

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/friends/domain/repositories/friends_repository.dart';
import 'package:my_madamis_app/features/group_search/domain/usecases/find_group_scenarios_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'package:my_madamis_app/providers.dart';

enum GroupSearchSortOrder {
  wantsToPlayDesc, possessedDesc, wantsToGmDesc, externalGmDesc, titleAsc,
}

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
  int get totalGmCandidates => possessedNames.length + wantsToGmNames.length;
  
  bool get hasWantsToPlay => wantsToPlayNames.isNotEmpty;
  List<String> get externalHolderNames => [...possessedNames, ...wantsToGmNames];
}

class GroupSearchState {
  final bool isLoadingFriends;
  final bool isSearching;
  final List<User> friends;
  final Set<String> selectedFriendIds;
  final String friendNameFilter;
  final List<GroupSearchDisplayItem>? searchResults;
  final GroupSearchSortOrder sortOrder;
  final bool exactPlayerMatch; 
  final bool hasInternalGm; // ★追加: 内部GMの有無
  final String? errorMessage;

  GroupSearchState({
    this.isLoadingFriends = false,
    this.isSearching = false,
    this.friends = const [],
    this.selectedFriendIds = const {},
    this.friendNameFilter = '',
    this.searchResults,
    this.sortOrder = GroupSearchSortOrder.wantsToPlayDesc,
    this.exactPlayerMatch = false,
    this.hasInternalGm = false, // ★追加
    this.errorMessage,
  });

  int get totalPlayers => selectedFriendIds.length + 1;

  GroupSearchState copyWith({
    bool? isLoadingFriends,
    bool? isSearching,
    List<User>? friends,
    Set<String>? selectedFriendIds,
    String? friendNameFilter,
    List<GroupSearchDisplayItem>? searchResults,
    GroupSearchSortOrder? sortOrder,
    bool? exactPlayerMatch,
    bool? hasInternalGm, // ★追加
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
      exactPlayerMatch: exactPlayerMatch ?? this.exactPlayerMatch,
      hasInternalGm: hasInternalGm ?? this.hasInternalGm, // ★追加
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

  // ★追加: 内部GMのON/OFFを切り替える
  void toggleHasInternalGm(bool value) {
    state = state.copyWith(hasInternalGm: value);
    clearResults(); // 条件が変わったので結果をクリアして再検索を促す
  }

  void clearResults() {
    _rawResults = [];
    state = state.copyWith(searchResults: null);
  }

  void changeSortOrder(GroupSearchSortOrder order) {
    state = state.copyWith(sortOrder: order);
    _applySort();
  }

  void toggleExactPlayerMatch(bool value) {
    state = state.copyWith(exactPlayerMatch: value);
    _applySort();
  }

  void _applySort() {
    Iterable<GroupSearchDisplayItem> filtered = _rawResults;
    
    if (state.exactPlayerMatch) {
      // ★修正: 内部GMの有無を考慮して「ぴったり」の人数を計算
      final targetPlCount = state.hasInternalGm ? state.totalPlayers - 1 : state.totalPlayers;
      filtered = filtered.where((item) => item.scenario.maxPlayerCount == targetPlCount);
    }

    final sorted = filtered.toList();
    sorted.sort((a, b) {
      if (a.isPlayable != b.isPlayable) return a.isPlayable ? -1 : 1;
      switch (state.sortOrder) {
        case GroupSearchSortOrder.wantsToPlayDesc:
          int diff = b.wantsToPlayNames.length.compareTo(a.wantsToPlayNames.length);
          if (diff != 0) return diff;
          return b.totalGmCandidates.compareTo(a.totalGmCandidates);
        case GroupSearchSortOrder.possessedDesc:
          return b.possessedNames.length.compareTo(a.possessedNames.length);
        case GroupSearchSortOrder.wantsToGmDesc:
          return b.wantsToGmNames.length.compareTo(a.wantsToGmNames.length);
        case GroupSearchSortOrder.externalGmDesc:
          return b.totalGmCandidates.compareTo(a.totalGmCandidates);
        case GroupSearchSortOrder.titleAsc:
          return a.scenario.title.compareTo(b.scenario.title);
      }
    });
    state = state.copyWith(searchResults: sorted);
  }

  Future<void> search() async {
    if (state.selectedFriendIds.isEmpty) return;
    state = state.copyWith(isSearching: true, errorMessage: null);

    try {
      final friendIds = state.selectedFriendIds.toList();
      final results = await _findGroupScenariosUseCase(friendIds);
      final allScenarios = await _ref.read(allScenariosProvider.future);
      final friendMap = {for (var f in state.friends) f.id: f};
      
      String myId = '';
      String myName = '自分';
      try {
        final user = await Amplify.Auth.getCurrentUser();
        myId = user.userId;
        final authState = _ref.read(authStateNotifierProvider);
        if (authState.username != null) myName = authState.username!;
      } catch (_) {}

      final metaMap = {for (var r in results) r.scenarioId: r};
      
      // ★修正: 内部GMの有無を考慮してターゲットとなるPL人数を算出
      final totalPlayers = state.totalPlayers;
      final targetPlCount = state.hasInternalGm ? totalPlayers - 1 : totalPlayers;

      List<String> toNames(List<String> ids) {
        return ids.map((uid) {
          if (uid == myId) return myName;
          return friendMap[uid]?.username ?? '不明';
        }).toList();
      }

      final List<GroupSearchDisplayItem> displayItems = [];
      for (var scenario in allScenarios) {
        final meta = metaMap[scenario.id];
        
        // ★改善: minとmaxの両方を見て、ターゲットのPL人数が遊べる範囲に収まっているか厳密に判定
        if (targetPlCount < scenario.minPlayerCount || targetPlCount > scenario.maxPlayerCount) {
          continue;
        }

        // ★改善: 内部GMがいる場合、GM不要(レス専用)のシナリオはGMが暇になってしまうため除外
        if (state.hasInternalGm && scenario.gmRequirement == GmRequirement.none) {
          continue;
        }

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