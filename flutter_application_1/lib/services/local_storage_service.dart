import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  /// 保存先: アプリ専用フォルダ /drawings/{creatureId}/{placementId}.png
  Future<String> saveDrawingPng({
    required String creatureId,
    required String placementId,
    required Uint8List bytes,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/drawings/$creatureId');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final filePath = '${folder.path}/$placementId.png';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return filePath; // ← これをFieldで表示に使う
  }
}
