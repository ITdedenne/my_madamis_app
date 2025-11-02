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
  final bool? _isPlayed;
  final bool? _isPossessed;

  bool? get isPlayed {
    return _isPlayed;
  }
  
  bool? get isPossessed {
    return _isPossessed;
  }
  
  const ScenarioWithMyStatus._internal({isPlayed, isPossessed}): _isPlayed = isPlayed, _isPossessed = isPossessed;
  
  factory ScenarioWithMyStatus({bool? isPlayed, bool? isPossessed}) {
    return ScenarioWithMyStatus._internal(
      isPlayed: isPlayed,
      isPossessed: isPossessed);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ScenarioWithMyStatus &&
      _isPlayed == other._isPlayed &&
      _isPossessed == other._isPossessed;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("ScenarioWithMyStatus {");
    buffer.write("isPlayed=" + (_isPlayed != null ? _isPlayed!.toString() : "null") + ", ");
    buffer.write("isPossessed=" + (_isPossessed != null ? _isPossessed!.toString() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  ScenarioWithMyStatus copyWith({bool? isPlayed, bool? isPossessed}) {
    return ScenarioWithMyStatus._internal(
      isPlayed: isPlayed ?? this.isPlayed,
      isPossessed: isPossessed ?? this.isPossessed);
  }
  
  ScenarioWithMyStatus copyWithModelFieldValues({
    ModelFieldValue<bool?>? isPlayed,
    ModelFieldValue<bool?>? isPossessed
  }) {
    return ScenarioWithMyStatus._internal(
      isPlayed: isPlayed == null ? this.isPlayed : isPlayed.value,
      isPossessed: isPossessed == null ? this.isPossessed : isPossessed.value
    );
  }
  
  ScenarioWithMyStatus.fromJson(Map<String, dynamic> json)  
    : _isPlayed = json['isPlayed'],
      _isPossessed = json['isPossessed'];
  
  Map<String, dynamic> toJson() => {
    'isPlayed': _isPlayed, 'isPossessed': _isPossessed
  };
  
  Map<String, Object?> toMap() => {
    'isPlayed': _isPlayed,
    'isPossessed': _isPossessed
  };

  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "ScenarioWithMyStatus";
    modelSchemaDefinition.pluralName = "ScenarioWithMyStatuses";
    
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