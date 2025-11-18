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


/** This is an auto generated class representing the UserScenario type in your schema. */
class UserScenario extends amplify_core.Model {
  static const classType = const _UserScenarioModelType();
  final String? _userId;
  final String? _scenarioId;
  final bool? _isPlayed;
  final bool? _isPossessed;
  final bool? _wantsToGm;
  final User? _user;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => modelIdentifier.serializeAsString();
  
  UserScenarioModelIdentifier get modelIdentifier {
    try {
      return UserScenarioModelIdentifier(
        userId: _userId!,
        scenarioId: _scenarioId!
      );
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get userId {
    try {
      return _userId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get scenarioId {
    try {
      return _scenarioId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
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
  
  bool get wantsToGm {
    try {
      return _wantsToGm!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  User? get user {
    return _user;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const UserScenario._internal({required userId, required scenarioId, required isPlayed, required isPossessed, required wantsToGm, user, createdAt, updatedAt}): _userId = userId, _scenarioId = scenarioId, _isPlayed = isPlayed, _isPossessed = isPossessed, _wantsToGm = wantsToGm, _user = user, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory UserScenario({required String userId, required String scenarioId, required bool isPlayed, required bool isPossessed, required bool wantsToGm, User? user}) {
    return UserScenario._internal(
      userId: userId,
      scenarioId: scenarioId,
      isPlayed: isPlayed,
      isPossessed: isPossessed,
      wantsToGm: wantsToGm,
      user: user);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserScenario &&
      _userId == other._userId &&
      _scenarioId == other._scenarioId &&
      _isPlayed == other._isPlayed &&
      _isPossessed == other._isPossessed &&
      _wantsToGm == other._wantsToGm &&
      _user == other._user;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("UserScenario {");
    buffer.write("userId=" + "$_userId" + ", ");
    buffer.write("scenarioId=" + "$_scenarioId" + ", ");
    buffer.write("isPlayed=" + (_isPlayed != null ? _isPlayed!.toString() : "null") + ", ");
    buffer.write("isPossessed=" + (_isPossessed != null ? _isPossessed!.toString() : "null") + ", ");
    buffer.write("wantsToGm=" + (_wantsToGm != null ? _wantsToGm!.toString() : "null") + ", ");
    buffer.write("user=" + (_user != null ? _user!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  UserScenario copyWith({bool? isPlayed, bool? isPossessed, bool? wantsToGm, User? user}) {
    return UserScenario._internal(
      userId: userId,
      scenarioId: scenarioId,
      isPlayed: isPlayed ?? this.isPlayed,
      isPossessed: isPossessed ?? this.isPossessed,
      wantsToGm: wantsToGm ?? this.wantsToGm,
      user: user ?? this.user);
  }
  
  UserScenario copyWithModelFieldValues({
    ModelFieldValue<bool>? isPlayed,
    ModelFieldValue<bool>? isPossessed,
    ModelFieldValue<bool>? wantsToGm,
    ModelFieldValue<User?>? user
  }) {
    return UserScenario._internal(
      userId: userId,
      scenarioId: scenarioId,
      isPlayed: isPlayed == null ? this.isPlayed : isPlayed.value,
      isPossessed: isPossessed == null ? this.isPossessed : isPossessed.value,
      wantsToGm: wantsToGm == null ? this.wantsToGm : wantsToGm.value,
      user: user == null ? this.user : user.value
    );
  }
  
  UserScenario.fromJson(Map<String, dynamic> json)  
    : _userId = json['userId'],
      _scenarioId = json['scenarioId'],
      _isPlayed = json['isPlayed'],
      _isPossessed = json['isPossessed'],
      _wantsToGm = json['wantsToGm'],
      _user = json['user'] != null
        ? json['user']['serializedData'] != null
          ? User.fromJson(new Map<String, dynamic>.from(json['user']['serializedData']))
          : User.fromJson(new Map<String, dynamic>.from(json['user']))
        : null,
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'userId': _userId, 'scenarioId': _scenarioId, 'isPlayed': _isPlayed, 'isPossessed': _isPossessed, 'wantsToGm': _wantsToGm, 'user': _user?.toJson(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'userId': _userId,
    'scenarioId': _scenarioId,
    'isPlayed': _isPlayed,
    'isPossessed': _isPossessed,
    'wantsToGm': _wantsToGm,
    'user': _user,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<UserScenarioModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<UserScenarioModelIdentifier>();
  static final USERID = amplify_core.QueryField(fieldName: "userId");
  static final SCENARIOID = amplify_core.QueryField(fieldName: "scenarioId");
  static final ISPLAYED = amplify_core.QueryField(fieldName: "isPlayed");
  static final ISPOSSESSED = amplify_core.QueryField(fieldName: "isPossessed");
  static final WANTSTOGM = amplify_core.QueryField(fieldName: "wantsToGm");
  static final USER = amplify_core.QueryField(
    fieldName: "user",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'User'));
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
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["userId", "scenarioId"], name: null),
      amplify_core.ModelIndex(fields: const ["userId"], name: "byUser"),
      amplify_core.ModelIndex(fields: const ["scenarioId", "userId"], name: "byScenario")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserScenario.USERID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserScenario.SCENARIOID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
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
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserScenario.WANTSTOGM,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.belongsTo(
      key: UserScenario.USER,
      isRequired: false,
      targetNames: ['userId'],
      ofModelName: 'User'
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
  final String userId;
  final String scenarioId;

  /**
   * Create an instance of UserScenarioModelIdentifier using [userId] the primary key.
   * And [scenarioId] the sort key.
   */
  const UserScenarioModelIdentifier({
    required this.userId,
    required this.scenarioId});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'userId': userId,
    'scenarioId': scenarioId
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'UserScenarioModelIdentifier(userId: $userId, scenarioId: $scenarioId)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is UserScenarioModelIdentifier &&
      userId == other.userId &&
      scenarioId == other.scenarioId;
  }
  
  @override
  int get hashCode =>
    userId.hashCode ^
    scenarioId.hashCode;
}