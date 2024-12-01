import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

void main() {
  const sourceFilePath = 'lib/view/home/home_view.dart';

  final sourceFile = File(sourceFilePath);
  if (!sourceFile.existsSync()) {
    print('Error: File not found at $sourceFilePath');
    return;
  }

  final sourceContent = sourceFile.readAsStringSync();
  final parseResult = parseString(content: sourceContent, throwIfDiagnostics: false);

  final unit = parseResult.unit;
  final extractedWidgets = <String, String>{};

  for (final declaration in unit.declarations) {
    if (declaration is ClassDeclaration) {
      final widgetName = declaration.name.lexeme;
      final widgetContent = sourceContent.substring(declaration.offset, declaration.end);
      extractedWidgets[widgetName] = widgetContent;
    }
  }

  if (extractedWidgets.isEmpty) {
    print('No widgets found.');
    return;
  }

  const outputDir = 'lib/common_widget';
  final outputDirectory = Directory(outputDir);
  if (!outputDirectory.existsSync()) {
    outputDirectory.createSync(recursive: true);
  }

  extractedWidgets.forEach((widgetName, widgetContent) {
    final fileName = '${_toSnakeCase(widgetName)}.dart';
    final filePath = '$outputDir/$fileName';

    // Writing extracted widget code into separate files
    File(filePath).writeAsStringSync('''
import 'package:flutter/material.dart';

$widgetContent
    ''');

    print('Refactored $widgetName into $filePath');
  });

  print('Refactoring completed.');
}

String _toSnakeCase(String input) {
  return input.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'), (match) => '${match.group(1)}_${match.group(2)}').toLowerCase();
}
