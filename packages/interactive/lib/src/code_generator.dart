import 'dart:io';

class CodeGenerator {
  // TODO do not hardcode this...
  final path =
      '/Users/tom/RefCode/dart_interactive/packages/execution_workspace/lib/auto_generated.dart';

  void generate(String rawCode) {
    final wrappedCode = '''
// AUTO-GENERATED, PLEASE DO NOT MODIFY BY HAND

import 'workspace.dart'; // ignore: unused_import
export 'workspace.dart';

extension ExtDynamic on dynamic {
  void generatedMethod() {
    $rawCode
  }
}
    ''';

    File(path).writeAsStringSync(wrappedCode, flush: true);
  }
}
