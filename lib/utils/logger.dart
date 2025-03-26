import 'dart:developer' as developer;
  import 'dart:io';

  class Logger {
    static File? _logFile;

    static void setLogFile(File file) {
      _logFile = file;
      // Dodaj nagłówek przy inicjalizacji pliku logów
      if (file.existsSync()) {
        _writeToFile('\n=== Sesja logowania rozpoczęta: ${DateTime.now()} ===\n');
      }
    }

    static void info(String message) {
      final timeStamp = DateTime.now().toString();
      final logMessage = '[$timeStamp] [INFO] $message';
      developer.log('[INFO] $message', name: 'myUZ');
      _writeToFile(logMessage);
    }

    static void error(String message) {
      final timeStamp = DateTime.now().toString();
      final logMessage = '[$timeStamp] [ERROR] $message';
      developer.log('[ERROR] $message', name: 'myUZ');
      _writeToFile(logMessage);
    }

    static void warning(String message) {
      final timeStamp = DateTime.now().toString();
      final logMessage = '[$timeStamp] [WARNING] $message';
      developer.log('[WARNING] $message', name: 'myUZ');
      _writeToFile(logMessage);
    }

    static void debug(String message) {
      final timeStamp = DateTime.now().toString();
      final logMessage = '[$timeStamp] [DEBUG] $message';
      developer.log('[DEBUG] $message', name: 'myUZ');
      _writeToFile(logMessage);
    }

    static void _writeToFile(String message) {
      if (_logFile != null) {
        try {
          _logFile!.writeAsStringSync('$message\n', mode: FileMode.append);
        } catch (e) {
          developer.log('[ERROR] Błąd zapisywania do pliku logów: $e', name: 'myUZ');
        }
      }
    }
  }