// ファイルパス: lib/features/scenario_logbook/presentation/pages/author_search_page.dart

import 'package:flutter/material.dart';

class AuthorSearchPage extends StatefulWidget {
  final List<String> allAuthors;
  const AuthorSearchPage({super.key, required this.allAuthors});

  @override
  State<AuthorSearchPage> createState() => _AuthorSearchPageState();
}

class _AuthorSearchPageState extends State<AuthorSearchPage> {
  late final List<String> _allAuthors;
  List<String> _filteredAuthors = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 重複を除いてソートしておく
    _allAuthors = widget.allAuthors.toSet().toList()..sort();
    _filteredAuthors = _allAuthors;

    _searchController.addListener(() {
      _filterAuthors();
    });
  }

  void _filterAuthors() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAuthors = _allAuthors
          .where((author) => author.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '作者名で検索...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: _filteredAuthors.length,
        itemBuilder: (context, index) {
          final author = _filteredAuthors[index];
          return ListTile(
            title: Text(author),
            onTap: () {
              // 選択した作者名を前の画面に返す
              Navigator.of(context).pop(author);
            },
          );
        },
      ),
    );
  }
}