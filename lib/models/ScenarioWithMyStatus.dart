/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
* http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;

/** This is an auto generated class representing the ScenarioWithMyStatus type in your schema. */
class ScenarioWithMyStatus {
  // --- ▼ 修正 ▼ ---
  // Scenarioモデルのフィールドを追加
  final String _id;
  final String _title;
  final int? _minPlayerCount;
  final int? _maxPlayerCount;
  final GMRequirementType? _gmRequirement;
  final String? _storeUrl;
  final Author? _author;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;
  // --- ▲ 修正 ▲ ---

  final bool? _isPlayed;
  final bool? _isPossessed;

  // --- ▼ 修正 ▼ ---
  // Scenarioモデルのゲッターを追加
  String get id {
    return _id;
  }

  String get title {
    return _title;
  }

  int? get minPlayerCount {
    return _minPlayerCount;
  }

  int? get maxPlayerCount {
    return _maxPlayerCount;
  }

  GMRequirementType? get gmRequirement {
    return _gmRequirement;
  }

  String? get storeUrl {
    return _storeUrl;
  }

  Author? get author {
    return _author;
  }

  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }

  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  // --- ▲ 修正 ▲ ---

  bool? get isPlayed {
    return _isPlayed;
  }
  
  bool? get isPossessed {
    return _isPossessed;
  }
  
  const ScenarioWithMyStatus._internal({
    // --- ▼ 修正 ▼ ---
    required id,
    required title,
    minPlayerCount,
    maxPlayerCount,
    gmRequirement,
    storeUrl,
    author,
    createdAt,
    updatedAt,
    // --- ▲ 修正 ▲ ---
    isPlayed,
    isPossessed,
  })  : 
        // --- ▼ 修正 ▼ ---
        _id = id,
        _title = title,
        _minPlayerCount = minPlayerCount,
        _maxPlayerCount = maxPlayerCount,
        _gmRequirement = gmRequirement,
        _storeUrl = storeUrl,
        _author = author,
        _createdAt = createdAt,
        _updatedAt = updatedAt,
        // --- ▲ 修正 ▲ ---
        _isPlayed = isPlayed,
        _isPossessed = isPossessed;
  
  factory ScenarioWithMyStatus({
    // --- ▼ 修正 ▼ ---
    required String id,
    required String title,
    int? minPlayerCount,
    int? maxPlayerCount,
    GMRequirementType? gmRequirement,
    String? storeUrl,
    Author? author,
    // --- ▲ 修正 ▲ ---
    bool? isPlayed,
    bool? isPossessed,
  }) {
    return ScenarioWithMyStatus._internal(
      // --- ▼ 修正 ▼ ---
      id: id,
      title: title,
      minPlayerCount: minPlayerCount,
      maxPlayerCount: maxPlayerCount,
      gmRequirement: gmRequirement,
      storeUrl: storeUrl,
      author: author,
      // --- ▲ 修正 ▲ ---
      isPlayed: isPlayed,
      isPossessed: isPossessed,
    );
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ScenarioWithMyStatus &&
        // --- ▼ 修正 ▼ ---
        _id == other._id &&
        _title == other._title &&
        _minPlayerCount == other._minPlayerCount &&
        _maxPlayerCount == other._maxPlayerCount &&
        _gmRequirement == other._gmRequirement &&
        _storeUrl == other._storeUrl &&
        _author == other._author &&
        _createdAt == other._createdAt &&
        _updatedAt == other._updatedAt &&
        // --- ▲ 修正 ▲ ---
        _isPlayed == other._isPlayed &&
        _isPossessed == other._isPossessed;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("ScenarioWithMyStatus {");
    // --- ▼ 修正 ▼ ---
    buffer.write("id=" + "$_id" + ", ");
    buffer.write("title=" + "$_title" + ", ");
    buffer.write("minPlayerCount=" +
        (_minPlayerCount != null ? _minPlayerCount!.toString() : "null") +
        ", ");
    buffer.write("maxPlayerCount=" +
        (_maxPlayerCount != null ? _maxPlayerCount!.toString() : "null") +
        ", ");
    buffer.write("gmRequirement=" +
        (_gmRequirement != null
            ? amplify_core.enumToString(_gmRequirement)!
            : "null") +
        ", ");
    buffer.write("storeUrl=" + "$_storeUrl" + ", ");
    buffer.write(
        "author=" + (_author != null ? _author!.toString() : "null") + ", ");
    buffer.write("createdAt=" +
        (_createdAt != null ? _createdAt!.format() : "null") +
        ", ");
    buffer.write("updatedAt=" +
        (_updatedAt != null ? _updatedAt!.format() : "null") +
        ", ");
    // --- ▲ 修正 ▲ ---
    buffer.write(
        "isPlayed=" + (_isPlayed != null ? _isPlayed!.toString() : "null") + ", ");
    buffer.write("isPossessed=" +
        (_isPossessed != null ? _isPossessed!.toString() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  ScenarioWithMyStatus copyWith({
    // --- ▼ 修正 ▼ ---
    String? id,
    String? title,
    int? minPlayerCount,
    int? maxPlayerCount,
    GMRequirementType? gmRequirement,
    String? storeUrl,
    Author? author,
    // --- ▲ 修正 ▲ ---
    bool? isPlayed,
    bool? isPossessed,
  }) {
    return ScenarioWithMyStatus._internal(
      // --- ▼ 修正 ▼ ---
      id: id ?? this.id,
      title: title ?? this.title,
      minPlayerCount: minPlayerCount ?? this.minPlayerCount,
      maxPlayerCount: maxPlayerCount ?? this.maxPlayerCount,
      gmRequirement: gmRequirement ?? this.gmRequirement,
      storeUrl: storeUrl ?? this.storeUrl,
      author: author ?? this.author,
      // createdAt, updatedAt は更新しない想定
      // --- ▲ 修正 ▲ ---
      isPlayed: isPlayed ?? this.isPlayed,
      isPossessed: isPossessed ?? this.isPossessed,
    );
  }
  
  ScenarioWithMyStatus.fromJson(Map<String, dynamic> json)
      : 
        // --- ▼ 修正 ▼ ---
        _id = json['id'],
        _title = json['title'],
        _minPlayerCount = (json['minPlayerCount'] as num?)?.toInt(),
        _maxPlayerCount = (json['maxPlayerCount'] as num?)?.toInt(),
        _gmRequirement = amplify_core.enumFromString<GMRequirementType>(
            json['gmRequirement'], GMRequirementType.values),
        _storeUrl = json['storeUrl'],
        _author = json['author'] != null
            ? Author.fromJson(new Map<String, dynamic>.from(json['author']))
            : null,
        _createdAt = json['createdAt'] != null
            ? amplify_core.TemporalDateTime.fromString(json['createdAt'])
            : null,
        _updatedAt = json['updatedAt'] != null
            ? amplify_core.TemporalDateTime.fromString(json['updatedAt'])
            : null,
        // --- ▲ 修正 ▲ ---
        _isPlayed = json['isPlayed'],
        _isPossessed = json['isPossessed'];
  
  Map<String, dynamic> toJson() => {
        // --- ▼ 修正 ▼ ---
        'id': _id,
        'title': _title,
        'minPlayerCount': _minPlayerCount,
        'maxPlayerCount': _maxPlayerCount,
        'gmRequirement': amplify_core.enumToString(_gmRequirement),
        'storeUrl': _storeUrl,
        'author': _author?.toJson(),
        'createdAt': _createdAt?.format(),
        'updatedAt': _updatedAt?.format(),
        // --- ▲ 修正 ▲ ---
        'isPlayed': _isPlayed,
        'isPossessed': _isPossessed
      };
  
  Map<String, Object?> toMap() => {
        // --- ▼ 修正 ▼ ---
        'id': _id,
        'title': _title,
        'minPlayerCount': _minPlayerCount,
        'maxPlayerCount': _maxPlayerCount,
        'gmRequirement': _gmRequirement,
        'storeUrl': _storeUrl,
        'author': _author,
        'createdAt': _createdAt,
        'updatedAt': _updatedAt,
        // --- ▲ 修正 ▲ ---
        'isPlayed': _isPlayed,
        'isPossessed': _isPossessed
      };

  static var schema = amplify_core.Model.defineSchema(
      define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "ScenarioWithMyStatus";
    modelSchemaDefinition.pluralName = "ScenarioWithMyStatuses";
    
    // --- ▼ 修正 ▼ ---
    // (schema.graphqlの定義と合わせる必要があるが、
    //  ひとまずクエリで取得するフィールドを定義する)
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.customTypeField(
      fieldName: 'id',
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.customTypeField(
      fieldName: 'title',
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));

    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.customTypeField(
      fieldName: 'minPlayerCount',
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.customTypeField(
      fieldName: 'maxPlayerCount',
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));

    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.customTypeField(
      fieldName: 'gmRequirement',
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));

    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.customTypeField(
      fieldName: 'storeUrl',
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.customTypeField(
      fieldName: 'author',
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.embedded, ofCustomTypeName: 'Author')
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.customTypeField(
      fieldName: 'createdAt',
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.customTypeField(
      fieldName: 'updatedAt',
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    // --- ▲ 修正 ▲ ---
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.customTypeField(
      fieldName: 'isPlayed',
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.customTypeField(
      fieldName: 'isPossessed',
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
  });
}