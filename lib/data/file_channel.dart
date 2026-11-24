import 'package:flutter/services.dart';

/// Android's own "Save as" and "Open" dialogs (Storage Access Framework),
/// implemented in MainActivity.kt. No packages, and files land wherever the
/// user picks (Downloads, Google Drive, ...), so they survive an uninstall.
class SystemFiles {
  const SystemFiles();

  static const _channel = MethodChannel('merabike/files');

  /// Asks where to save [text]. False if the user cancelled.
  Future<bool> saveAs(String fileName, String text) async =>
      await _channel.invokeMethod<bool>('saveAs', {
        'fileName': fileName,
        'text': text,
      }) ??
      false;

  /// Asks for a file and returns its text, or null if the user cancelled.
  Future<String?> open() => _channel.invokeMethod<String>('open');
}
