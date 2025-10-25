// ファイルパス: lib/features/scenario_logbook/presentation/widgets/filter_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';
import 'package:my_madamis_app/providers.dart';

import '../pages/author_search_page.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  final SearchFilter currentFilter;
  final Function(SearchFilter newFilter) onApplyFilter;

  const FilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onApplyFilter,
  });

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late RangeValues _playerCountRange;
  late GmRequirement? _gmRequirement;
  late String? _authorName;

  @override
  void initState() {
    super.initState();
    _playerCountRange = widget.currentFilter.playerCountRange;
    _gmRequirement = widget.currentFilter.gmRequirement;
    _authorName = widget.currentFilter.authorName;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('絞り込み', style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          const SizedBox(height: 16),

          // --- プレイ人数 ---
          Text('プレイ人数: ${_playerCountRange.start.round()}人 〜 ${_playerCountRange.end.round()}人'),
          RangeSlider(
            values: _playerCountRange,
            min: 1,
            max: 15,
            divisions: 14,
            labels: RangeLabels(
              _playerCountRange.start.round().toString(),
              _playerCountRange.end.round().toString(),
            ),
            onChanged: (values) {
              setState(() {
                _playerCountRange = values;
              });
            },
          ),
          const SizedBox(height: 24),

          // --- GM要否 ---
          const Text('GM要否'),
          Wrap(
            spacing: 8.0,
            children: GmRequirement.values.map((req) {
              return ChoiceChip(
                label: Text(req.displayName),
                selected: _gmRequirement == req,
                onSelected: (selected) {
                  setState(() {
                    _gmRequirement = selected ? req : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // --- 作者名 ---
          const Text('作者'),
          ListTile(
            title: Text(_authorName ?? '指定なし'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              final allAuthors = await ref.read(scenarioRepositoryProvider).fetchAllAuthorNames();
              final selectedAuthor = await Navigator.of(context).push<String>(
                MaterialPageRoute(
                  builder: (_) => AuthorSearchPage(allAuthors: allAuthors),
                ),
              );
              if (selectedAuthor != null) {
                setState(() {
                  _authorName = selectedAuthor;
                });
              }
            },
          ),
          const SizedBox(height: 24),

          // --- ボタン ---
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApplyFilter(SearchFilter.initial());
                    Navigator.pop(context);
                  },
                  child: const Text('リセット'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final newFilter = SearchFilter(
                      playerCountRange: _playerCountRange,
                      gmRequirement: _gmRequirement,
                      authorName: _authorName,
                    );
                    widget.onApplyFilter(newFilter);
                    Navigator.pop(context);
                  },
                  child: const Text('適用'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// GmRequirement に表示名を追加するための extension
extension GmRequirementExtension on GmRequirement {
  String get displayName {
    switch (this) {
      case GmRequirement.required:
        return '必須';
      case GmRequirement.optional:
        return '任意';
      case GmRequirement.none:
        return '不要';
    }
  }
}