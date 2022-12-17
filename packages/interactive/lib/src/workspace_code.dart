import 'package:interactive/src/runtime_support.dart';
import 'package:logging/logging.dart';

class WorkspaceCode {
  final Set<String> imports;
  final Map<String, ClassInfo> classMap;
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

//import 'package:interactive/src/runtime_support.dart';
$kRuntimeSupportImport
${imports.join('\n')}

$kRuntimeSupportCode

${classMap.values.map((e) => e.generate()).join('\n\n')}

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

class ClassInfo {
  static final log = Logger('ClassInfo');

  final String rawCode;
  final Set<String> potentialAccessors;

  ClassInfo({
    required this.rawCode,
    required this.potentialAccessors,
  });

  String generate() {
    const kEnding = '}';

    if (!rawCode.endsWith(kEnding)) {
      log.info(
          'generateClass skip since not endsWidth "$kEnding" (rawCode=$rawCode)');
      return rawCode;
    }

    final accessorCodes =
        potentialAccessors.map(_generateAccessorCode).join('\n');

    final replacedEnding = '$accessorCodes\n}';

    return rawCode.substring(0, rawCode.length - kEnding.length) +
        replacedEnding;
  }

  static String _generateAccessorCode(String name) {
    return '''
dynamic get $name => synthesizedClassNoSuchMethod(Invocation.getter(#$name));
set $name(dynamic value) => synthesizedClassNoSuchMethod(Invocation.setter(#$name, value));''';
  }
}
