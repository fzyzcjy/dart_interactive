import 'package:interactive/src/reader.dart';
import 'package:test/test.dart';

void main() {
  test('replValidator', () {
    expect(replValidator('a = 1'), true);
    expect(replValidator('f()'), true);
    expect(replValidator('f(g())'), true);
    expect(replValidator('void f() {}'), true);
    expect(replValidator('a[1]'), true);

    expect(replValidator('f('), false);
    expect(replValidator('f(g('), false);
    expect(replValidator('f(g()'), false);
    expect(replValidator('void f() {'), false);
    expect(replValidator('a[1'), false);

    expect(replValidator('a[1\n'), true);
  });
}
