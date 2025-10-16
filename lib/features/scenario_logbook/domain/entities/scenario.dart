// ファイルパス: lib/features/scenario_logbook/domain/entities/scenario.dart

import 'package:equatable/equatable.dart';

// GMの要否を表すEnum
enum GmRequirement { required, optional, none }

class Scenario extends Equatable {
  final String id;
  final String title;
  final String authorName;
  final int minPlayerCount;
  final int maxPlayerCount;
  final GmRequirement gmRequirement;

  const Scenario({
    required this.id,
    required this.title,
    required this.authorName,
    required this.minPlayerCount,
    required this.maxPlayerCount,
    required this.gmRequirement,
  });

  @override
  List<Object?> get props => [id, title, authorName, minPlayerCount, maxPlayerCount, gmRequirement];
}