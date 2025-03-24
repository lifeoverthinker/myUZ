class DatabaseConfig {
  final String url;
  final String anonKey;
  final String serviceRoleKey;

  DatabaseConfig({
    required this.url,
    required this.anonKey,
    required this.serviceRoleKey,
  });

  factory DatabaseConfig.fromEnv() {
    final url = String.fromEnvironment('SUPABASE_URL');
    final anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    final serviceRoleKey = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');

    if (url.isEmpty || anonKey.isEmpty || serviceRoleKey.isEmpty) {
      throw Exception('Brakuje konfiguracji bazy danych. Ustaw SUPABASE_URL, SUPABASE_ANON_KEY i SUPABASE_SERVICE_ROLE_KEY.');
    }

    return DatabaseConfig(
      url: url,
      anonKey: anonKey,
      serviceRoleKey: serviceRoleKey,
    );
  }
}