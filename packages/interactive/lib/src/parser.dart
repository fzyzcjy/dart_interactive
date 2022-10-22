// ignore_for_file: implementation_imports

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:interactive/src/workspace_code.dart';
import 'package:logging/logging.dart';

class InputParser {
  final log = Logger('InputParser');

  WorkspaceCode? parse(String rawCode) {
    final compilationUnit = _tryParse(
        rawCode, (parser, token) => parser.parseCompilationUnit(token));
    if (compilationUnit != null) {
      // #16
      if (compilationUnit.declarations
          .whereType<TopLevelVariableDeclaration>()
          .isNotEmpty) {
        log.warning('Please use `a=1` instead of `var a=1`');
        return null;
      }

      final classMap = <String, ClassInfo>{};
      final functionMap = <String, String>{};
      final miscDeclarationMap = <String, String>{};
      for (final declaration in compilationUnit.declarations) {
        final identifier = declaration.identifier;
        if (declaration is ClassDeclaration) {
          classMap[identifier] = ClassInfo(
            rawCode: declaration.getCode(rawCode),
            potentialAccessors:
                _PotentialAccessorParser().parseClassDeclaration(declaration),
          );
        } else if (declaration is FunctionDeclaration) {
          functionMap[identifier] = declaration.getCode(rawCode);
        } else {
          miscDeclarationMap[identifier] = declaration.getCode(rawCode);
        }
      }

      final imports = compilationUnit.directives
          .whereType<ImportDirective>()
          .map((e) => e.getCode(rawCode))
          .toSet();

      log.info('parse return via compilationUnit');
      return WorkspaceCode(
        classMap: classMap,
        functionMap: functionMap,
        miscDeclarationMap: miscDeclarationMap,
        imports: imports,
        generatedMethodCodeBlock: '',
      );
    }

    final expression =
        _tryParse(rawCode, (parser, token) => parser.parseExpression(token));
    if (expression != null) {
      log.info('parse return via expression');
      return WorkspaceCode.codeBlock(
        generatedMethodCodeBlock: 'return ($rawCode) as dynamic;',
      );
    }

    // fallback as raw code
    log.info('parse return via raw code');
    return WorkspaceCode.codeBlock(
      generatedMethodCodeBlock: rawCode,
    );
  }
}

typedef ParserClosure<T extends AstNode> = T Function(
    Parser parser, Token token);

// ref: https://github.com/BlackHC/dart_repl/blob/ad568604f41be31fbc8d809d5e0cfa25a6cd5601/lib/src/cell_type.dart#L18
T? _tryParse<T extends AstNode>(String code, ParserClosure<T> parse) {
  final reader = CharSequenceReader(code);
  final errorListener = _LoggingErrorListener();
  final featureSet = FeatureSet.latestLanguageVersion();
  final scanner = Scanner(StringSource(code, ''), reader, errorListener)
    ..configureFeatures(
        featureSetForOverriding: featureSet, featureSet: featureSet);
  final token = scanner.tokenize();
  final parser = Parser(StringSource(code, ''), errorListener,
      featureSet: featureSet, lineInfo: LineInfo.fromContent(code));

  final result = parse(parser, token);

  if (errorListener.errorReported ||
      result.endToken.next?.type != TokenType.EOF) {
    return null;
  }

  return result;
}

// TODO change to gather it etc
class _LoggingErrorListener extends BooleanErrorListener {
  final log = Logger('LoggingErrorListener');

  @override
  void onError(AnalysisError error) {
    super.onError(error);
    log.info('Error when parsing: $error');
  }
}

extension on AstNode {
  String getCode(String fullCode) =>
      fullCode.substring(offset, offset + length);
}

extension on CompilationUnitMember {
  String get identifier {
    final that = this;
    if (that is NamedCompilationUnitMember) return '$runtimeType#${that.name}';
    throw UnimplementedError(
        'Not implemented identifier for $runtimeType yet, please make a PR');
  }
}

class _PotentialAccessorParser {
  static final log = Logger('PotentialAccessorParser');

  Set<String> parseClassDeclaration(ClassDeclaration value) {
    final visitor = _PotentialAccessorVisitor();
    value.visitChildren(visitor);
    final potentialAccessors = visitor.potentialAccessors;
    final fieldNames = _parseFieldNames(value);
    log.info(
        'parseClassDeclaration potentialAccessors=$potentialAccessors fieldNames=$fieldNames');
    return potentialAccessors.difference(fieldNames);
  }

  Set<String> _parseFieldNames(ClassDeclaration value) => value.members
      .whereType<FieldDeclaration>()
      .expand((e) => e.fields.variables)
      .map((e) => e.name.toString())
      .toSet();
}

class _PotentialAccessorVisitor extends GeneralizingAstVisitor<void> {
  static final log = Logger('PotentialAccessorVisitor');

  final potentialAccessors = <String>{};

  @override
  void visitExpression(Expression node) {
    log.warning('expression of type ${node.runtimeType} not implemented yet '
        '(should be quite trivial - not implemented simply because I never see it in tests), '
        'please raise issue or PR. node=$node');
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _visitPotentialAccessor(node.leftOperand);
    _visitPotentialAccessor(node.rightOperand);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _visitPotentialAccessor(node.leftHandSide);
    _visitPotentialAccessor(node.rightHandSide);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _visitPotentialAccessor(node.operand);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _visitPotentialAccessor(node.operand);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // nothing
  }

  @override
  void visitLiteral(Literal node) {
    // nothing
  }

  void _visitPotentialAccessor(Expression node) {
    if (node is SimpleIdentifier) {
      potentialAccessors.add(node.name);
    }
  }
}
