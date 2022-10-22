import 'dart:io';

import 'package:args/args.dart';
import 'package:interactive/src/parser.dart';
import 'package:interactive/src/reader.dart';
import 'package:interactive/src/vm_service_wrapper.dart';
import 'package:interactive/src/workspace_code.dart';
import 'package:interactive/src/workspace_isolate.dart';
import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart';

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

  final vm = await VmServiceWrapper.create();
  final executionWorkspaceManager =
      await WorkspaceIsolate.create(vm, executionWorkspaceDir);
  final workspaceCode = WorkspaceCode();

  try {
    await reader.run((input) =>
        _executeOne(vm, executionWorkspaceManager, workspaceCode, input));
  } finally {
    vm.dispose();
  }
}

const _evaluateCode = 'interactiveRuntimeContext.generatedMethod()';

Future<void> _executeOne(
  VmServiceWrapper vm,
  WorkspaceIsolate executionWorkspaceManager,
  WorkspaceCode workspaceCode,
  String rawInput,
) async {
  print('Phase: Parse');
  InputParser.parseAndApply(rawInput, workspaceCode);

  print('Phase: Generate');
  File('$executionWorkspaceDir/lib/auto_generated.dart')
      .writeAsStringSync(workspaceCode.generate());

  print('Phase: ReloadSources');
  final report =
      await vm.vmService.reloadSources(executionWorkspaceManager.isolateId);
  if (report.success != true) {
    print('Error: Hot reload failed, maybe because code has syntax error?');
    return;
  }

  print('Phase: Evaluate');
  final isolateInfo = await executionWorkspaceManager.isolateInfo;
  final targetId = isolateInfo.rootLib!.id!;
  final response = await vm.vmService
      .evaluate(executionWorkspaceManager.isolateId, targetId, _evaluateCode);

  _handleEvaluateResponse(response);
}

void _handleEvaluateResponse(Response response) {
  if (response is InstanceRef) {
    final value = response.valueAsString;
    if (value != null && value != 'null') {
      print(value);
    }
  } else if (response is ErrorRef) {
    print('Error: $response');
  } else {
    print('Unknown error (response: $response)');
  }
}

void _setUpLogging(Level level) {
  Logger.root
    ..level = level
    ..onRecord.listen((record) =>
        print('[${record.level.name} ${record.time}] ${record.message}'));
}
