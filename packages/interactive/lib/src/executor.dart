import 'dart:io';

import 'package:interactive/src/main.dart';
import 'package:interactive/src/parser.dart';
import 'package:interactive/src/vm_service_wrapper.dart';
import 'package:interactive/src/workspace_code.dart';
import 'package:interactive/src/workspace_isolate.dart';
import 'package:vm_service/vm_service.dart';

class Executor {
  static const _evaluateCode = 'interactiveRuntimeContext.generatedMethod()';

  final VmServiceWrapper vm;
  final WorkspaceIsolate executionWorkspaceManager;
  final WorkspaceCode workspaceCode;

  Executor._(this.vm, this.executionWorkspaceManager, this.workspaceCode);

  static Future<Executor> create() async {
    final vm = await VmServiceWrapper.create();
    final executionWorkspaceManager =
        await WorkspaceIsolate.create(vm, executionWorkspaceDir);
    final workspaceCode = WorkspaceCode();

    return Executor._(vm, executionWorkspaceManager, workspaceCode);
  }

  void dispose() {
    vm.dispose();
  }

  Future<void> execute(
    String rawInput,
  ) async {
    print('Phase: Parse');
    InputParser.parseAndApply(rawInput, workspaceCode);

    print('Phase: Generate');
    File('$executionWorkspaceDir/lib/auto_generated.dart')
        .writeAsStringSync(workspaceCode.generate());

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
}
