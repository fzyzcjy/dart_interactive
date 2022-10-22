class WorkspaceCode {
  final declarationMap = <DeclarationKey, String>{};
  String generatedMethodCodeBlock = '';

  String generate() {
    return '''
// AUTO-GENERATED, PLEASE DO NOT MODIFY BY HAND

import 'workspace.dart'; // ignore: unused_import
export 'workspace.dart';

${declarationMap.values.join('\n\n')}

extension ExtDynamic on dynamic {
  void generatedMethod() {
    $generatedMethodCodeBlock
  }
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
