import "dart:async";
import 'dart:io';

import 'package:args/args.dart';
import 'package:interactive/src/executor.dart';
import 'package:interactive/src/reader.dart';
import 'package:interactive/src/workspace_file_tree.dart';
import 'package:logging/logging.dart';

Future<void> main(List<String> args) {
  final parsedArgs = _parseArgs(args);

  return run(
    reader: createReader(),
    writer: print,
    directory: parsedArgs['directory'] as String?,
    verbose: parsedArgs['verbose'] as bool,
  );
}

ArgResults _parseArgs(List<String> args) {
  final parser = ArgParser()
    ..addFlag('verbose', defaultsTo: false, help: 'More logging')
    ..addOption('directory', abbr: 'd', help: 'Working directory')
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

typedef Reader = Stream<String>;
typedef Writer = void Function(String);

Future<void> run({
  required bool verbose,
  required Reader reader,
  required Writer writer,
  required String? directory,
}) async {
  _setUpLogging(verbose ? Level.ALL : Level.WARNING);

  final workspaceFileTree = await WorkspaceFileTree.create(
      directory ?? await WorkspaceFileTree.getTempDirectory());

  final executor =
      await Executor.create(writer, workspaceFileTree: workspaceFileTree);
  const prompt = ">>>";
  const continuation = "...";
  try {
    final statement = StringBuffer();
    // we can't just do await for(final line in reader) because we need to print the prompt / continuation before the line the user is typing, not after the line has already been inputted
    final iter = StreamIterator(reader);
    while(true) {
      stdout.write(statement.isEmpty ? prompt : continuation);
      if(!await iter.moveNext()) {
        break;
      }
      final line = iter.current;
      statement.writeln(line);
      if (replValidator(statement.toString())) {
        await executor.execute(statement.toString());
        statement.clear();
      } else {
        statement.writeln();
      }
    }
    print("Done");
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
