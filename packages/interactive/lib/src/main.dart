
import 'package:args/args.dart';
import 'package:interactive/src/executor.dart';
import 'package:interactive/src/reader.dart';
import 'package:logging/logging.dart';

// TODO should dynamically generate and do not hardcode path...
const executionWorkspaceDir =
    '/Users/tom/RefCode/dart_interactive/packages/execution_workspace';

Future<void> main(List<String> args) {
  final parsedArgs = (ArgParser() //
        ..addFlag('verbose', defaultsTo: false))
      .parse(args);

  return run(
    reader: ReplReader(),
    verbose: parsedArgs['verbose'] as bool,
  );
}

Future<void> run({
  required bool verbose,
  required BaseReader reader,
}) async {
  _setUpLogging(verbose ? Level.ALL : Level.WARNING);

  final executor = await Executor.create();
  try {
    await reader.run(executor.execute);
  } finally {
    executor.dispose();
  }
}

void _setUpLogging(Level level) {
  Logger.root
    ..level = level
    ..onRecord.listen((record) =>
        print('[${record.level.name} ${record.time}] ${record.message}'));
}
