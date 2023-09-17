import 'dart:io';

import 'package:logging/logging.dart';

Future<void> executeProcess(
  String command, {
  required String workingDirectory,
  required void Function(String) writer,
}) async {
  final logger = Logger('ExecuteProcess');

  logger.info('start `$command` in $workingDirectory');

  final cmd = getCrossPlatformCommand(command);

  final process = await Process.start(
    cmd.executable,
    cmd.arguments,
    workingDirectory: workingDirectory,
    runInShell: true,
  );

  process.stdout.listen((e) => writer(String.fromCharCodes(e)));
  process.stderr.listen((e) => writer('[STDERR] ${String.fromCharCodes(e)}'));

  final exitCode = await process.exitCode;
  logger.info('end exitCode=$exitCode');

  if (exitCode != 0) {
    logger.warning('Process execution failed (exitCode=$exitCode)');
  }
}

Command getCrossPlatformCommand(String command) {
  final String executable;
  final List<String> arguments;
  if (Platform.isWindows) {
    executable = 'cmd';
    arguments = ['/c', command];
  } else {
    executable = '/bin/sh';
    arguments = ['-c', command];
  }

  return Command(
    executable: executable,
    arguments: arguments,
  );
}

class Command {
  final String executable;
  final List<String> arguments;

  Command({required this.executable, required this.arguments});
}
