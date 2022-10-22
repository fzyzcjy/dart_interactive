import 'package:cli_repl/cli_repl.dart';
import 'package:interactive/src/main.dart';

Reader createReader() => Repl(prompt: '>>> ', validator: replValidator).run;

const _leftBrackets = ['{', '[', '('];
const _rightToLeftBracketMap = {'}': '{', ']': '[', ')': '('};

bool replValidator(String text) {
  final stack = <String>[];
  for (var i = 0; i < text.length; ++i) {
    final ch = text[i];
    if (_leftBrackets.contains(ch)) {
      stack.add(ch);
    } else if (_rightToLeftBracketMap.containsKey(ch)) {
      // not check matching pairs currently, since user can
      // input a wrong grammar
      if (stack.isNotEmpty) stack.removeLast();
    }
  }

  return stack.isEmpty;
}
