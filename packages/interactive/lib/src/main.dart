import 'dart:io';

import 'package:args/args.dart';
import 'package:cli_repl/cli_repl.dart';
import 'package:interactive/src/executor.dart';
import 'package:interactive/src/reader.dart';
import 'package:interactive/src/workspace_file_tree.dart';
import 'package:logging/logging.dart';

Future<void> main(List<String> args) {
  final parsedArgs = _parseArgs(args);

  return run(
    reader: createReader(),
    writer: print,
    verbose: parsedArgs['verbose'] as bool,
  );
}

ArgResults _parseArgs(List<String> args) {
  final parser = ArgParser()
    ..addFlag('verbose', defaultsTo: false, help: 'More logging')
    ..addFlag('help', defaultsTo: false, help: 'Show help message');

  String usage() => 'Arguments:\n${parser.usage}';

  final ArgResults parsedArgs;
  try {
    parsedArgs = parser.parse(args);
  } on Exception {
    print(usage());
    rethrow;
  }

  if (parsedArgs['help'] as bool) {
    print(usage());
    exit(0);
  }

  return parsedArgs;
}

typedef Reader = Iterable<String> Function();
typedef Writer = void Function(String);

Future<void> run({
  required bool verbose,
  required Reader reader,
  required Writer writer,
}) async {
  _setUpLogging(verbose ? Level.ALL : Level.WARNING);

  final workspaceFileTree = await WorkspaceFileTree.create();

  final executor =
      await Executor.create(writer, workspaceFileTree: workspaceFileTree);
  try {
    for (final input in reader()) {
      await executor.execute(input);
    }
  } finally {
    executor.dispose();
    workspaceFileTree.dispose();
  }
}

void _setUpLogging(Level level) {
  Logger.root
    ..level = level
    ..onRecord.listen((record) =>
        print('[${record.level.name} ${record.time}] ${record.message}'));
}
