class WorkspaceCode {
  final Set<String> imports;
  final Map<String, String> classMap;
  final Map<String, String> functionMap;
  final Map<String, String> miscDeclarationMap;
  final String generatedMethodCodeBlock;

  const WorkspaceCode({
    required this.imports,
    required this.classMap,
    required this.functionMap,
    required this.miscDeclarationMap,
    required this.generatedMethodCodeBlock,
  });

  const WorkspaceCode.codeBlock({
    required this.generatedMethodCodeBlock,
  })  : imports = const {},
        classMap = const {},
        functionMap = const {},
        miscDeclarationMap = const {};

  const WorkspaceCode.empty()
      : imports = const {},
        classMap = const {},
        functionMap = const {},
        miscDeclarationMap = const {},
        generatedMethodCodeBlock = '';

  WorkspaceCode merge(WorkspaceCode other) => WorkspaceCode(
        imports: {...imports, ...other.imports},
        classMap: {...classMap, ...other.classMap},
        functionMap: {...functionMap, ...other.functionMap},
        miscDeclarationMap: {
          ...miscDeclarationMap,
          ...other.miscDeclarationMap
        },
        generatedMethodCodeBlock: other.generatedMethodCodeBlock,
      );

  String generate() {
    return '''
// AUTO-GENERATED, PLEASE DO NOT MODIFY BY HAND

import 'package:interactive/src/runtime_support.dart';

import 'workspace.dart'; // ignore: unused_import
export 'workspace.dart';

${imports.join('\n')}

${classMap.values.join('\n\n')}

${miscDeclarationMap.values.join('\n\n')}

extension ExtDynamic on dynamic {
  Object? generatedMethod() {
    $generatedMethodCodeBlock
  }
  
  ${functionMap.values.join('\n\n')}
}
''';
  }
}

class DeclarationKey {
  final Type type;
  final String identifier;

  DeclarationKey(this.type, this.identifier);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeclarationKey &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          identifier == other.identifier;

  @override
  int get hashCode => type.hashCode ^ identifier.hashCode;

  @override
  String toString() => 'DeclarationKey($type, $identifier)';
}
