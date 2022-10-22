import 'package:cli_repl/cli_repl.dart';

abstract class BaseReader {
  Future<void> run(Future<void> Function(String input) handler);
}

class ReplReader extends BaseReader {
  @override
  Future<void> run(Future<void> Function(String input) handler) async {
    final repl = Repl(prompt: '>>> ');
    for (final input in repl.run()) {
      if (input.trim().isEmpty) continue;
      await handler(input);
    }
  }
}

class TestReader extends BaseReader {
  final List<String> inputs;

  TestReader(this.inputs);

  @override
  Future<void> run(Future<void> Function(String input) handler) async {
    for (final input in inputs) {
      print('>>> $input');
      await handler(input);
    }
  }
}
