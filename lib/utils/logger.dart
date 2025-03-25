import 'dart:developer' as developer;

class Logger {
  static void info(String message) {
    developer.log('[INFO] $message', name: 'myUZ');
  }

  static void error(String message) {
    developer.log('[ERROR] $message', name: 'myUZ');
  }

  static void warning(String message) {
    developer.log('[WARNING] $message', name: 'myUZ');
  }

  static void debug(String message) {
    developer.log('[DEBUG] $message', name: 'myUZ');
  }
}