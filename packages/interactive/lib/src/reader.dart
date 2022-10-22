import 'package:cli_repl/cli_repl.dart';
import 'package:interactive/src/main.dart';

Reader createReader() => Repl(prompt: '>>> ', validator: replValidator).run;

bool replValidator(String text) {
  return TODO;
}
