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

  test(
    'Print all types of variables without needing print statement #47',
    () => _body(
      inputs: [
        'class Foo {}',
        'Foo()',
      ],
      expectOutputs: [
        // should call toString to that object
        "Instance of 'Foo'",
      ],
    ),
  );

  test(
    'has exit helper method',
    () => _body(
      inputs: [
        // cannot really test executing it - otherwise our test is exited, so only verify
        // the method exists. should test executing it by hand.
        r'"$exit"',
      ],
      expectOutputs: [
        "Closure: () => Never from Function 'exit': static.",
      ],
    ),
  );

  test(
    'package imports',
    () => _bodyCustomExpect(
      inputs: [
        '!dart pub add path:1.8.3',
        '"after pub add"', // Custom split point
        'import "package:path/path.dart";',
        'join("a", "b")',
      ],
      customExpect: (actual) {
        expect(actual.first, 'Resolving dependencies...\n');
        final afterAdd = _getLinesAfter(actual, 'after pub add');

        expect(afterAdd, [
          'a/b',
        ]);
      },
    ),
  );

  test(
    // Test for more "complex" packge dependencies.
    // See here for context: https://github.com/fzyzcjy/dart_interactive/issues/88
    'package imports (_fe_analyzer_shared dependency)',
    () => _bodyCustomExpect(
      inputs: [
        '!dart pub add http:1.0.0',
        '"after pub add"', // Custom split point
        'import "package:http/http.dart";',
        'get', // Display the http get function
        'import "package:async/async.dart" as async_lib;', // Transitive dependency + alias
        'async_lib.AsyncCache', // Display a class from the transitive dependency
      ],
      customExpect: (actual) {
        expect(actual.first, 'Resolving dependencies...\n');
        final afterAdd = _getLinesAfter(actual, 'after pub add');

        expect(afterAdd, [
          "Closure: (Uri, {Map<String, String>? headers}) => Future<Response> from Function 'get': static.",
          'AsyncCache<dynamic>',
        ]);
      },
    ),
  );
}

Future<void> _body({
  required List<String> inputs,
  required List<String> expectOutputs,
}) async {
  final actualOutputs = await _getOutputs(inputs);
  expect(actualOutputs, expectOutputs);
}

/// Useful for tests where we want to ignore certain non-deterministic outputs, like fetching packages,
/// where a transitive dependency may be out of date in the future
Future<void> _bodyCustomExpect({
  required List<String> inputs,
  required void Function(List<String> actual) customExpect,
}) async {
  final actualOutputs = await _getOutputs(inputs);
  customExpect(actualOutputs);
}

Future<List<String>> _getOutputs(List<String> inputs) async {
  final actualOutputs = <String>[];
  await run(
    verbose: true,
    reader: () => inputs,
    writer: actualOutputs.add,
    directory: null,
  );
  return actualOutputs;
}

List<String> _getLinesAfter(List<String> lines, String line) {
  final idx = lines.indexOf(line);
  if (idx == -1) {
    fail('Expected to find $line in $lines');
  }
  if (idx == lines.length - 1) {
    return [];
  }
  return lines.sublist(idx + 1);
}
