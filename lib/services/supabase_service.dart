import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static final SupabaseClient client = SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_KEY']!,
  );

  // Najbliższe zajęcia dla podgrupy "A" oraz wspólne (NULL lub pusty string)
  Future<List<Map<String, dynamic>>> fetchNajblizszeZajecia() async {
    try {
      final grupy = await client
          .from('grupy')
          .select('id')
          .eq('kod_grupy', '23INF-SP');

      if (grupy.isEmpty) return [];

      final grupaIds = grupy.map((g) => g['id'] as String).toList();

      final response = await client
          .from('zajecia_grupy')
          .select('przedmiot, od, do_, miejsce, rz, podgrupa')
          .inFilter('grupa_id', grupaIds)
          .or('podgrupa.eq.A,podgrupa.is.null,podgrupa.eq.')
          .gte('od', DateTime.now().toIso8601String())
          .order('od', ascending: true)
          .limit(5);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Błąd pobierania zajęć: $e');
      return [];
    }
  }

  // Zajęcia na wybrany dzień dla podgrupy "A" oraz wspólne (NULL lub pusty string)
  Future<List<Map<String, dynamic>>> fetchZajeciaForDay(DateTime day) async {
    try {
      final grupy = await client
          .from('grupy')
          .select('id')
          .eq('kod_grupy', '23INF-SP');

      if (grupy.isEmpty) return [];

      final grupaIds = grupy.map((g) => g['id'] as String).toList();

      final start = DateTime(day.year, day.month, day.day, 0, 0, 0).toIso8601String();
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59).toIso8601String();

      final zajecia = await client
          .from('zajecia_grupy')
          .select('przedmiot, od, do_, miejsce, rz, podgrupa')
          .inFilter('grupa_id', grupaIds)
          .or('podgrupa.eq.A,podgrupa.is.null,podgrupa.eq.')
          .gte('od', start)
          .lte('od', end)
          .order('od', ascending: true);

      return List<Map<String, dynamic>>.from(zajecia);
    } catch (e) {
      print('Błąd pobierania zajęć na dzień: $e');
      return [];
    }
  }
}
