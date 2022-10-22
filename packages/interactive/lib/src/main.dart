import 'package:interactive/src/execution_workspace_manager.dart';
import 'package:interactive/src/reader.dart';
import 'package:interactive/src/vm_service_wrapper.dart';

Future<void> main() async {
  // TODO should dynamically generate
  const executionWorkspaceDir =
      '/Users/tom/RefCode/dart_interactive/packages/execution_workspace';

  final vm = await VmServiceWrapper.create();
  final executionWorkspaceManager =
      await ExecutionWorkspaceManager.create(executionWorkspaceDir);

  try {
    await runReader(
        (input) => _handleInput(vm, executionWorkspaceManager, input));
  } finally {
    vm.dispose();
  }
}

Future<void> _handleInput(
  VmServiceWrapper vm,
  ExecutionWorkspaceManager executionWorkspaceManager,
  String rawInput,
) async {
  final evaluateCode = TODO;

  await vm.vmService.evaluate(
      vm.isolateId, executionWorkspaceManager.isolateId, evaluateCode);
}
