import 'dart:isolate';

import 'package:interactive/src/vm_service_wrapper.dart';
import 'package:collection/collection.dart';

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

    final isolateIdsBefore = await vm.getIsolateIds();

    final isolate = await _spawnUriWithErrorHandling(Uri.file(path));

    final isolateIdsAfter = await vm.getIsolateIds();
    final isolateId = isolateIdsAfter.difference(isolateIdsBefore).single;

    return ExecutionWorkspaceManager._(isolate: isolate, isolateId: isolateId);
  }
}

extension on VmServiceWrapper {
  Future<Set<String>> getIsolateIds() async => (await vmService.getVM())
      .isolates!
      .map((e) => e.id)
      .whereNotNull()
      .toSet();
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
