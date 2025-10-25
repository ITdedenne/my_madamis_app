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


/** This is an auto generated class representing the Author type in your schema. */
class Author extends amplify_core.Model {
  static const classType = const _AuthorModelType();
  final String id;
  final String? _authorName;
  final List<Scenario>? _scenarios;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  AuthorModelIdentifier get modelIdentifier {
      return AuthorModelIdentifier(
        id: id
      );
  }
  
  String get authorName {
    try {
      return _authorName!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  List<Scenario>? get scenarios {
    return _scenarios;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Author._internal({required this.id, required authorName, scenarios, createdAt, updatedAt}): _authorName = authorName, _scenarios = scenarios, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Author({String? id, required String authorName, List<Scenario>? scenarios}) {
    return Author._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      authorName: authorName,
      scenarios: scenarios != null ? List<Scenario>.unmodifiable(scenarios) : scenarios);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Author &&
      id == other.id &&
      _authorName == other._authorName &&
      DeepCollectionEquality().equals(_scenarios, other._scenarios);
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Author {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("authorName=" + "$_authorName" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Author copyWith({String? authorName, List<Scenario>? scenarios}) {
    return Author._internal(
      id: id,
      authorName: authorName ?? this.authorName,
      scenarios: scenarios ?? this.scenarios);
  }
  
  Author copyWithModelFieldValues({
    ModelFieldValue<String>? authorName,
    ModelFieldValue<List<Scenario>?>? scenarios
  }) {
    return Author._internal(
      id: id,
      authorName: authorName == null ? this.authorName : authorName.value,
      scenarios: scenarios == null ? this.scenarios : scenarios.value
    );
  }
  
  Author.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _authorName = json['authorName'],
      _scenarios = json['scenarios']  is Map
        ? (json['scenarios']['items'] is List
          ? (json['scenarios']['items'] as List)
              .where((e) => e != null)
              .map((e) => Scenario.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['scenarios'] is List
          ? (json['scenarios'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => Scenario.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'authorName': _authorName, 'scenarios': _scenarios?.map((Scenario? e) => e?.toJson()).toList(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'authorName': _authorName,
    'scenarios': _scenarios,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<AuthorModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<AuthorModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final AUTHORNAME = amplify_core.QueryField(fieldName: "authorName");
  static final SCENARIOS = amplify_core.QueryField(
    fieldName: "scenarios",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Scenario'));
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Author";
    modelSchemaDefinition.pluralName = "Authors";
    
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
      amplify_core.ModelIndex(fields: const ["id"], name: null)
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Author.AUTHORNAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: Author.SCENARIOS,
      isRequired: false,
      ofModelName: 'Scenario',
      associatedKey: Scenario.AUTHOR
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

class _AuthorModelType extends amplify_core.ModelType<Author> {
  const _AuthorModelType();
  
  @override
  Author fromJson(Map<String, dynamic> jsonData) {
    return Author.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Author';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Author] in your schema.
 */
class AuthorModelIdentifier implements amplify_core.ModelIdentifier<Author> {
  final String id;

  /** Create an instance of AuthorModelIdentifier using [id] the primary key. */
  const AuthorModelIdentifier({
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
  String toString() => 'AuthorModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is AuthorModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}