class WorkspaceCode {
  final classCodeOfNameMap = <String, String>{};
  String generatedMethodCodeBlock = '';

  String generate() {
    return '''
// AUTO-GENERATED, PLEASE DO NOT MODIFY BY HAND

import 'workspace.dart'; // ignore: unused_import
export 'workspace.dart';

${classCodeOfNameMap.values.join('\n\n')}

extension ExtDynamic on dynamic {
  void generatedMethod() {
    $generatedMethodCodeBlock
  }
}
''';
  }
}
