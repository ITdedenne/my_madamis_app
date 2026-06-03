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
import 'package:my_madamis_app/features/group_search/domain/entities/group_search_result.dart';

enum GroupSearchSortOrder {
  wantsToPlayDesc, possessedDesc, wantsToGmDesc, externalGmDesc, titleAsc,
}

class GroupSearchDisplayItem {
  final Scenario scenario;
  final List<String> ngUserNames;
  final List<String> wantsToPlayNames;
  final List<String> possessedNames;
  final List<String> wantsToGmNames;
  final bool isPlayerCountMatch; 
  final bool isOverCapacity;     

  GroupSearchDisplayItem({
    required this.scenario,
    this.ngUserNames = const [],
    this.wantsToPlayNames = const [],
    this.possessedNames = const [],
    this.wantsToGmNames = const [],
    this.isPlayerCountMatch = true,
    this.isOverCapacity = false,
  });

  bool get isPlayable => ngUserNames.isEmpty && !isOverCapacity;
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
  final bool hasInternalGm; 
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
    this.hasInternalGm = false, 
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
    bool? hasInternalGm, 
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
      hasInternalGm: hasInternalGm ?? this.hasInternalGm, 
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
  
  // 通信コスト削減のためのキャッシュ変数
  List<GroupSearchResult>? _lastLambdaResults; 
  Set<String>? _lastSearchedFriendIds;

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

  // ★内部GMのON/OFF時、すでに検索結果を持っていれば「ローカルで即座に再計算」する (AWSコスト0・UX最高)
  void toggleHasInternalGm(bool value) {
    state = state.copyWith(hasInternalGm: value);
    if (_lastLambdaResults != null && _lastSearchedFriendIds != null && _lastSearchedFriendIds!.length == state.selectedFriendIds.length && _lastSearchedFriendIds!.containsAll(state.selectedFriendIds)) {
      // メンバー構成が変わっていないなら、通信せずローカルで画面表示用アイテムを再生成
      _generateDisplayItems(_lastLambdaResults!);
    } else {
      clearResults();
    }
  }

  void clearResults() {
    _rawResults = [];
    _lastLambdaResults = null;
    _lastSearchedFriendIds = null;
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
      filtered = filtered.where((item) => item.isPlayerCountMatch);
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

  // Lambdaの結果を元に、現在の画面設定（GM有無など）に合わせて表示用アイテムを生成する処理を分離
  Future<void> _generateDisplayItems(List<GroupSearchResult> lambdaResults) async {
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

    final metaMap = {for (var r in lambdaResults) r.scenarioId: r};
    
    final totalPlayers = state.totalPlayers;
    // 内部GMがONの場合は必要PL人数を-1する
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
      
      final bool isCountMatch = targetPlCount == scenario.minPlayerCount && targetPlCount == scenario.maxPlayerCount;
      final bool isOver = targetPlCount > scenario.maxPlayerCount;

      if (state.hasInternalGm && scenario.gmRequirement == GmRequirement.none) {
        continue;
      }

      displayItems.add(GroupSearchDisplayItem(
        scenario: scenario,
        ngUserNames: meta != null ? toNames(meta.ngUserIds) : [],
        wantsToPlayNames: meta != null ? toNames(meta.wantsToPlayUserIds) : [],
        possessedNames: meta != null ? toNames(meta.possessedUserIds) : [],
        wantsToGmNames: meta != null ? toNames(meta.wantsToGmUserIds) : [],
        isPlayerCountMatch: isCountMatch,
        isOverCapacity: isOver,
      ));
    }

    _rawResults = displayItems;
    _applySort();
  }

  Future<void> search() async {
    if (state.selectedFriendIds.isEmpty) return;
    // ★連打対策 (すでに検索中なら弾く)
    if (state.isSearching) return; 

    // ★キャッシュ判定 (直前とまったく同じメンバーでの検索ならAWS通信をスキップして即表示)
    if (_lastSearchedFriendIds != null && 
        _lastSearchedFriendIds!.length == state.selectedFriendIds.length && 
        _lastSearchedFriendIds!.containsAll(state.selectedFriendIds)) {
      if (_lastLambdaResults != null) {
        await _generateDisplayItems(_lastLambdaResults!);
        return;
      }
    }

    state = state.copyWith(isSearching: true, errorMessage: null);

    try {
      final friendIds = state.selectedFriendIds.toList();
      
      // AWS (Lambda) への通信発生
      final results = await _findGroupScenariosUseCase(friendIds);
      
      // 成功したら結果と検索時のメンバー構成をキャッシュに保存
      _lastLambdaResults = results;
      _lastSearchedFriendIds = Set.from(state.selectedFriendIds);
      
      await _generateDisplayItems(results);
      state = state.copyWith(isSearching: false);
    } catch (e) {
      state = state.copyWith(isSearching: false, errorMessage: '$e');
    }
  }
}