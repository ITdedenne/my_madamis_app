// ファイルパス: lib/features/group_search/presentation/viewmodels/group_search_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/friends/domain/repositories/friends_repository.dart';
import 'package:my_madamis_app/features/group_search/domain/entities/group_search_result.dart'; // 前回の修正で作成したEntity
import 'package:my_madamis_app/features/group_search/domain/usecases/find_group_scenarios_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'package:my_madamis_app/providers.dart';

// ソート順定義
enum GroupSearchSortOrder {
  wantsToPlayDesc, // PL希望が多い順 (デフォルト)
  externalGmDesc,  // 外部GM候補がいる順
  titleAsc,        // 名前順
}

// 表示用アイテム
class GroupSearchDisplayItem {
  final Scenario scenario;
  final List<String> wantsToPlayNames;    // 選択メンバー内のPL希望者
  final List<String> externalHolderNames; // 選択外の所持・GM検討者

  GroupSearchDisplayItem({
    required this.scenario,
    this.wantsToPlayNames = const [],
    this.externalHolderNames = const [],
  });

  // ★ 追加: エラーの原因となっていたゲッター
  bool get hasWantsToPlay => wantsToPlayNames.isNotEmpty;
}

class GroupSearchState {
  final bool isLoadingFriends;
  final bool isSearching;
  final List<User> friends;
  final Set<String> selectedFriendIds;
  final String friendNameFilter;
  
  // 検索結果
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

  // 生データを保持しておき、ソート時に再利用する
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
      state = state.copyWith(isLoadingFriends: false, errorMessage: 'フレンズ読込エラー: $e');
    }
  }

  void updateFriendFilter(String query) {
    state = state.copyWith(friendNameFilter: query);
  }

  void toggleSelection(String userId) {
    final currentSelection = Set<String>.from(state.selectedFriendIds);
    if (currentSelection.contains(userId)) {
      currentSelection.remove(userId);
    } else {
      if (state.isSelectionLimitReached) return;
      currentSelection.add(userId);
    }
    state = state.copyWith(selectedFriendIds: currentSelection);
  }

  void clearResults() {
    state = GroupSearchState(
      friends: state.friends,
      selectedFriendIds: state.selectedFriendIds,
      // 検索前の状態に戻す
    );
    _rawResults = [];
  }

  void changeSortOrder(GroupSearchSortOrder order) {
    if (state.searchResults == null) return;
    state = state.copyWith(sortOrder: order);
    _applySort();
  }

  void _applySort() {
    final sorted = List<GroupSearchDisplayItem>.from(_rawResults);
    sorted.sort((a, b) {
      switch (state.sortOrder) {
        case GroupSearchSortOrder.wantsToPlayDesc:
          // PL希望数 > 外部GM > 名前
          int diff = b.wantsToPlayNames.length.compareTo(a.wantsToPlayNames.length);
          if (diff != 0) return diff;
          int gmDiff = b.externalHolderNames.length.compareTo(a.externalHolderNames.length);
          if (gmDiff != 0) return gmDiff;
          return a.scenario.title.compareTo(b.scenario.title);

        case GroupSearchSortOrder.externalGmDesc:
          // 外部GM > PL希望 > 名前
          int diff = b.externalHolderNames.length.compareTo(a.externalHolderNames.length);
          if (diff != 0) return diff;
          int plDiff = b.wantsToPlayNames.length.compareTo(a.wantsToPlayNames.length);
          if (plDiff != 0) return plDiff;
          return a.scenario.title.compareTo(b.scenario.title);

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
      
      // 1. Lambda呼び出し (NGリストとメタデータを取得)
      final response = await _findGroupScenariosUseCase(friendIds);
      
      // 2. ローカルの全シナリオマスタ取得
      final allScenarios = await _ref.read(allScenariosProvider.future);
      
      // 3. マッピング準備
      final friendMap = {for (var f in state.friends) f.id: f};
      final ngSet = response.ngScenarioIds.toSet();
      final metadataMap = {for (var m in response.metadata) m.scenarioId: m};
      
      final totalPlayers = friendIds.length + 1; // 自分 + フレンズ

      List<String> idsToNames(List<String> ids) {
        return ids.map((uid) => friendMap[uid]?.username ?? '不明').toList();
      }

      final List<GroupSearchDisplayItem> displayItems = [];

      // 4. フィルタリング & データ結合
      for (var scenario in allScenarios) {
        // NGリストに含まれていれば除外
        if (ngSet.contains(scenario.id)) continue;

        // 人数チェック
        if (scenario.maxPlayerCount < totalPlayers) continue;

        // メタデータがあれば結合、なければ空で作成
        final meta = metadataMap[scenario.id];
        
        displayItems.add(GroupSearchDisplayItem(
          scenario: scenario,
          wantsToPlayNames: meta != null ? idsToNames(meta.wantsToPlayUserIds) : [],
          externalHolderNames: meta != null ? idsToNames(meta.externalHolderUserIds) : [],
        ));
      }

      _rawResults = displayItems;
      _applySort(); // ソートしてState更新

      // ローディング解除は _applySort 内の copyWith で行われないためここで
      state = state.copyWith(isSearching: false);

    } catch (e) {
      state = state.copyWith(isSearching: false, errorMessage: '検索中にエラーが発生しました: $e');
    }
  }
}