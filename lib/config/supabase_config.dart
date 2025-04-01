class SupabaseConfig {
  // 🔴 Dane pobierane ZAWSZE z zmiennych środowiskowych (GitHub Secrets)
  static String get url => const String.fromEnvironment('SUPABASE_URL');
  static String get anonKey => const String.fromEnvironment('SUPABASE_KEY');
  static String get serviceRoleKey =>
      const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');
}