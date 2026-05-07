// lib/features/scenario_logbook/domain/entities/scenario.dart

import 'package:flutter/material.dart';

enum GmRequirement {
  required,
  optional,
  none,
}

class Scenario {
  final String id;
  final String title;
  final String authorName;
  final String authorId;
  final int minPlayerCount;
  final int maxPlayerCount;
  final GmRequirement gmRequirement;
  final String? storeUrl;
  final String titleLower;
  final String authorNameLower;

  Scenario({
    required this.id,
    required this.title,
    required this.authorName,
    required this.authorId,
    required this.minPlayerCount,
    required this.maxPlayerCount,
    required this.gmRequirement,
    this.storeUrl,
    required this.titleLower,
    required this.authorNameLower,
  });

  factory Scenario.fromJson(Map<String, dynamic> json, String authorName) {
    GmRequirement gmReq;
    final gmReqStr = json['gmRequirement']?.toString().toLowerCase() ?? '';
    if (gmReqStr == 'required') {
      gmReq = GmRequirement.required;
    } else if (gmReqStr == 'optional') {
      gmReq = GmRequirement.optional;
    } else {
      gmReq = GmRequirement.none;
    }

    // すべてのStringフィールドに対して .toString() と ?? '' を使い、絶対Nullにならないようにします
    final id = (json['scenarioId'] ?? json['id'] ?? '').toString();
    final title = (json['title'] ?? '無題').toString();
    final authorId = (json['authorId'] ?? '').toString();

    return Scenario(
      id: id,
      title: title,
      authorName: authorName,
      authorId: authorId,
      minPlayerCount: (json['minPlayerCount'] as num?)?.toInt() ?? 0,
      maxPlayerCount: (json['maxPlayerCount'] as num?)?.toInt() ?? 0,
      gmRequirement: gmReq,
      storeUrl: json['storeUrl']?.toString(),
      titleLower: title.toLowerCase(),
      authorNameLower: authorName.toLowerCase(),
    );
  }
}