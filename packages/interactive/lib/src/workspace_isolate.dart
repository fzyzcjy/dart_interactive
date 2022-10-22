import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:interactive/src/vm_service_wrapper.dart';
import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

class WorkspaceIsolate {
  final VmServiceWrapper vm;
  final Isolate isolate;
  final String isolateId;

  WorkspaceIsolate._({
    required this.vm,
    required this.isolate,
    required this.isolateId,
  });

  static Future<WorkspaceIsolate> create(
      VmServiceWrapper vm, String executionWorkspaceDir) async {
    final path = '$executionWorkspaceDir/lib/auto_generated.dart';

    final isolateIdsBefore = await vm.getIsolateIds();

    final isolate = await _spawnUriWithErrorHandling(Uri.file(path));

    final isolateIdsAfter = await vm.getIsolateIds();
    final isolateId = isolateIdsAfter.difference(isolateIdsBefore).single;

    return WorkspaceIsolate._(vm: vm, isolate: isolate, isolateId: isolateId);
  }

  Future<vm_service.Isolate> get isolateInfo =>
      vm.vmService.getIsolate(isolateId);

  void dispose() {
    isolate.kill(priority: Isolate.immediate);
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
  final log = Logger('SpawnUriWithErrorHandling');

  final errorPort = RawReceivePort()
    ..handler = (Object? message) => log.warning('Isolate error: $message');
  final exitPort = RawReceivePort()
    ..handler =
        (Object? message) => log.warning('Isolate exited (message: $message)');

  return await Isolate.spawnUri(
    uri,
    const [],
    null,
    onError: errorPort.sendPort,
    onExit: exitPort.sendPort,
  );
}
