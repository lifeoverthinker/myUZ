import 'dart:developer' as developer;
import 'dart:io';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class Logger {
  static LogLevel _currentLevel = LogLevel.info;
  static File? _logFile;
  static IOSink? _logSink;

  // Ustawienie poziomu logowania
  static set level(LogLevel level) {
    _currentLevel = level;
  }

  // Metoda do ustawienia pliku logów
  static void setLogFile(String filePath) {
    try {
      _logFile = File(filePath);
      _logSink = _logFile!.openWrite(mode: FileMode.append);
      _log('INFO', 'Ustawianie pliku logów: $filePath');
    } catch (e, stackTrace) {
      _log('ERROR', 'Nie można otworzyć pliku logów: $filePath', e, stackTrace);
    }
  }

  // Logowanie na poziomie debug
  static void debug(String message) {
    if (_currentLevel.index <= LogLevel.debug.index) {
      _log('DEBUG', message);
    }
  }

  // Logowanie na poziomie info
  static void info(String message) {
    if (_currentLevel.index <= LogLevel.info.index) {
      _log('INFO', message);
    }
  }

  // Logowanie na poziomie warning
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (_currentLevel.index <= LogLevel.warning.index) {
      _log('WARNING', message, error, stackTrace);
    }
  }

  // Logowanie na poziomie error
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_currentLevel.index <= LogLevel.error.index) {
      _log('ERROR', message, error, stackTrace);
    }
  }

  // Wewnętrzna implementacja logowania
  static void _log(String level, String message,
      [Object? error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    final formattedMessage = '[$timestamp] $level: $message';

    developer.log(
      formattedMessage,
      name: 'MyUZ',
      error: error,
      stackTrace: stackTrace,
    );

    // Zapisywanie do pliku jeśli jest ustawiony
    if (_logSink != null) {
      try {
        _logSink!.writeln(formattedMessage);
        if (error != null) _logSink!.writeln('Error: $error');
        if (stackTrace != null) _logSink!.writeln('Stack trace: $stackTrace');
      } catch (e) {
        print('Błąd zapisywania do pliku logów: $e');
      }
    }

    // Dodatkowe logowanie do konsoli dla łatwiejszego debugowania
    print(formattedMessage);
    if (error != null) print('Error: $error');
    if (stackTrace != null) print('Stack trace: $stackTrace');
  }

  // Zamykanie pliku logów
  static void close() {
    _logSink?.close();
  }
}