import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AppState extends ChangeNotifier {
  final auth = AuthService();
  bool ready = false;

  Future<void> bootstrap() async {
    await auth.signInAnonymouslyIfNeeded();
    ready = true;
    notifyListeners();
  }
}
