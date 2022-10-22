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

    final isolate = _spawnUriWithErrorHandling(Uri.file(path));

    final isolateIdsAfter = vm.vm.isolates!.map((e) => e.id).toSet();
    print('isolateIdsAfter=$isolateIdsAfter');
    final isolateId = isolateIdsAfter.difference(isolateIdsBefore).single!;

    return ExecutionWorkspaceManager._(isolate: isolate, isolateId: isolateId);
  }
}

// ref: [Isolate.run]
Future<Isolate> _spawnUriWithErrorHandling(Uri uri) async {
  final errorPort = RawReceivePort()
    ..handler = (Object? message) => print('Isolate error: $message');
  final exitPort = RawReceivePort()
    ..handler =
        (Object? message) => print('Isolate exited (message: $message)');

  return await Isolate.spawnUri(
    uri,
    const [],
    null,
    onError: errorPort.sendPort,
    onExit: exitPort.sendPort,
  );
}
