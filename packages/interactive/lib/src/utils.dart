import 'dart:io';

import 'package:logging/logging.dart';

Future<void> executeProcess(String command,
    {required String workingDirectory}) async {
  final logger = Logger('ExecuteProcess');

  logger.info('start `$command` in $workingDirectory');

  final process = await Process.start(
    command,
    const [],
    workingDirectory: workingDirectory,
    runInShell: true,
  );

  process.stdout.listen((e) => logger.info(String.fromCharCodes(e)));
  process.stderr
      .listen((e) => logger.warning('[STDERR] ${String.fromCharCodes(e)}'));

  final exitCode = await process.exitCode;
  logger.info('end exitCode=$exitCode');

  if (exitCode != 0) {
    throw Exception('Process execution failed (exitCode=$exitCode)');
  }
}
