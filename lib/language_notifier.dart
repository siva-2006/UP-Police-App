// lib/language_notifier.dart
import 'package:flutter/material.dart';

class LanguageNotifier extends ChangeNotifier {
  bool _isHindi = false;

  bool get isHindi => _isHindi;

  void toggleLanguage() {
    _isHindi = !_isHindi;
    notifyListeners();
  }
}