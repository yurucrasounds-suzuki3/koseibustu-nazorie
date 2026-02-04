import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AppState extends ChangeNotifier {
  bool ready = false;
  String? uid;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('local_uid');
    if (existing != null && existing.isNotEmpty) {
      uid = existing;
    } else {
      final generated = const Uuid().v4();
      await prefs.setString('local_uid', generated);
      uid = generated;
    }
    ready = true;
    notifyListeners();
  }
}
