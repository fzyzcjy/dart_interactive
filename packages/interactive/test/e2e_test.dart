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
    'class extends class',
    () => _body(
      inputs: [
        'class A { int f() => 10; } class B extends A { int f() => 20; }',
        'A().f() + B().f()',
        'class A { int f() => 100; }',
        'A().f() + B().f()',
      ],
      expectOutputs: [
        '30',
        '120',
      ],
    ),
  );

  test(
    'class implements class',
    () => _body(
      inputs: [
        'class A { int f() => 10; } class B implements A { int f() => 20; }',
        'A().f() + B().f()',
        'class A { int f() => 100; }',
        'A().f() + B().f()',
      ],
      expectOutputs: [
        '30',
        '120',
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

  test(
    'function uses local variable',
    () => _body(
      inputs: [
        'int f() { int a = 0; return a++; }',
        'f()',
      ],
      expectOutputs: [
        '0',
      ],
    ),
  );

  test(
    'function uses global variable',
    () => _body(
      inputs: [
        'a = 1;',
        'int f() => a++;',
        'f()',
        'a',
      ],
      expectOutputs: [
        '1',
        '2',
      ],
    ),
  );

  test(
    'class method uses local variable',
    () => _body(
      inputs: [
        'class C { int f() { int a = 10; return a++; } }',
        'C().f()',
      ],
      expectOutputs: [
        '10',
      ],
    ),
  );

  test(
    'class method uses field',
    () => _body(
      inputs: [
        'class C { int a = 10; int f() { return a++; } }',
        'C().f()',
      ],
      expectOutputs: [
        '10',
      ],
    ),
  );

  test(
    'class method uses global variable',
    () => _body(
      inputs: [
        'a = 1;',
        'class C { int f() { var b=a; var c=a+1; a=10; return a++; } }',
        'C().f()',
        'a',
      ],
      expectOutputs: [
        '10',
        '11',
      ],
    ),
  );

  test(
    'Calling undefined getter on self defined class instance should not yield global variable #51',
    () => _body(
      inputs: [
        'a = 1;',
        'class Foo {}',
        'f = Foo();',
        // should not output
        'f.a',
      ],
      expectOutputs: [],
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
    directory: null,
  );
  expect(actualOutputs, expectOutputs);
}
