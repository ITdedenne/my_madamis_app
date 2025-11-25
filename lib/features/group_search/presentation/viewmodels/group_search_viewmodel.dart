// ファイルパス: lib/features/group_search/presentation/viewmodels/group_search_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/friends/domain/repositories/friends_repository.dart';
import 'package:my_madamis_app/features/group_search/domain/usecases/find_group_scenarios_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart'; // allScenariosProvider
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'package:my_madamis_app/providers.dart';

// --- UI表示用のラッパークラス (定義を追加) ---
class GroupSearchDisplayItem {
  final Scenario scenario;
  final bool isFriendWantsToPlay;

  GroupSearchDisplayItem({
    required this.scenario,
    required this.isFriendWantsToPlay,
  });
}

// --- State ---
class GroupSearchState {
  final bool isLoadingFriends;
  final bool isSearching;
  final List<User> friends;
  final Set<String> selectedFriendIds;
  final String friendNameFilter; // ローカル検索用
  final List<GroupSearchDisplayItem>? searchResults;
  final String? errorMessage;

  GroupSearchState({
    this.isLoadingFriends = false,
    this.isSearching = false,
    this.friends = const [],
    this.selectedFriendIds = const {},
    this.friendNameFilter = '',
    this.searchResults,
    this.errorMessage,
  });

  GroupSearchState copyWith({
    bool? isLoadingFriends,
    bool? isSearching,
    List<User>? friends,
    Set<String>? selectedFriendIds,
    String? friendNameFilter,
    List<GroupSearchDisplayItem>? searchResults,
    String? errorMessage,
  }) {
    return GroupSearchState(
      isLoadingFriends: isLoadingFriends ?? this.isLoadingFriends,
      isSearching: isSearching ?? this.isSearching,
      friends: friends ?? this.friends,
      selectedFriendIds: selectedFriendIds ?? this.selectedFriendIds,
      friendNameFilter: friendNameFilter ?? this.friendNameFilter,
      searchResults: searchResults ?? this.searchResults,
      errorMessage: errorMessage,
    );
  }

  // フレンズフィルタリング (3.4.7 / 4.5.1)
  List<User> get filteredFriends {
    if (friendNameFilter.isEmpty) return friends;
    return friends.where((f) => 
      f.username.contains(friendNameFilter) || f.publicUserId.contains(friendNameFilter)
    ).toList();
  }

  // 選択上限 (最大8人)
  bool get isSelectionLimitReached => selectedFriendIds.length >= 8;
}

// --- Provider ---
final groupSearchViewModelProvider = StateNotifierProvider.autoDispose<GroupSearchViewModel, GroupSearchState>((ref) {
  return GroupSearchViewModel(
    ref.watch(friendsRepositoryProvider),
    FindGroupScenariosUseCase(ref.watch(groupSearchRepositoryProvider)),
    ref,
  );
});

// --- ViewModel ---
class GroupSearchViewModel extends StateNotifier<GroupSearchState> {
  final FriendsRepository _friendsRepository;
  final FindGroupScenariosUseCase _findGroupScenariosUseCase;
  final Ref _ref;

  GroupSearchViewModel(this._friendsRepository, this._findGroupScenariosUseCase, this._ref) : super(GroupSearchState()) {
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    state = state.copyWith(isLoadingFriends: true);
    try {
      final friends = await _friendsRepository.fetchFollowingUsers();
      state = state.copyWith(isLoadingFriends: false, friends: friends);
    } catch (e) {
      state = state.copyWith(isLoadingFriends: false, errorMessage: 'フレンズの読み込みに失敗しました: $e');
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

  Future<void> search() async {
    if (state.selectedFriendIds.isEmpty) return;

    state = state.copyWith(isSearching: true, errorMessage: null);
    try {
      final friendIds = state.selectedFriendIds.toList();
      
      // 1. Lambda呼び出し
      final matchedResults = await _findGroupScenariosUseCase(friendIds);
      
      // 2. クライアントキャッシュ取得
      final allScenarios = await _ref.read(allScenariosProvider.future);
      
      final matchMap = { for (var r in matchedResults) r.scenarioId: r.isFriendWantsToPlay };
      final totalPlayers = friendIds.length + 1; // 自分 + フレンズ

      final List<GroupSearchDisplayItem> displayItems = [];

      for (var scenario in allScenarios) {
        if (matchMap.containsKey(scenario.id)) {
          // ★ v2.15 新規: 人数チェック (3.5.1)
          // シナリオの最大プレイ人数が参加人数以上でなければならない
          if (scenario.maxPlayerCount >= totalPlayers) {
             displayItems.add(GroupSearchDisplayItem(
              scenario: scenario,
              isFriendWantsToPlay: matchMap[scenario.id]!,
            ));
          }
        }
      }

      // ソート: PL希望 > タイトル
      displayItems.sort((a, b) {
        if (a.isFriendWantsToPlay != b.isFriendWantsToPlay) {
          return a.isFriendWantsToPlay ? -1 : 1;
        }
        return a.scenario.title.compareTo(b.scenario.title);
      });

      state = state.copyWith(isSearching: false, searchResults: displayItems);

    } catch (e) {
      state = state.copyWith(isSearching: false, errorMessage: '検索中にエラーが発生しました: $e');
    }
  }
}