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


/** This is an auto generated class representing the ScenarioLogbookEntry type in your schema. */
class ScenarioLogbookEntry {
  final String id;
  final String? _title;
  final int? _minPlayerCount;
  final int? _maxPlayerCount;
  final GMRequirementType? _gmRequirement;
  final String? _storeUrl;
  final String? _authorId;
  final String? _authorName;
  final bool? _isPlayed;
  final bool? _isPossessed;

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
  
  String? get authorName {
    return _authorName;
  }
  
  bool get isPlayed {
    try {
      return _isPlayed!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  bool get isPossessed {
    try {
      return _isPossessed!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  const ScenarioLogbookEntry._internal({required this.id, required title, minPlayerCount, maxPlayerCount, gmRequirement, storeUrl, required authorId, authorName, required isPlayed, required isPossessed}): _title = title, _minPlayerCount = minPlayerCount, _maxPlayerCount = maxPlayerCount, _gmRequirement = gmRequirement, _storeUrl = storeUrl, _authorId = authorId, _authorName = authorName, _isPlayed = isPlayed, _isPossessed = isPossessed;
  
  factory ScenarioLogbookEntry({String? id, required String title, int? minPlayerCount, int? maxPlayerCount, GMRequirementType? gmRequirement, String? storeUrl, required String authorId, String? authorName, required bool isPlayed, required bool isPossessed}) {
    return ScenarioLogbookEntry._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      title: title,
      minPlayerCount: minPlayerCount,
      maxPlayerCount: maxPlayerCount,
      gmRequirement: gmRequirement,
      storeUrl: storeUrl,
      authorId: authorId,
      authorName: authorName,
      isPlayed: isPlayed,
      isPossessed: isPossessed);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ScenarioLogbookEntry &&
      id == other.id &&
      _title == other._title &&
      _minPlayerCount == other._minPlayerCount &&
      _maxPlayerCount == other._maxPlayerCount &&
      _gmRequirement == other._gmRequirement &&
      _storeUrl == other._storeUrl &&
      _authorId == other._authorId &&
      _authorName == other._authorName &&
      _isPlayed == other._isPlayed &&
      _isPossessed == other._isPossessed;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("ScenarioLogbookEntry {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("title=" + "$_title" + ", ");
    buffer.write("minPlayerCount=" + (_minPlayerCount != null ? _minPlayerCount!.toString() : "null") + ", ");
    buffer.write("maxPlayerCount=" + (_maxPlayerCount != null ? _maxPlayerCount!.toString() : "null") + ", ");
    buffer.write("gmRequirement=" + (_gmRequirement != null ? amplify_core.enumToString(_gmRequirement)! : "null") + ", ");
    buffer.write("storeUrl=" + "$_storeUrl" + ", ");
    buffer.write("authorId=" + "$_authorId" + ", ");
    buffer.write("authorName=" + "$_authorName" + ", ");
    buffer.write("isPlayed=" + (_isPlayed != null ? _isPlayed!.toString() : "null") + ", ");
    buffer.write("isPossessed=" + (_isPossessed != null ? _isPossessed!.toString() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  ScenarioLogbookEntry copyWith({String? id, String? title, int? minPlayerCount, int? maxPlayerCount, GMRequirementType? gmRequirement, String? storeUrl, String? authorId, String? authorName, bool? isPlayed, bool? isPossessed}) {
    return ScenarioLogbookEntry._internal(
      id: id ?? this.id,
      title: title ?? this.title,
      minPlayerCount: minPlayerCount ?? this.minPlayerCount,
      maxPlayerCount: maxPlayerCount ?? this.maxPlayerCount,
      gmRequirement: gmRequirement ?? this.gmRequirement,
      storeUrl: storeUrl ?? this.storeUrl,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      isPlayed: isPlayed ?? this.isPlayed,
      isPossessed: isPossessed ?? this.isPossessed);
  }
  
  ScenarioLogbookEntry copyWithModelFieldValues({
    ModelFieldValue<String>? id,
    ModelFieldValue<String>? title,
    ModelFieldValue<int?>? minPlayerCount,
    ModelFieldValue<int?>? maxPlayerCount,
    ModelFieldValue<GMRequirementType?>? gmRequirement,
    ModelFieldValue<String?>? storeUrl,
    ModelFieldValue<String>? authorId,
    ModelFieldValue<String?>? authorName,
    ModelFieldValue<bool>? isPlayed,
    ModelFieldValue<bool>? isPossessed
  }) {
    return ScenarioLogbookEntry._internal(
      id: id == null ? this.id : id.value,
      title: title == null ? this.title : title.value,
      minPlayerCount: minPlayerCount == null ? this.minPlayerCount : minPlayerCount.value,
      maxPlayerCount: maxPlayerCount == null ? this.maxPlayerCount : maxPlayerCount.value,
      gmRequirement: gmRequirement == null ? this.gmRequirement : gmRequirement.value,
      storeUrl: storeUrl == null ? this.storeUrl : storeUrl.value,
      authorId: authorId == null ? this.authorId : authorId.value,
      authorName: authorName == null ? this.authorName : authorName.value,
      isPlayed: isPlayed == null ? this.isPlayed : isPlayed.value,
      isPossessed: isPossessed == null ? this.isPossessed : isPossessed.value
    );
  }
  
  ScenarioLogbookEntry.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _title = json['title'],
      _minPlayerCount = (json['minPlayerCount'] as num?)?.toInt(),
      _maxPlayerCount = (json['maxPlayerCount'] as num?)?.toInt(),
      _gmRequirement = amplify_core.enumFromString<GMRequirementType>(json['gmRequirement'], GMRequirementType.values),
      _storeUrl = json['storeUrl'],
      _authorId = json['authorId'],
      _authorName = json['authorName'],
      _isPlayed = json['isPlayed'],
      _isPossessed = json['isPossessed'];
  
  Map<String, dynamic> toJson() => {
    'id': id, 'title': _title, 'minPlayerCount': _minPlayerCount, 'maxPlayerCount': _maxPlayerCount, 'gmRequirement': amplify_core.enumToString(_gmRequirement), 'storeUrl': _storeUrl, 'authorId': _authorId, 'authorName': _authorName, 'isPlayed': _isPlayed, 'isPossessed': _isPossessed
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'title': _title,
    'minPlayerCount': _minPlayerCount,
    'maxPlayerCount': _maxPlayerCount,
    'gmRequirement': _gmRequirement,
    'storeUrl': _storeUrl,
    'authorId': _authorId,
    'authorName': _authorName,
    'isPlayed': _isPlayed,
    'isPossessed': _isPossessed
  };

  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "ScenarioLogbookEntry";
    modelSchemaDefinition.pluralName = "ScenarioLogbookEntries";
    
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
      fieldName: 'authorName',
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.customTypeField(
      fieldName: 'isPlayed',
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.customTypeField(
      fieldName: 'isPossessed',
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
  });
}