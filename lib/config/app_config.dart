class AppConfig {
  // Pozwala na dynamiczną zmianę w skrypcie bin/scraper.dart
  static bool enableScraper = false;

  // Dodatkowe ustawienia konfiguracyjne
  static const String appName = 'UZ Plan';
  static const int dataRefreshIntervalHours = 12;
}