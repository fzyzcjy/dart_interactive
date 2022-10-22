const kRuntimeSupportImport = '''
import 'dart:mirrors';
''';

const kRuntimeSupportCode = r'''
Future<void> main() async =>
    await Future<void>.delayed(const Duration(days: 1000));

class InteractiveRuntimeContext {
  final _fieldMap = <Symbol, Object?>{};

  @override
  Object? noSuchMethod(Invocation invocation) {
    if (invocation.isGetter && _fieldMap.containsKey(invocation.memberName)) {
      return _fieldMap[invocation.memberName];
    }

    if (invocation.isSetter) {
      final name = MirrorSystem.getSymbol(
          MirrorSystem.getName(invocation.memberName).split('=').first);
      _fieldMap[name] = invocation.positionalArguments.single;
      return null;
    }

    if (invocation.isMethod && _fieldMap.containsKey(invocation.memberName)) {
      return Function.apply(_fieldMap[invocation.memberName]! as Function,
          invocation.positionalArguments, invocation.namedArguments);
    }

    return super.noSuchMethod(invocation);
  }

  @override
  String toString() => 'InteractiveRuntimeContext(fieldMap: $_fieldMap)';
}

// used by [execution_workspace], not by code *inside* [interactive]
final interactiveRuntimeContext = InteractiveRuntimeContext();

dynamic synthesizedClassNoSuchMethod(Invocation invocation) =>
    interactiveRuntimeContext.noSuchMethod(invocation);
''';
