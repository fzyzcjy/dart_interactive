import 'dart:io';

import 'package:collection/collection.dart';
import 'package:interactive/src/main.dart' as lib_main;

// ref: https://github.com/dart-lang/pub/issues/3291#issuecomment-1019880145
Future<void> main(List<String> rawArgs) async {
  if (rawArgs.firstOrNull == _vmServiceWasEnabledArg) {
    await lib_main.main(rawArgs.skip(1).toList());
  } else {
    await _runWithEnableVmService(rawArgs);
  }
}

Future<int> _getUnusedPort() async {
  final socket = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<void> _runWithEnableVmService(List<String> rawArgs) async {
  final executable = Platform.executable;
  final arguments = [
    '--enable-vm-service=${await _getUnusedPort()}',
    Platform.script.toString(),
    _vmServiceWasEnabledArg,
    ...rawArgs
  ];

  print('Run: $executable $arguments');
  final process = await Process.start(executable, arguments,
      mode: ProcessStartMode.inheritStdio);
  final innerExitCode = await process.exitCode;
  exit(innerExitCode);
}

const _vmServiceWasEnabledArg = '--vm-service-was-enabled';
