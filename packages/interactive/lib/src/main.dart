import 'package:interactive/src/code_generator.dart';
import 'package:interactive/src/execution_workspace_manager.dart';
import 'package:interactive/src/reader.dart';
import 'package:interactive/src/vm_service_wrapper.dart';
import 'package:vm_service/vm_service.dart';

Future<void> main() async {
  // TODO should dynamically generate
  const executionWorkspaceDir =
      '/Users/tom/RefCode/dart_interactive/packages/execution_workspace';

  final vm = await VmServiceWrapper.create();
  final executionWorkspaceManager =
      await ExecutionWorkspaceManager.create(vm, executionWorkspaceDir);
  final codeGenerator = CodeGenerator();

  try {
    await runReader((input) =>
        _handleInput(vm, executionWorkspaceManager, codeGenerator, input));
  } finally {
    vm.dispose();
  }
}

const _evaluateCode = 'interactiveRuntimeContext.generatedMethod()';

Future<void> _handleInput(
  VmServiceWrapper vm,
  ExecutionWorkspaceManager executionWorkspaceManager,
  CodeGenerator codeGenerator,
  String rawInput,
) async {
  print('Phase: Generate');
  codeGenerator.generate(rawInput);

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
