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

    final isolateIdsBefore =
        vm.vm.isolates!.map((e) => e.id).whereNotNull().toSet();

    final isolate = await _spawnUriWithErrorHandling(Uri.file(path));

    while (true) {
      print('isolates=${vm.vm.isolates}');
      final isolateIdsAfter =
          vm.vm.isolates!.map((e) => e.id).whereNotNull().toSet();
      final isolateId =
          isolateIdsAfter.difference(isolateIdsBefore).singleOrNull;

      if (isolateId != null) {
        return ExecutionWorkspaceManager._(
            isolate: isolate, isolateId: isolateId);
      }
      
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
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
