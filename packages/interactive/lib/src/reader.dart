import 'package:cli_repl/cli_repl.dart';

abstract class Reader {
  Future<void> run(Future<void> Function(String input) handler);
}

class ReplReader {
  Future<void> run(Future<void> Function(String input) handler) async {
    final repl = Repl(prompt: '>>> ');
    for (final input in repl.run()) {
      if (input.trim().isEmpty) continue;
      await handler(input);
    }
  }
}

class TestReader {
  final List<String> inputs;

  TestReader(this.inputs);

  Future<void> run(Future<void> Function(String input) handler) async {
    for (final input in inputs) {
      print('>>> $input');
      await handler(input);
    }
  }
}
