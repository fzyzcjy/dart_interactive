// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:interactive/src/workspace_code.dart';
import 'package:logging/logging.dart';
import 'package:pub_semver/pub_semver.dart';

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
            potentialAccessors: _PotentialAccessorParser()
                .parseClassDeclaration(declaration as ClassDeclaration),
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

    final expression = _tryParse(rawCode, parseExpression);
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

  Expression parseExpression(Parser parser, Token token) {
    parser.fastaParser
        .parseExpression(parser.fastaParser.syntheticPreviousToken(token))
        .next!;
    return parser.astBuilder.pop()! as Expression;
  }
}

typedef ParserClosure<T extends AstNode> = T Function(
    Parser parser, Token token);

// ref: https://github.com/BlackHC/dart_repl/blob/ad568604f41be31fbc8d809d5e0cfa25a6cd5601/lib/src/cell_type.dart#L18
T? _tryParse<T extends AstNode>(String code, ParserClosure<T> parse) {
  final source = StringSource(code, '');
  final diagnosticsListener = _LoggingDiagnosticsListener();
  final reporter = DiagnosticReporter(diagnosticsListener, source);
  final featureSet = FeatureSet.latestLanguageVersion();
  final scanner = Scanner(inputText: code, reportError: reporter.report)
    ..configureFeatures(
        featureSetForOverriding: featureSet, featureSet: featureSet);
  final token = scanner.tokenize();
  // actual version via sem ver is before the first space. so, we leverage the runtime's version, ignoring override currently.
  final languageVersionViaRuntime = Platform.version.split(' ').first;

  final parser = Parser(reporter,
      featureSet: featureSet,
      lineInfo: LineInfo.fromContent(code),
      languageVersion: LibraryLanguageVersion(
          package: Version.parse(languageVersionViaRuntime), override: null));

  final result = parse(parser, token);

  if (diagnosticsListener.errorReported ||
      result.endToken.next?.type != TokenType.EOF) {
    return null;
  }

  return result;
}

// TODO change to gather it etc
class _LoggingDiagnosticsListener extends BooleanDiagnosticListener {
  final log = Logger('LoggingDiagnosticsListener');

  @override
  void onDiagnostic(Diagnostic diagnostic) {
    super.onDiagnostic(diagnostic);
    log.info('Error when parsing: $diagnostic');
  }
}

extension on AstNode {
  String getCode(String fullCode) =>
      fullCode.substring(offset, offset + length);
}

extension on CompilationUnitMember {
  String get identifier {
    final that = this;

    return switch (that) {
      ClassDeclaration() => '$runtimeType#${that.namePart}',
      EnumDeclaration() => '$runtimeType#${that.namePart}',
      FunctionDeclaration() => '$runtimeType#${that.name}',
      MixinDeclaration() => '$runtimeType#${that.name}',
      TypeAlias() => '$runtimeType#${that.name}',
      CompilationUnitMember() => throw UnimplementedError(),
    };
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

  Set<String> _parseFieldNames(ClassDeclaration value) => value.body.members
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
