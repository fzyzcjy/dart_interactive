import 'dart:io';

// this file should have at few imports as possible to speed up booting
Future<void> main(List<String> rawArgs) async {
  final executable = Platform.executable;
  final arguments = ['--enable-vm-service', _interactiveRawScript, ...rawArgs];

  print('Run: $executable $arguments');
  final process = await Process.start(executable, arguments,
      mode: ProcessStartMode.inheritStdio);
  final innerExitCode = await process.exitCode;
  exit(innerExitCode);
}

// ref: https://github.com/dart-lang/pub/issues/3291
String get _interactiveRawScript {
  const kReplaceSrc = 'interactive.dart';
  const kReplaceDst = 'interactive_raw.dart';

  final self = Platform.script.toString();
  if (!self.contains(kReplaceSrc)) {
    throw AssertionError(
        'self=$self does not contain $kReplaceSrc, please create an issue');
  }
  return self.replaceAll(kReplaceSrc, kReplaceDst);
}
