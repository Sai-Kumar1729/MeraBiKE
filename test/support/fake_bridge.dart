import 'package:flutter/services.dart';
import 'package:mera_bike/data/android_bridge.dart';

/// Stands in for MainActivity.kt: a backup folder held in memory.
class FakeBridge extends AndroidBridge {
  FakeBridge();

  static const folderUri = 'content://test/tree/MeraBiKE';

  /// File name → contents in the picked folder.
  final Map<String, String> files = {};

  /// Makes every write fail like a revoked folder permission.
  bool failWrites = false;

  Uint8List? sharedImage;
  String? sharedText;

  @override
  Future<PickedFolder?> pickFolder() async =>
      const PickedFolder(uri: folderUri, name: 'MeraBiKE');

  @override
  Future<List<String>> listFolder(String folderUri) async => [...files.keys];

  @override
  Future<void> writeToFolder(String folderUri, String name, String text) async {
    if (failWrites) {
      throw PlatformException(
        code: 'io',
        message: 'Access to the backup folder was lost. Pick the folder again.',
      );
    }
    files[name] = text;
  }

  @override
  Future<void> deleteFromFolder(String folderUri, String name) async =>
      files.remove(name);

  @override
  Future<void> shareImage(Uint8List png, String text) async {
    sharedImage = png;
    sharedText = text;
  }

  @override
  Future<String?> takeLaunchAction() async => null;

  @override
  void onShortcut(void Function(String action) onAction) {}
}
