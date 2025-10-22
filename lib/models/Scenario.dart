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
import 'package:collection/collection.dart';


/** This is an auto generated class representing the Scenario type in your schema. */
class Scenario extends amplify_core.Model {
  static const classType = const _ScenarioModelType();
  final String id;
  final String? _title;
  final int? _minPlayerCount;
  final int? _maxPlayerCount;
  final String? _gmRequirement;
  final String? _storeUrl;
  final Author? _author;
  final List<UserScenario>? _users;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  ScenarioModelIdentifier get modelIdentifier {
      return ScenarioModelIdentifier(
        id: id
      );
  }
  
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
  
  String? get gmRequirement {
    return _gmRequirement;
  }
  
  String? get storeUrl {
    return _storeUrl;
  }
  
  Author? get author {
    return _author;
  }
  
  List<UserScenario>? get users {
    return _users;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Scenario._internal({required this.id, required title, minPlayerCount, maxPlayerCount, gmRequirement, storeUrl, author, users, createdAt, updatedAt}): _title = title, _minPlayerCount = minPlayerCount, _maxPlayerCount = maxPlayerCount, _gmRequirement = gmRequirement, _storeUrl = storeUrl, _author = author, _users = users, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Scenario({String? id, required String title, int? minPlayerCount, int? maxPlayerCount, String? gmRequirement, String? storeUrl, Author? author, List<UserScenario>? users}) {
    return Scenario._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      title: title,
      minPlayerCount: minPlayerCount,
      maxPlayerCount: maxPlayerCount,
      gmRequirement: gmRequirement,
      storeUrl: storeUrl,
      author: author,
      users: users != null ? List<UserScenario>.unmodifiable(users) : users);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Scenario &&
      id == other.id &&
      _title == other._title &&
      _minPlayerCount == other._minPlayerCount &&
      _maxPlayerCount == other._maxPlayerCount &&
      _gmRequirement == other._gmRequirement &&
      _storeUrl == other._storeUrl &&
      _author == other._author &&
      DeepCollectionEquality().equals(_users, other._users);
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Scenario {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("title=" + "$_title" + ", ");
    buffer.write("minPlayerCount=" + (_minPlayerCount != null ? _minPlayerCount!.toString() : "null") + ", ");
    buffer.write("maxPlayerCount=" + (_maxPlayerCount != null ? _maxPlayerCount!.toString() : "null") + ", ");
    buffer.write("gmRequirement=" + "$_gmRequirement" + ", ");
    buffer.write("storeUrl=" + "$_storeUrl" + ", ");
    buffer.write("author=" + (_author != null ? _author!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Scenario copyWith({String? title, int? minPlayerCount, int? maxPlayerCount, String? gmRequirement, String? storeUrl, Author? author, List<UserScenario>? users}) {
    return Scenario._internal(
      id: id,
      title: title ?? this.title,
      minPlayerCount: minPlayerCount ?? this.minPlayerCount,
      maxPlayerCount: maxPlayerCount ?? this.maxPlayerCount,
      gmRequirement: gmRequirement ?? this.gmRequirement,
      storeUrl: storeUrl ?? this.storeUrl,
      author: author ?? this.author,
      users: users ?? this.users);
  }
  
  Scenario copyWithModelFieldValues({
    ModelFieldValue<String>? title,
    ModelFieldValue<int?>? minPlayerCount,
    ModelFieldValue<int?>? maxPlayerCount,
    ModelFieldValue<String?>? gmRequirement,
    ModelFieldValue<String?>? storeUrl,
    ModelFieldValue<Author?>? author,
    ModelFieldValue<List<UserScenario>?>? users
  }) {
    return Scenario._internal(
      id: id,
      title: title == null ? this.title : title.value,
      minPlayerCount: minPlayerCount == null ? this.minPlayerCount : minPlayerCount.value,
      maxPlayerCount: maxPlayerCount == null ? this.maxPlayerCount : maxPlayerCount.value,
      gmRequirement: gmRequirement == null ? this.gmRequirement : gmRequirement.value,
      storeUrl: storeUrl == null ? this.storeUrl : storeUrl.value,
      author: author == null ? this.author : author.value,
      users: users == null ? this.users : users.value
    );
  }
  
  Scenario.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _title = json['title'],
      _minPlayerCount = (json['minPlayerCount'] as num?)?.toInt(),
      _maxPlayerCount = (json['maxPlayerCount'] as num?)?.toInt(),
      _gmRequirement = json['gmRequirement'],
      _storeUrl = json['storeUrl'],
      _author = json['author'] != null
        ? json['author']['serializedData'] != null
          ? Author.fromJson(new Map<String, dynamic>.from(json['author']['serializedData']))
          : Author.fromJson(new Map<String, dynamic>.from(json['author']))
        : null,
      _users = json['users']  is Map
        ? (json['users']['items'] is List
          ? (json['users']['items'] as List)
              .where((e) => e != null)
              .map((e) => UserScenario.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['users'] is List
          ? (json['users'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => UserScenario.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'title': _title, 'minPlayerCount': _minPlayerCount, 'maxPlayerCount': _maxPlayerCount, 'gmRequirement': _gmRequirement, 'storeUrl': _storeUrl, 'author': _author?.toJson(), 'users': _users?.map((UserScenario? e) => e?.toJson()).toList(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'title': _title,
    'minPlayerCount': _minPlayerCount,
    'maxPlayerCount': _maxPlayerCount,
    'gmRequirement': _gmRequirement,
    'storeUrl': _storeUrl,
    'author': _author,
    'users': _users,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<ScenarioModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<ScenarioModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TITLE = amplify_core.QueryField(fieldName: "title");
  static final MINPLAYERCOUNT = amplify_core.QueryField(fieldName: "minPlayerCount");
  static final MAXPLAYERCOUNT = amplify_core.QueryField(fieldName: "maxPlayerCount");
  static final GMREQUIREMENT = amplify_core.QueryField(fieldName: "gmRequirement");
  static final STOREURL = amplify_core.QueryField(fieldName: "storeUrl");
  static final AUTHOR = amplify_core.QueryField(
    fieldName: "author",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Author'));
  static final USERS = amplify_core.QueryField(
    fieldName: "users",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'UserScenario'));
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Scenario";
    modelSchemaDefinition.pluralName = "Scenarios";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.READ
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PUBLIC,
        provider: amplify_core.AuthRuleProvider.APIKEY,
        operations: const [
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["id"], name: null),
      amplify_core.ModelIndex(fields: const ["authorId", "title"], name: "byAuthor")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Scenario.TITLE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Scenario.MINPLAYERCOUNT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Scenario.MAXPLAYERCOUNT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Scenario.GMREQUIREMENT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Scenario.STOREURL,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.belongsTo(
      key: Scenario.AUTHOR,
      isRequired: false,
      targetNames: ['authorId'],
      ofModelName: 'Author'
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: Scenario.USERS,
      isRequired: false,
      ofModelName: 'UserScenario',
      associatedKey: UserScenario.SCENARIO
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'createdAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'updatedAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _ScenarioModelType extends amplify_core.ModelType<Scenario> {
  const _ScenarioModelType();
  
  @override
  Scenario fromJson(Map<String, dynamic> jsonData) {
    return Scenario.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Scenario';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Scenario] in your schema.
 */
class ScenarioModelIdentifier implements amplify_core.ModelIdentifier<Scenario> {
  final String id;

  /** Create an instance of ScenarioModelIdentifier using [id] the primary key. */
  const ScenarioModelIdentifier({
    required this.id});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'id': id
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'ScenarioModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is ScenarioModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}