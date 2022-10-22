import 'dart:isolate';

class ExecutionWorkspaceManager {
  final Isolate isolate;

  ExecutionWorkspaceManager._(this.isolate);

  static Future<ExecutionWorkspaceManager> create(
      String executionWorkspaceDir) async {
    final path = '$executionWorkspaceDir/lib/main.dart';
    final isolate = await Isolate.spawnUri(Uri.file(path), const [], null);

    return ExecutionWorkspaceManager._(isolate);
  }
}
