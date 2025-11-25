// ファイルパス: lib/features/group_search/presentation/viewmodels/group_search_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/friends/domain/repositories/friends_repository.dart';
import 'package:my_madamis_app/features/group_search/domain/usecases/find_group_scenarios_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'package:my_madamis_app/providers.dart';

// --- UI表示用のラッパークラス ---
class GroupSearchDisplayItem {
  final Scenario scenario;
  // IDではなく「表示名」のリストを保持する
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
  
  // NGユーザーがいない＝全員遊べる
  bool get isPlayable => ngUserNames.isEmpty;
  // PL希望者がいるか
  bool get hasWantsToPlay => wantsToPlayNames.isNotEmpty;
}

// --- State ---
class GroupSearchState {
  final bool isLoadingFriends;
  final bool isSearching;
  final List<User> friends;
  final Set<String> selectedFriendIds;
  final String friendNameFilter;
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

  List<User> get filteredFriends {
    if (friendNameFilter.isEmpty) return friends;
    return friends.where((f) => 
      f.username.contains(friendNameFilter) || f.publicUserId.contains(friendNameFilter)
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
      final matchedResults = await _findGroupScenariosUseCase(friendIds);
      final allScenarios = await _ref.read(allScenariosProvider.future);
      
      // マッピング用: ID -> User
      final friendMap = {for (var f in state.friends) f.id: f};
      final resultMap = { for (var r in matchedResults) r.scenarioId: r };
      
      final totalPlayers = friendIds.length + 1; 

      // ヘルパー関数: IDリストを名前リストに変換
      List<String> idsToNames(List<String> ids) {
        return ids.map((uid) => friendMap[uid]?.username ?? '不明').toList();
      }

      final List<GroupSearchDisplayItem> displayItems = [];

      for (var scenario in allScenarios) {
        if (resultMap.containsKey(scenario.id)) {
          final result = resultMap[scenario.id]!;
          
          // 人数チェック
          // ※「惜しい」シナリオであっても、人数が足りていれば表示対象とする
          if (scenario.maxPlayerCount >= totalPlayers) {
             displayItems.add(GroupSearchDisplayItem(
              scenario: scenario,
              ngUserNames: idsToNames(result.ngUserIds),
              wantsToPlayNames: idsToNames(result.wantsToPlayUserIds),
              possessedNames: idsToNames(result.possessedUserIds),
              wantsToGmNames: idsToNames(result.wantsToGmUserIds),
            ));
          }
        }
      }

      // ソート: 遊べる > PL希望数 > NG少ない
      displayItems.sort((a, b) {
        if (a.isPlayable != b.isPlayable) return a.isPlayable ? -1 : 1;
        
        if (a.isPlayable) {
          // PL希望者が多い順
          int wantsDiff = b.wantsToPlayNames.length.compareTo(a.wantsToPlayNames.length);
          if (wantsDiff != 0) return wantsDiff;
          return a.scenario.title.compareTo(b.scenario.title);
        } else {
          // 惜しい順（NGが少ない順）
          int ngDiff = a.ngUserNames.length.compareTo(b.ngUserNames.length);
          if (ngDiff != 0) return ngDiff;
          return a.scenario.title.compareTo(b.scenario.title);
        }
      });

      state = state.copyWith(isSearching: false, searchResults: displayItems);

    } catch (e) {
      state = state.copyWith(isSearching: false, errorMessage: '検索中にエラーが発生しました: $e');
    }
  }
}