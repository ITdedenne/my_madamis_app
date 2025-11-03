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


/** This is an auto generated class representing the UserScenario type in your schema. */
class UserScenario extends amplify_core.Model {
  static const classType = const _UserScenarioModelType();
  final String id;
  final User? _user;
  final Scenario? _scenario;
  final bool? _isPlayed;
  final bool? _isPossessed;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  UserScenarioModelIdentifier get modelIdentifier {
      return UserScenarioModelIdentifier(
        id: id
      );
  }
  
  User? get user {
    return _user;
  }
  
  Scenario? get scenario {
    return _scenario;
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
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const UserScenario._internal({required this.id, user, scenario, required isPlayed, required isPossessed, createdAt, updatedAt}): _user = user, _scenario = scenario, _isPlayed = isPlayed, _isPossessed = isPossessed, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory UserScenario({String? id, User? user, Scenario? scenario, required bool isPlayed, required bool isPossessed}) {
    return UserScenario._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      user: user,
      scenario: scenario,
      isPlayed: isPlayed,
      isPossessed: isPossessed);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserScenario &&
      id == other.id &&
      _user == other._user &&
      _scenario == other._scenario &&
      _isPlayed == other._isPlayed &&
      _isPossessed == other._isPossessed;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("UserScenario {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("user=" + (_user != null ? _user!.toString() : "null") + ", ");
    buffer.write("scenario=" + (_scenario != null ? _scenario!.toString() : "null") + ", ");
    buffer.write("isPlayed=" + (_isPlayed != null ? _isPlayed!.toString() : "null") + ", ");
    buffer.write("isPossessed=" + (_isPossessed != null ? _isPossessed!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  UserScenario copyWith({User? user, Scenario? scenario, bool? isPlayed, bool? isPossessed}) {
    return UserScenario._internal(
      id: id,
      user: user ?? this.user,
      scenario: scenario ?? this.scenario,
      isPlayed: isPlayed ?? this.isPlayed,
      isPossessed: isPossessed ?? this.isPossessed);
  }
  
  UserScenario copyWithModelFieldValues({
    ModelFieldValue<User?>? user,
    ModelFieldValue<Scenario?>? scenario,
    ModelFieldValue<bool>? isPlayed,
    ModelFieldValue<bool>? isPossessed
  }) {
    return UserScenario._internal(
      id: id,
      user: user == null ? this.user : user.value,
      scenario: scenario == null ? this.scenario : scenario.value,
      isPlayed: isPlayed == null ? this.isPlayed : isPlayed.value,
      isPossessed: isPossessed == null ? this.isPossessed : isPossessed.value
    );
  }
  
  UserScenario.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _user = json['user'] != null
        ? json['user']['serializedData'] != null
          ? User.fromJson(new Map<String, dynamic>.from(json['user']['serializedData']))
          : User.fromJson(new Map<String, dynamic>.from(json['user']))
        : null,
      _scenario = json['scenario'] != null
        ? json['scenario']['serializedData'] != null
          ? Scenario.fromJson(new Map<String, dynamic>.from(json['scenario']['serializedData']))
          : Scenario.fromJson(new Map<String, dynamic>.from(json['scenario']))
        : null,
      _isPlayed = json['isPlayed'],
      _isPossessed = json['isPossessed'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'user': _user?.toJson(), 'scenario': _scenario?.toJson(), 'isPlayed': _isPlayed, 'isPossessed': _isPossessed, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'user': _user,
    'scenario': _scenario,
    'isPlayed': _isPlayed,
    'isPossessed': _isPossessed,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<UserScenarioModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<UserScenarioModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final USER = amplify_core.QueryField(
    fieldName: "user",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'User'));
  static final SCENARIO = amplify_core.QueryField(
    fieldName: "scenario",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Scenario'));
  static final ISPLAYED = amplify_core.QueryField(fieldName: "isPlayed");
  static final ISPOSSESSED = amplify_core.QueryField(fieldName: "isPossessed");
  
  // --- ▼ 追加: DataStoreでIDによる検索を可能にするための静的フィールド ▼ ---
  static final USERID = amplify_core.QueryField(fieldName: 'userId');
  static final SCENARIOID = amplify_core.QueryField(fieldName: 'scenarioId');
  // --- ▲ 追加 ▲ ---

  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "UserScenario";
    modelSchemaDefinition.pluralName = "UserScenarios";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "userId",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["userId"], name: "byUser"),
      amplify_core.ModelIndex(fields: const ["scenarioId"], name: "byScenario")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.belongsTo(
      key: UserScenario.USER,
      isRequired: false,
      targetNames: ['userId'],
      ofModelName: 'User'
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.belongsTo(
      key: UserScenario.SCENARIO,
      isRequired: false,
      targetNames: ['scenarioId'],
      ofModelName: 'Scenario'
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserScenario.ISPLAYED,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserScenario.ISPOSSESSED,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
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

class _UserScenarioModelType extends amplify_core.ModelType<UserScenario> {
  const _UserScenarioModelType();
  
  @override
  UserScenario fromJson(Map<String, dynamic> jsonData) {
    return UserScenario.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'UserScenario';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [UserScenario] in your schema.
 */
class UserScenarioModelIdentifier implements amplify_core.ModelIdentifier<UserScenario> {
  final String id;

  /** Create an instance of UserScenarioModelIdentifier using [id] the primary key. */
  const UserScenarioModelIdentifier({
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
  String toString() => 'UserScenarioModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is UserScenarioModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}