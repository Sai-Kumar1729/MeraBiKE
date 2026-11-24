import 'package:flutter/services.dart';

/// A folder the owner picked once; the app keeps permission to write to it.
class PickedFolder {
  const PickedFolder({required this.uri, required this.name});

  final String uri;
  final String name;
}

/// Everything the app asks of Android, implemented in MainActivity.kt with no
/// packages: the system Save as / Open dialogs, a backup folder with lasting
/// permission, the share sheet, and the home-screen shortcut.
class AndroidBridge {
  const AndroidBridge();

  static const _channel = MethodChannel('merabike/android');

  /// The "Log refuel" home-screen shortcut.
  static const logRefuelAction = 'logRefuel';

  /// Asks where to save [text]. False if the user cancelled.
  Future<bool> saveAs(String fileName, String text) async =>
      await _channel.invokeMethod<bool>('saveAs', {
        'fileName': fileName,
        'text': text,
      }) ??
      false;

  /// Asks for a file and returns its text, or null if the user cancelled.
  Future<String?> open() => _channel.invokeMethod<String>('open');

  /// Asks for a folder and keeps permission to write there, even after a
  /// restart. Null if the user cancelled.
  Future<PickedFolder?> pickFolder() async {
    final picked = await _channel.invokeMapMethod<String, String>('pickFolder');
    if (picked == null) return null;
    return PickedFolder(uri: picked['uri']!, name: picked['name']!);
  }

  /// File names directly inside the folder.
  Future<List<String>> listFolder(String folderUri) async =>
      await _channel.invokeListMethod<String>('listFolder', {
        'uri': folderUri,
      }) ??
      const [];

  /// Creates or replaces [name] in the folder.
  Future<void> writeToFolder(String folderUri, String name, String text) =>
      _channel.invokeMethod('writeToFolder', {
        'uri': folderUri,
        'name': name,
        'text': text,
      });

  Future<void> deleteFromFolder(String folderUri, String name) => _channel
      .invokeMethod('deleteFromFolder', {'uri': folderUri, 'name': name});

  /// Opens the share sheet with a PNG and a caption.
  Future<void> shareImage(Uint8List png, String text) =>
      _channel.invokeMethod('shareImage', {'png': png, 'text': text});

  /// The shortcut the app was opened from ([logRefuelAction]), once; null
  /// for a normal launch.
  Future<String?> takeLaunchAction() =>
      _channel.invokeMethod<String>('takeLaunchAction');

  /// Calls [onAction] when a shortcut is used while the app is running.
  void onShortcut(void Function(String action) onAction) =>
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'shortcut') onAction(call.arguments as String);
      });
}
