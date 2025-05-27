import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static final SupabaseClient client = SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_KEY']!,
  );

  Future<List<Map<String, dynamic>>> fetchNajblizszeZajecia({int limit = 5}) async {
    final response = await client
        .from('zajecia')
        .select('przedmiot, od, do_, miejsce, kod_grupy')
        .order('od', ascending: true)
        .limit(limit);
    if (response == null) return [];
    return List<Map<String, dynamic>>.from(response);
  }
}
