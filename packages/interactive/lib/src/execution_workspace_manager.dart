import 'dart:isolate';

import 'package:interactive/src/vm_service_wrapper.dart';

class ExecutionWorkspaceManager {
  final Isolate isolate;
  final String isolateId;

  ExecutionWorkspaceManager._({
    required this.isolate,
    required this.isolateId,
  });

  static Future<ExecutionWorkspaceManager> create(
      VmServiceWrapper vm, String executionWorkspaceDir) async {
    final path = '$executionWorkspaceDir/lib/main.dart';

    final isolateIdsBefore = vm.vm.isolates!.map((e) => e.id).toSet();

    final isolate = await Isolate.spawnUri(Uri.file(path), const [], null);

    final isolateIdsAfter = vm.vm.isolates!.map((e) => e.id).toSet();
    final isolateId = isolateIdsAfter.difference(isolateIdsBefore).single!;

    return ExecutionWorkspaceManager._(isolate: isolate, isolateId: isolateId);
  }
}
