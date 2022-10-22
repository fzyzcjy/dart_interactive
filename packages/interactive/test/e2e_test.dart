import 'package:interactive/src/main.dart';
import 'package:test/test.dart';

void main() {
  test('simplest',
      () => _body(inputs: ['"hi"', '10+20'], expectOutputs: ['hi', '30']));

  test(
    'read and write variables',
    () => _body(
      inputs: [
        'a = 42; b = "wow";',
        'a++; b += " dart";',
        r'"$a $b"',
      ],
      expectOutputs: ['43 wow dart'],
    ),
  );

  test(
    'define and redefine functions',
    () => _body(
      inputs: [
        'String f() => "old";',
        'a = f();',
        'a',
        'String f() => "new";',
        'a = f();',
        'a',
      ],
      expectOutputs: [
        'old',
        'new',
      ],
    ),
  );

  test(
    'define and redefine class and methods',
    () => _body(
      inputs: [
        'class C { int a = 10; int f() => a * 2; }',
        'c = C();',
        'c.f()',
        'class C { int a = 1000; int f() => a * 3; }',
        'c.f()',
        'C().f()',
      ],
      expectOutputs: [
        '20',
        '30',
        '3000',
      ],
    ),
  );

  test(
    'define multiple classes and methods in one go',
    () => _body(
      inputs: [
        'int g() => 42; class C { int a = 10; int f() => a * 2; }',
        'C().f() + g()',
        'int g() => 4200; class C { int a = 10; int f() => a * 3; }',
        'C().f() + g()',
      ],
      expectOutputs: [
        '62',
        '4230',
      ],
    ),
  );

  test(
    'imports',
    () => _body(
      inputs: [
        // should fail (since not imported)
        'Random().nextInt(1)',

        // first import
        'import "dart:math";',
        'Random().nextInt(1)',

        // import again should be ok
        'import "dart:math";',
        'Random().nextInt(1)',
      ],
      expectOutputs: [
        '0',
        '0',
      ],
    ),
  );
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
