const kRuntimeSupportCode = r'''
Future<void> main() async {
  while (true) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

class InteractiveRuntimeContext {
  final _fieldMap = <Symbol, Object?>{};

  @override
  Object? noSuchMethod(Invocation invocation) {
    if (invocation.isGetter && _fieldMap.containsKey(invocation.memberName)) {
      return _fieldMap[invocation.memberName];
    }

    if (invocation.isSetter) {
      final name = Symbol(invocation.memberName.name.split('=').first);
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

extension on Symbol {
  static final _nameRegex = RegExp(r'^Symbol\("(.+)"\)$');

  String get name => _nameRegex.firstMatch(toString())!.group(1)!;
}

// used by [execution_workspace], not by code *inside* [interactive]
final interactiveRuntimeContext = InteractiveRuntimeContext();

dynamic synthesizedClassNoSuchMethod(Invocation invocation) =>
    interactiveRuntimeContext.noSuchMethod(invocation);
''';
