import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps lib/engine/ pure Dart: no Flutter, no I/O, no packages.
void main() {
  test('lib/engine imports only core dart: libraries and its own files', () {
    const allowed = {
      'dart:async',
      'dart:collection',
      'dart:convert',
      'dart:math',
      'dart:typed_data',
    };
    final directive = RegExp(
      r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
      multiLine: true,
    );
    final files = Directory('lib/engine')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    expect(files, isNotEmpty);
    for (final file in files) {
      for (final match in directive.allMatches(file.readAsStringSync())) {
        final uri = match.group(1)!;
        final isOwnFile = !uri.contains(':');
        expect(
          isOwnFile || allowed.contains(uri),
          isTrue,
          reason: '${file.path} imports $uri',
        );
      }
    }
  });
}
