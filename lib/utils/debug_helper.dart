import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class DebugHelper {
  // Flaga do kontrolowania logów debugowania
  static const bool _enableDebugLogs = true; // Zmień na false w produkcji

  // KALENDARZ - logi związane z kalendarzem
  static void logCalendar(String message, {Object? data}) {
    if (!_enableDebugLogs || !kDebugMode) return;
    developer.log(
      message,
      name: 'CALENDAR',
      error: data?.toString(),
    );
  }

  // PROFILE - logi związane z profilem użytkownika
  static void logProfile(String message, {Object? data}) {
    if (!_enableDebugLogs || !kDebugMode) return;
    developer.log(
      message,
      name: 'PROFILE',
      error: data?.toString(),
    );
  }

  // HOME - logi związane z ekranem głównym
  static void logHome(String message, {Object? data}) {
    if (!_enableDebugLogs || !kDebugMode) return;
    developer.log(
      message,
      name: 'HOME',
      error: data?.toString(),
    );
  }

  // SUPABASE - logi związane z bazą danych
  static void logSupabase(String message, {Object? data}) {
    if (!_enableDebugLogs || !kDebugMode) return;
    developer.log(
      message,
      name: 'SUPABASE',
      error: data?.toString(),
    );
  }

  // ERROR - logi błędów
  static void logError(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return; // Błędy zawsze loguj w debug mode
    developer.log(
      message,
      name: 'ERROR',
      error: error?.toString(),
      stackTrace: stackTrace,
    );
  }

  // Metoda do szybkiego wyłączania wszystkich logów
  static void disableAllLogs() {
    // W przyszłości można dodać mechanizm runtime'owego wyłączania
  }
}
