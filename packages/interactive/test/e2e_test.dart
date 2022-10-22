import 'package:interactive/src/main.dart';
import 'package:test/test.dart';

void main() {
  test(
      'simplest', () => _body(inputs: ['"hi"'], expectOutputs: ['hi']));
}

Future<void> _body({
  required List<String> inputs,
  required List<String> expectOutputs,
}) async {
  final actualOutputs = <String>[];
  await run(
    verbose: true,
    reader: () => inputs,
    writer: actualOutputs.add,
  );
  expect(actualOutputs, expectOutputs);
}
