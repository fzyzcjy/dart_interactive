import 'dart:mirrors';

Future<void> executionWorkspaceMain() async {
  print('executionWorkspaceMain called and sleep');
  await Future<void>.delayed(const Duration(days: 1000));
}

class InteractiveRuntimeContext {
  final _fieldMap = <Symbol, Object?>{};

  @override
  Object? noSuchMethod(Invocation invocation) {
    // print(
    //     'InteractiveRuntimeContext.noSuchMethod memberName=${invocation.memberName} positionalArguments=${invocation.positionalArguments} namedArguments=${invocation.namedArguments}');

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

// convenient name for repl
// notice this "dynamic" - otherwise cannot access fields
final dynamic $ = interactiveRuntimeContext;

dynamic synthesizedClassNoSuchMethod(Invocation invocation) =>
    interactiveRuntimeContext.noSuchMethod(invocation);
