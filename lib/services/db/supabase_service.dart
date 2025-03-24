import 'package:supabase/supabase.dart';
import '../../models/kierunek.dart';
import '../../models/grupa.dart';
import '../../models/zajecia.dart';
import '../../models/wydzial.dart';
import '../../models/nauczyciel.dart';
import '../../models/plan_nauczyciela.dart';
import '../../utils/logger.dart';

class SupabaseService {
  static SupabaseClient supabase = SupabaseClient(
    'https://aovlvwjbnjsfplpgqzjv.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvdmx2d2pibmpzZnBscGdxemp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE5ODY5OTEsImV4cCI6MjA1NzU2Mjk5MX0.TYvFUUhrksgleb-jiLDa-TxdItWuEO_CqIClPYyHdN0',
  );

  static void initialize(String url, String key) {
    supabase = SupabaseClient(url, key);
  }

  // Metody dla kierunków
  static Future<List<Kierunek>> getKierunki() async {
    try {
      final response = await supabase.from('kierunki').select();
      return response.map((json) => Kierunek.fromJson(json)).toList();
    } catch (e) {
      Logger.error('SupabaseService: Błąd pobierania kierunków: $e');
      return [];
    }
  }

  static Future<Kierunek?> createOrUpdateKierunek(Kierunek kierunek) async {
    try {
      // Najpierw sprawdź czy kierunek istnieje
      final existing = await supabase
          .from('kierunki')
          .select()
          .eq('nazwa', kierunek.nazwa)
          .limit(1);

      if (existing.isNotEmpty) {
        // Aktualizuj istniejący
        final updated = await supabase
            .from('kierunki')
            .update(kierunek.toJson())
            .eq('id', existing[0]['id'])
            .select();

        if (updated.isNotEmpty) {
          return Kierunek.fromJson(updated[0]);
        }
      } else {
        // Dodaj nowy
        final inserted = await supabase
            .from('kierunki')
            .insert(kierunek.toJson())
            .select();

        if (inserted.isNotEmpty) {
          return Kierunek.fromJson(inserted[0]);
        }
      }

      return null;
    } catch (e) {
      Logger.error('SupabaseService: Błąd zapisywania kierunku: $e');
      return null;
    }
  }

  // Metody dla grup
  static Future<List<Grupa>> getGrupyForKierunek(int kierunekId) async {
    try {
      final response = await supabase
          .from('grupy')
          .select()
          .eq('kierunek_id', kierunekId);

      return response.map((json) => Grupa.fromJson(json)).toList();
    } catch (e) {
      Logger.error('SupabaseService: Błąd pobierania grup: $e');
      return [];
    }
  }

  static Future<Grupa?> createOrUpdateGrupa(Grupa grupa) async {
    try {
      // Najpierw sprawdź czy grupa istnieje
      final existing = await supabase
          .from('grupy')
          .select()
          .eq('nazwa', grupa.nazwa)
          .eq('kierunek_id', grupa.kierunekId)
          .limit(1);

      if (existing.isNotEmpty) {
        // Aktualizuj istniejącą
        final updated = await supabase
            .from('grupy')
            .update(grupa.toJson())
            .eq('id', existing[0]['id'])
            .select();

        if (updated.isNotEmpty) {
          return Grupa.fromJson(updated[0]);
        }
      } else {
        // Dodaj nową
        final inserted = await supabase
            .from('grupy')
            .insert(grupa.toJson())
            .select();

        if (inserted.isNotEmpty) {
          return Grupa.fromJson(inserted[0]);
        }
      }

      return null;
    } catch (e) {
      Logger.error('SupabaseService: Błąd zapisywania grupy: $e');
      return null;
    }
  }

  // Metody dla zajęć
  static Future<bool> deleteZajeciaForGrupa(int grupaId) async {
    try {
      await supabase.from('zajecia').delete().eq('grupa_id', grupaId);
      return true;
    } catch (e) {
      Logger.error('SupabaseService: Błąd usuwania zajęć: $e');
      return false;
    }
  }

  static Future<bool> batchInsertZajecia(List<Zajecia> zajecia) async {
    if (zajecia.isEmpty) return true;

    try {
      // Podziel na mniejsze partie po 25 rekordów
      for (int i = 0; i < zajecia.length; i += 25) {
        final end = (i + 25 < zajecia.length) ? i + 25 : zajecia.length;
        final batch = zajecia.sublist(i, end).map((z) => z.toJson()).toList();

        await supabase.from('zajecia').insert(batch);
        Logger.info('SupabaseService: Zapisano ${i+1}-$end z ${zajecia.length} zajęć');
      }

      return true;
    } catch (e) {
      Logger.error('SupabaseService: Błąd zapisywania zajęć: $e');
      return false;
    }
  }

  /// Pobiera wydział po URL
  static Future<Wydzial?> getWydzialByUrl(String url) async {
    try {
      final response = await supabase
          .from('wydzialy')
          .select()
          .eq('url', url)
          .limit(1);

      if (response.isNotEmpty) {
        return Wydzial.fromJson(response[0]);
      }
      return null;
    } catch (e) {
      Logger.error('SupabaseService: Błąd pobierania wydziału po URL: $e');
      return null;
    }
  }

  /// Pobiera kierunek po URL
  static Future<Kierunek?> getKierunekByUrl(String url) async {
    try {
      final response = await supabase
          .from('kierunki')
          .select()
          .eq('url', url)
          .limit(1);

      if (response.isNotEmpty) {
        return Kierunek.fromJson(response[0]);
      }
      return null;
    } catch (e) {
      Logger.error('SupabaseService: Błąd pobierania kierunku po URL: $e');
      return null;
    }
  }

  /// Pobiera nauczyciela po URL planu
  static Future<Nauczyciel?> getNauczycielByUrlPlan(String urlPlan) async {
    try {
      final response = await supabase
          .from('nauczyciele')
          .select()
          .eq('url_plan', urlPlan)
          .limit(1);

      if (response.isNotEmpty) {
        return Nauczyciel.fromJson(response[0]);
      }
      return null;
    } catch (e) {
      Logger.error('SupabaseService: Błąd pobierania nauczyciela po URL: $e');
      return null;
    }
  }

  static Future<Nauczyciel?> createOrUpdateNauczyciel(Nauczyciel nauczyciel) async {
    try {
      // Najpierw sprawdź czy nauczyciel istnieje
      final existing = await supabase
          .from('nauczyciele')
          .select()
          .eq('url_plan', nauczyciel.urlPlan)
          .limit(1);

      if (existing.isNotEmpty) {
        // Aktualizuj istniejącego
        final updated = await supabase
            .from('nauczyciele')
            .update(nauczyciel.toJson())
            .eq('id', existing[0]['id'])
            .select();

        if (updated.isNotEmpty) {
          return Nauczyciel.fromJson(updated[0]);
        }
      } else {
        // Dodaj nowego
        final inserted = await supabase
            .from('nauczyciele')
            .insert(nauczyciel.toJson())
            .select();

        if (inserted.isNotEmpty) {
          return Nauczyciel.fromJson(inserted[0]);
        }
      }

      return null;
    } catch (e) {
      Logger.error('SupabaseService: Błąd zapisywania nauczyciela: $e');
      return null;
    }
  }

  /// Zapisuje lub aktualizuje wydział
  static Future<Wydzial?> createOrUpdateWydzial(Wydzial wydzial) async {
    try {
      // Najpierw sprawdź czy wydział istnieje
      final existing = await supabase
          .from('wydzialy')
          .select()
          .eq('url', wydzial.url)
          .limit(1);

      if (existing.isNotEmpty) {
        // Aktualizuj istniejący
        final updated = await supabase
            .from('wydzialy')
            .update(wydzial.toJson())
            .eq('id', existing[0]['id'])
            .select();

        if (updated.isNotEmpty) {
          return Wydzial.fromJson(updated[0]);
        }
      } else {
        // Dodaj nowy
        final inserted = await supabase
            .from('wydzialy')
            .insert(wydzial.toJson())
            .select();

        if (inserted.isNotEmpty) {
          return Wydzial.fromJson(inserted[0]);
        }
      }

      return null;
    } catch (e) {
      Logger.error('SupabaseService: Błąd zapisywania wydziału: $e');
      return null;
    }
  }

  /// Usuwa plan nauczyciela
  static Future<bool> deleteZajeciaForNauczyciel(int nauczycielId) async {
    try {
      await supabase
          .from('plany_nauczycieli')
          .delete()
          .eq('nauczyciel_id', nauczycielId);
      return true;
    } catch (e) {
      Logger.error('SupabaseService: Błąd usuwania planu nauczyciela: $e');
      return false;
    }
  }

  /// Zapisuje plan nauczyciela
  static Future<bool> batchInsertPlanNauczyciela(List<PlanNauczyciela> plany) async {
    if (plany.isEmpty) return true;

    try {
      // Podziel na mniejsze partie po 25 rekordów
      for (int i = 0; i < plany.length; i += 25) {
        final end = (i + 25 < plany.length) ? i + 25 : plany.length;
        final batch = plany.sublist(i, end).map((z) => z.toJson()).toList();

        await supabase
            .from('plany_nauczycieli')
            .insert(batch);
        Logger.info('SupabaseService: Zapisano ${i+1}-$end z ${plany.length} zajęć planu nauczyciela');
      }
      return true;
    } catch (e) {
      Logger.error('SupabaseService: Błąd zapisywania planu nauczyciela: $e');
      return false;
    }
  }
}