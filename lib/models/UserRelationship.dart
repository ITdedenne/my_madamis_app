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


/** This is an auto generated class representing the UserRelationship type in your schema. */
class UserRelationship extends amplify_core.Model {
  static const classType = const _UserRelationshipModelType();
  final String? _followingId;
  final String? _followedId;
  final User? _followingUser;
  final User? _followedUser;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => modelIdentifier.serializeAsString();
  
  UserRelationshipModelIdentifier get modelIdentifier {
    try {
      return UserRelationshipModelIdentifier(
        followingId: _followingId!,
        followedId: _followedId!
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
  
  String get followingId {
    try {
      return _followingId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get followedId {
    try {
      return _followedId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  User? get followingUser {
    return _followingUser;
  }
  
  User? get followedUser {
    return _followedUser;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const UserRelationship._internal({required followingId, required followedId, followingUser, followedUser, createdAt, updatedAt}): _followingId = followingId, _followedId = followedId, _followingUser = followingUser, _followedUser = followedUser, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory UserRelationship({required String followingId, required String followedId, User? followingUser, User? followedUser}) {
    return UserRelationship._internal(
      followingId: followingId,
      followedId: followedId,
      followingUser: followingUser,
      followedUser: followedUser);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserRelationship &&
      _followingId == other._followingId &&
      _followedId == other._followedId &&
      _followingUser == other._followingUser &&
      _followedUser == other._followedUser;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("UserRelationship {");
    buffer.write("followingId=" + "$_followingId" + ", ");
    buffer.write("followedId=" + "$_followedId" + ", ");
    buffer.write("followingUser=" + (_followingUser != null ? _followingUser!.toString() : "null") + ", ");
    buffer.write("followedUser=" + (_followedUser != null ? _followedUser!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  UserRelationship copyWith({User? followingUser, User? followedUser}) {
    return UserRelationship._internal(
      followingId: followingId,
      followedId: followedId,
      followingUser: followingUser ?? this.followingUser,
      followedUser: followedUser ?? this.followedUser);
  }
  
  UserRelationship copyWithModelFieldValues({
    ModelFieldValue<User?>? followingUser,
    ModelFieldValue<User?>? followedUser
  }) {
    return UserRelationship._internal(
      followingId: followingId,
      followedId: followedId,
      followingUser: followingUser == null ? this.followingUser : followingUser.value,
      followedUser: followedUser == null ? this.followedUser : followedUser.value
    );
  }
  
  UserRelationship.fromJson(Map<String, dynamic> json)  
    : _followingId = json['followingId'],
      _followedId = json['followedId'],
      _followingUser = json['followingUser'] != null
        ? json['followingUser']['serializedData'] != null
          ? User.fromJson(new Map<String, dynamic>.from(json['followingUser']['serializedData']))
          : User.fromJson(new Map<String, dynamic>.from(json['followingUser']))
        : null,
      _followedUser = json['followedUser'] != null
        ? json['followedUser']['serializedData'] != null
          ? User.fromJson(new Map<String, dynamic>.from(json['followedUser']['serializedData']))
          : User.fromJson(new Map<String, dynamic>.from(json['followedUser']))
        : null,
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'followingId': _followingId, 'followedId': _followedId, 'followingUser': _followingUser?.toJson(), 'followedUser': _followedUser?.toJson(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'followingId': _followingId,
    'followedId': _followedId,
    'followingUser': _followingUser,
    'followedUser': _followedUser,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<UserRelationshipModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<UserRelationshipModelIdentifier>();
  static final FOLLOWINGID = amplify_core.QueryField(fieldName: "followingId");
  static final FOLLOWEDID = amplify_core.QueryField(fieldName: "followedId");
  static final FOLLOWINGUSER = amplify_core.QueryField(
    fieldName: "followingUser",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'User'));
  static final FOLLOWEDUSER = amplify_core.QueryField(
    fieldName: "followedUser",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'User'));
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "UserRelationship";
    modelSchemaDefinition.pluralName = "UserRelationships";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "followingId",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.DELETE
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["followingId", "followedId"], name: null),
      amplify_core.ModelIndex(fields: const ["followedId", "followingId"], name: "byFollowed")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserRelationship.FOLLOWINGID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserRelationship.FOLLOWEDID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.belongsTo(
      key: UserRelationship.FOLLOWINGUSER,
      isRequired: false,
      targetNames: ['followingId'],
      ofModelName: 'User'
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.belongsTo(
      key: UserRelationship.FOLLOWEDUSER,
      isRequired: false,
      targetNames: ['followedId'],
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

class _UserRelationshipModelType extends amplify_core.ModelType<UserRelationship> {
  const _UserRelationshipModelType();
  
  @override
  UserRelationship fromJson(Map<String, dynamic> jsonData) {
    return UserRelationship.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'UserRelationship';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [UserRelationship] in your schema.
 */
class UserRelationshipModelIdentifier implements amplify_core.ModelIdentifier<UserRelationship> {
  final String followingId;
  final String followedId;

  /**
   * Create an instance of UserRelationshipModelIdentifier using [followingId] the primary key.
   * And [followedId] the sort key.
   */
  const UserRelationshipModelIdentifier({
    required this.followingId,
    required this.followedId});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'followingId': followingId,
    'followedId': followedId
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'UserRelationshipModelIdentifier(followingId: $followingId, followedId: $followedId)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is UserRelationshipModelIdentifier &&
      followingId == other.followingId &&
      followedId == other.followedId;
  }
  
  @override
  int get hashCode =>
    followingId.hashCode ^
    followedId.hashCode;
}