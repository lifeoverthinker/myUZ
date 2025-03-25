class AppConfig {
  // Pozwala na dynamiczną zmianę w skrypcie bin/scraper.dart
  static bool enableScraper = false;

  // Dodatkowe ustawienia konfiguracyjne
  static const String appName = 'UZ Plan';
  static const int dataRefreshIntervalHours = 12;

  // Konfiguracja Supabase
  static const String supabaseUrl = 'https://aovlvwjbnjsfplpgqzjv.supabase.co';
  static const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvdmx2d2pibmpzZnBscGdxemp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE5ODY5OTEsImV4cCI6MjA1NzU2Mjk5MX0.TYvFUUhrksgleb-jiLDa-TxdItWuEO_CqIClPYyHdN0';
}