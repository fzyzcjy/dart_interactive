import 'package:cli_repl/cli_repl.dart';

Future<void> runReader(Future<void> Function(String input) handler) async {
  final repl = Repl(prompt: '> ');
  for (final input in repl.run()) {
    if (input.trim().isEmpty) continue;
    await handler(input);
  }
}
