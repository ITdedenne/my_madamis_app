// lib/features/scenario_logbook/presentation/widgets/filter_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  // Widgetのローカルステートとして、現在のProviderの値を初期値に持つ
  // これにより、ユーザーが「適用」を押すまでProviderを更新しない
  late int? _minPlayers;
  late int? _maxPlayers;
  // TODO: 他のフィルタ項目もローカルステートとして定義

  @override
  void initState() {
    super.initState();
    // 現在のProviderの値を読み込む
    final currentFilter = ref.read(searchFilterProvider);
    _minPlayers = currentFilter.minPlayerCount;
    _maxPlayers = currentFilter.maxPlayerCount;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('絞り込み', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          
          // 人数フィルタ (例)
          Text('プレイ人数', style: Theme.of(context).textTheme.titleMedium),
          Row(
            children: [
              Expanded(
                child: DropdownButton<int?>(
                  value: _minPlayers,
                  hint: const Text('下限'),
                  isExpanded: true,
                  items: [null, 1, 2, 3, 4, 5, 6, 7, 8]
                      .map((val) => DropdownMenuItem<int?>(
                            value: val,
                            child: Text(val == null ? '下限なし' : '$val 人'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _minPlayers = val;
                    });
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('〜'),
              ),
              Expanded(
                child: DropdownButton<int?>(
                  value: _maxPlayers,
                  hint: const Text('上限'),
                  isExpanded: true,
                  items: [null, 1, 2, 3, 4, 5, 6, 7, 8]
                      .map((val) => DropdownMenuItem<int?>(
                            value: val,
                            child: Text(val == null ? '上限なし' : '$val 人'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _maxPlayers = val;
                    });
                  },
                ),
              ),
            ],
          ),

          // TODO: 他のフィルタ項目 (GM要件、時間など) をここに追加

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // フィルタをリセット
                    ref.read(searchFilterProvider.notifier).state =
                        SearchFilterState();
                    Navigator.pop(context); // シートを閉じる
                  },
                  child: const Text('リセット'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // フィルタを適用
                    ref.read(searchFilterProvider.notifier).update(
                          (state) => state.copyWith(
                            minPlayerCount: _minPlayers,
                            maxPlayerCount: _maxPlayers,
                            // TODO: 他のフィルタ項目もここでセット
                          ),
                        );
                    Navigator.pop(context); // シートを閉じる
                  },
                  child: const Text('適用'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}