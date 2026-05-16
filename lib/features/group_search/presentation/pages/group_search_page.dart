// ファイルパス: lib/features/group_search/presentation/pages/group_search_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/group_search/presentation/widgets/group_search_condition_area.dart';
import 'package:my_madamis_app/features/group_search/presentation/widgets/group_search_results_area.dart';

class GroupSearchPage extends ConsumerWidget {
  const GroupSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('グループ検索'),
      ),
      body: const Column(
        children: [
          GroupSearchConditionArea(),
          GroupSearchResultsArea(),
        ],
      ),
    );
  }
}