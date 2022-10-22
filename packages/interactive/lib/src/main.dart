import 'dart:io';

import 'package:interactive/src/parser.dart';
import 'package:interactive/src/reader.dart';
import 'package:interactive/src/vm_service_wrapper.dart';
import 'package:interactive/src/workspace_code.dart';
import 'package:interactive/src/workspace_isolate.dart';
import 'package:vm_service/vm_service.dart';

Future<void> main() async {
  // TODO should dynamically generate
  const executionWorkspaceDir =
      '/Users/tom/RefCode/dart_interactive/packages/execution_workspace';

  final vm = await VmServiceWrapper.create();
  final executionWorkspaceManager =
      await WorkspaceIsolate.create(vm, executionWorkspaceDir);
  final workspaceCode = WorkspaceCode();

  final reader = ReplReader();

  // final reader = TestReader([
  //   'a = 10;',
  //   'print(a);',
  //   'class C { int a = 10; void f() => print("I am f, a=\$a"); }',
  //   'c = C(); c.f();',
  //   'class C { int a = 10; void f() => print("I am NEW f, a=\$a"); }',
  //   'c.f();',
  //   'void func() { print("old func"); }',
  //   'func();',
  //   'void func() { print("NEW func"); }',
  //   'func();',
  // ]);

  try {
    await reader.run((input) =>
        _handleInput(vm, executionWorkspaceManager, workspaceCode, input));
  } finally {
    vm.dispose();
  }
}

const _evaluateCode = 'interactiveRuntimeContext.generatedMethod()';

// TODO do not hardcode this...
const workspaceCodePath =
    '/Users/tom/RefCode/dart_interactive/packages/execution_workspace/lib/auto_generated.dart';

Future<void> _handleInput(
  VmServiceWrapper vm,
  WorkspaceIsolate executionWorkspaceManager,
  WorkspaceCode workspaceCode,
  String rawInput,
) async {
  print('Phase: Parse');
  InputParser.parseAndApply(rawInput, workspaceCode);

  print('Phase: Generate');
  File(workspaceCodePath).writeAsStringSync(workspaceCode.generate());

  print('Phase: ReloadSources');
  final report =
      await vm.vmService.reloadSources(executionWorkspaceManager.isolateId);
  if (report.success != true) {
    print('Error: Hot reload failed, maybe because code has syntax error?');
    return;
  }

  print('Phase: Evaluate');
  final isolateInfo = await executionWorkspaceManager.isolateInfo;
  final targetId = isolateInfo.rootLib!.id!;
  final response = await vm.vmService
      .evaluate(executionWorkspaceManager.isolateId, targetId, _evaluateCode);

  _handleEvaluateResponse(response);
}

void _handleEvaluateResponse(Response response) {
  if (response is InstanceRef) {
    final value = response.valueAsString;
    if (value != null && value != 'null') {
      print(value);
    }
  } else if (response is ErrorRef) {
    print('Error: $response');
  } else {
    print('Unknown error (response: $response)');
  }
}
