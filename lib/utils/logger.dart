class Logger {
  static bool _enabled = true;

  static void enable() => _enabled = true;
  static void disable() => _enabled = false;

  static void info(String message) {
    if (_enabled) {
      // ignore: avoid_print
      print('ℹ️ INFO: $message');
    }
  }

  static void error(String message) {
    if (_enabled) {
      // ignore: avoid_print
      print('❌ ERROR: $message');
    }
  }

  static void warning(String message) {
    if (_enabled) {
      // ignore: avoid_print
      print('⚠️ WARNING: $message');
    }
  }

  static void success(String message) {
    if (_enabled) {
      // ignore: avoid_print
      print('✅ SUCCESS: $message');
    }
  }
}