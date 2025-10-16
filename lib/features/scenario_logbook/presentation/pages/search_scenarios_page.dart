// ファイルパス: lib/features/scenario_logbook/presentation/pages/search_scenarios_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/scenario_list_item.dart';

// ▼▼▼ ConsumerWidget から ConsumerStatefulWidget に変更 ▼▼▼
// (ScrollController と TextEditingController を使うため)
class SearchScenariosPage extends ConsumerStatefulWidget {
  const SearchScenariosPage({super.key});

  @override
  ConsumerState<SearchScenariosPage> createState() => _SearchScenariosPageState();
}

class _SearchScenariosPageState extends ConsumerState<SearchScenariosPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // スクロールを監視し、一番下まで来たら次のページを読み込む
    _scrollController.addListener(() {
      if (_scrollController.position.maxScrollExtent == _scrollController.position.pixels) {
        final searchTerm = _searchController.text;
        ref.read(searchScenariosViewModelProvider.notifier).fetchNextPage(searchTerm: searchTerm);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchScenariosViewModelProvider);
    final notifier = ref.read(searchScenariosViewModelProvider.notifier);

    return Scaffold(
      // AppBarをScaffoldの外に持つことで、タブ切り替え時にAppBarが再描画されない
      // 今回は SearchScenariosPage の中にAppBarを移動
      appBar: AppBar(
        // titleに検索用のTextFieldを配置
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'シナリオ名で検索...',
            border: InputBorder.none,
            icon: Icon(Icons.search),
          ),
          onChanged: notifier.onSearchTermChanged,
        ),
        actions: [
          // TODO: 絞り込み機能を実装
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () { /* 絞り込みUIを表示 */ },
          ),
        ],
      ),
      body: _buildBody(state, notifier),
    );
  }

  Widget _buildBody(SearchScenariosState state, SearchScenariosViewModel notifier) {
    // 初期ロード中
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // エラー発生時
    if (state.errorMessage != null) {
      return Center(child: Text('エラー: ${state.errorMessage}'));
    }

    // 検索結果が0件の場合
    if (state.scenarios.isEmpty) {
      return const Center(child: Text('シナリオが見つかりません。'));
    }

    // シナリオ一覧
    return ListView.builder(
      controller: _scrollController,
      // +1 は、追加読み込み中のインジケーター表示分
      itemCount: state.scenarios.length + (state.isFetchingNextPage ? 1 : 0),
      itemBuilder: (context, index) {
        // リストの最後で、まだ次のページがある場合 -> ローディングインジケーターを表示
        if (index == state.scenarios.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final scenario = state.scenarios[index];
        return ScenarioListItem(
          scenario: scenario,
          status: state.myScenarioStatuses[scenario.id],
          onStatusChanged: (newStatus) {
            notifier.updateStatus(scenario.id, newStatus);
          },
        );
      },
    );
  }
}