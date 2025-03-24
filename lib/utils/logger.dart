import 'package:flutter/foundation.dart';

class Logger {
  static bool _enabled = true;

  static void enable() => _enabled = true;
  static void disable() => _enabled = false;

  static void info(String message) {
    if (_enabled) {
      debugPrint('ℹ️ INFO: $message');
    }
  }

  static void error(String message) {
    if (_enabled) {
      debugPrint('❌ ERROR: $message');
    }
  }

  static void warning(String message) {
    if (_enabled) {
      debugPrint('⚠️ WARNING: $message');
    }
  }

  static void success(String message) {
    if (_enabled) {
      debugPrint('✅ SUCCESS: $message');
    }
  }
}