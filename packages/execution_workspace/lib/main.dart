import 'workspace.dart'; // ignore: unused_import
export 'workspace.dart';

Future<void> main() async {
  print('execution_workspace::main called and sleep');
  await Future.delayed(const Duration(days: 1000));
}
