import 'dart:io';
import "dart:convert";
import 'package:logging/logging.dart';

Future<void> executeProcess(
  String command, {
  required String workingDirectory,
  required void Function(String) writer,
}) async {
  final logger = Logger('ExecuteProcess');

  logger.info('start `$command` in $workingDirectory');
  final process = await Process.start(
    command,
    [], // don't bother splitting up the commands since we're passing it to the platforms command shell, it'll do it for us
    workingDirectory: workingDirectory,
    runInShell: true,
  );

  process.stdout.transform(systemEncoding.decoder).listen((e) => writer(e));
  process.stderr.transform(systemEncoding.decoder).listen((e) => writer('[STDERR] ${e}'));

  final exitCode = await process.exitCode;
  logger.info('end exitCode=$exitCode');

  if (exitCode != 0) {
    logger.warning('Process execution failed (exitCode=$exitCode)');
  }
}
