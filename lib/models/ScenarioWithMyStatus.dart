/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
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
  final String id;
  final String? _title;
  final int? _minPlayerCount;
  final int? _maxPlayerCount;
  final GMRequirementType? _gmRequirement;
  final String? _storeUrl;
  final String? _authorId;
  final Author? _author;
  final bool? _isPlayed;
  final bool? _isPossessed;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  String get title {
    try {
      return _title!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
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
  
  String get authorId {
    try {
      return _authorId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  Author? get author {
    return _author;
  }
  
  bool? get isPlayed {
    return _isPlayed;
  }
  
  bool? get isPossessed {
    return _isPossessed;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const ScenarioWithMyStatus._internal({required this.id, required title, minPlayerCount, maxPlayerCount, gmRequirement, storeUrl, required authorId, author, isPlayed, isPossessed, createdAt, updatedAt}): _title = title, _minPlayerCount = minPlayerCount, _maxPlayerCount = maxPlayerCount, _gmRequirement = gmRequirement, _storeUrl = storeUrl, _authorId = authorId, _author = author, _isPlayed = isPlayed, _isPossessed = isPossessed, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory ScenarioWithMyStatus({String? id, required String title, int? minPlayerCount, int? maxPlayerCount, GMRequirementType? gmRequirement, String? storeUrl, required String authorId, Author? author, bool? isPlayed, bool? isPossessed, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return ScenarioWithMyStatus._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      title: title,
      minPlayerCount: minPlayerCount,
      maxPlayerCount: maxPlayerCount,
      gmRequirement: gmRequirement,
      storeUrl: storeUrl,
      authorId: authorId,
      author: author,
      isPlayed: isPlayed,
      isPossessed: isPossessed,
      createdAt: createdAt,
      updatedAt: updatedAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ScenarioWithMyStatus &&
      id == other.id &&
      _title == other._title &&
      _minPlayerCount == other._minPlayerCount &&
      _maxPlayerCount == other._maxPlayerCount &&
      _gmRequirement == other._gmRequirement &&
      _storeUrl == other._storeUrl &&
      _authorId == other._authorId &&
      _author == other._author &&
      _isPlayed == other._isPlayed &&
      _isPossessed == other._isPossessed &&
      _createdAt == other._createdAt &&
      _updatedAt == other._updatedAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("ScenarioWithMyStatus {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("title=" + "$_title" + ", ");
    buffer.write("minPlayerCount=" + (_minPlayerCount != null ? _minPlayerCount!.toString() : "null") + ", ");
    buffer.write("maxPlayerCount=" + (_maxPlayerCount != null ? _maxPlayerCount!.toString() : "null") + ", ");
    buffer.write("gmRequirement=" + (_gmRequirement != null ? amplify_core.enumToString(_gmRequirement)! : "null") + ", ");
    buffer.write("storeUrl=" + "$_storeUrl" + ", ");
    buffer.write("authorId=" + "$_authorId" + ", ");
    buffer.write("author=" + (_author != null ? _author!.toString() : "null") + ", ");
    buffer.write("isPlayed=" + (_isPlayed != null ? _isPlayed!.toString() : "null") + ", ");
    buffer.write("isPossessed=" + (_isPossessed != null ? _isPossessed!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  ScenarioWithMyStatus copyWith({String? id, String? title, int? minPlayerCount, int? maxPlayerCount, GMRequirementType? gmRequirement, String? storeUrl, String? authorId, Author? author, bool? isPlayed, bool? isPossessed, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return ScenarioWithMyStatus._internal(
      id: id ?? this.id,
      title: title ?? this.title,
      minPlayerCount: minPlayerCount ?? this.minPlayerCount,
      maxPlayerCount: maxPlayerCount ?? this.maxPlayerCount,
      gmRequirement: gmRequirement ?? this.gmRequirement,
      storeUrl: storeUrl ?? this.storeUrl,
      authorId: authorId ?? this.authorId,
      author: author ?? this.author,
      isPlayed: isPlayed ?? this.isPlayed,
      isPossessed: isPossessed ?? this.isPossessed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }
  
  ScenarioWithMyStatus copyWithModelFieldValues({
    ModelFieldValue<String>? id,
    ModelFieldValue<String>? title,
    ModelFieldValue<int?>? minPlayerCount,
    ModelFieldValue<int?>? maxPlayerCount,
    ModelFieldValue<GMRequirementType?>? gmRequirement,
    ModelFieldValue<String?>? storeUrl,
    ModelFieldValue<String>? authorId,
    ModelFieldValue<Author?>? author,
    ModelFieldValue<bool?>? isPlayed,
    ModelFieldValue<bool?>? isPossessed,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt
  }) {
    return ScenarioWithMyStatus._internal(
      id: id == null ? this.id : id.value,
      title: title == null ? this.title : title.value,
      minPlayerCount: minPlayerCount == null ? this.minPlayerCount : minPlayerCount.value,
      maxPlayerCount: maxPlayerCount == null ? this.maxPlayerCount : maxPlayerCount.value,
      gmRequirement: gmRequirement == null ? this.gmRequirement : gmRequirement.value,
      storeUrl: storeUrl == null ? this.storeUrl : storeUrl.value,
      authorId: authorId == null ? this.authorId : authorId.value,
      author: author == null ? this.author : author.value,
      isPlayed: isPlayed == null ? this.isPlayed : isPlayed.value,
      isPossessed: isPossessed == null ? this.isPossessed : isPossessed.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value
    );
  }
  
  ScenarioWithMyStatus.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _title = json['title'],
      _minPlayerCount = (json['minPlayerCount'] as num?)?.toInt(),
      _maxPlayerCount = (json['maxPlayerCount'] as num?)?.toInt(),
      _gmRequirement = amplify_core.enumFromString<GMRequirementType>(json['gmRequirement'], GMRequirementType.values),
      _storeUrl = json['storeUrl'],
      _authorId = json['authorId'],
      _author = json['author'] != null
        ? json['author']['serializedData'] != null
          ? Author.fromJson(new Map<String, dynamic>.from(json['author']['serializedData']))
          : Author.fromJson(new Map<String, dynamic>.from(json['author']))
        : null,
      _isPlayed = json['isPlayed'],
      _isPossessed = json['isPossessed'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'title': _title, 'minPlayerCount': _minPlayerCount, 'maxPlayerCount': _maxPlayerCount, 'gmRequirement': amplify_core.enumToString(_gmRequirement), 'storeUrl': _storeUrl, 'authorId': _authorId, 'author': _author?.toJson(), 'isPlayed': _isPlayed, 'isPossessed': _isPossessed, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'title': _title,
    'minPlayerCount': _minPlayerCount,
    'maxPlayerCount': _maxPlayerCount,
    'gmRequirement': _gmRequirement,
    'storeUrl': _storeUrl,
    'authorId': _authorId,
    'author': _author,
    'isPlayed': _isPlayed,
    'isPossessed': _isPossessed,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "ScenarioWithMyStatus";
    modelSchemaDefinition.pluralName = "ScenarioWithMyStatuses";
    
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
      fieldName: 'authorId',
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.customTypeField(
      fieldName: 'author',
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
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
  });
}