import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalDbService {
  Future<File> _fieldFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/field_default.json');
  }

  Future<Map<String, dynamic>> _readJson() async {
    final file = await _fieldFile();
    if (!await file.exists()) {
      // 初期データ
      final init = {
        "bgType": "sea",
        "placements": [],
      };
      await file.writeAsString(jsonEncode(init), flush: true);
      return init;
    }
    final txt = await file.readAsString();
    return jsonDecode(txt) as Map<String, dynamic>;
  }

  Future<void> _writeJson(Map<String, dynamic> data) async {
    final file = await _fieldFile();
    await file.writeAsString(jsonEncode(data), flush: true);
  }

  /// placements一覧取得
  Future<List<Map<String, dynamic>>> loadPlacements() async {
    final data = await _readJson();
    final list = (data["placements"] as List).cast<Map<String, dynamic>>();
    // zIndex順に並べる
    list.sort((a, b) => (a["zIndex"] as int).compareTo(b["zIndex"] as int));
    return list;
  }

  /// placement追加
  Future<void> addPlacement(Map<String, dynamic> placement) async {
    final data = await _readJson();
    final list = (data["placements"] as List).cast<dynamic>();
    list.add(placement);
    data["placements"] = list;
    await _writeJson(data);
  }

  /// placement更新（x,y,scale,rotationなど）
  Future<void> updatePlacement(String id, Map<String, dynamic> patch) async {
    final data = await _readJson();
    final list = (data["placements"] as List).cast<dynamic>();

    for (int i = 0; i < list.length; i++) {
      final p = (list[i] as Map).cast<String, dynamic>();
      if (p["id"] == id) {
        p.addAll(patch);
        list[i] = p;
        break;
      }
    }
    data["placements"] = list;
    await _writeJson(data);
  }
}
