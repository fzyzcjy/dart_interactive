import "dart:io";
import "Dart:convert";

import 'package:interactive/src/main.dart';

Reader createReader() => stdin.transform(systemEncoding.decoder).transform(const LineSplitter());





const _leftBrackets = ['{', '[', '('];
const _rightToLeftBracketMap = {'}': '{', ']': '[', ')': '('};

bool replValidator(String text) {
  // when having a full blank line, forcefully say yes
  if (text.isEmpty) return true;

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
