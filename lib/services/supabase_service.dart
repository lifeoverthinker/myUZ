import 'package:supabase/supabase.dart';
import 'package:my_uz/models/kierunek_model.dart';
import 'package:my_uz/models/grupa_model.dart';
import 'package:my_uz/models/zajecia_model.dart';
import 'package:my_uz/models/nauczyciel_model.dart';
import 'package:logger/logger.dart';

class SupabaseService {
  final _logger = Logger();
  late final SupabaseClient _client;

  // Konstruktor z opcjonalnym parametrem klienta
  SupabaseService({SupabaseClient? client}) {
    _client = client ??
        SupabaseClient('https://aovlvwjbnjsfplpgqzjv.supabase.co',
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvdmx2d2pibmpzZnBscGdxemp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE5ODY5OTEsImV4cCI6MjA1NzU2Mjk5MX0.TYvFUUhrksgleb-jiLDa-TxdItWuEO_CqIClPYyHdN0');
  }

  // Getter do klienta Supabase
  SupabaseClient get client => _client;

  Future<void> wstawKierunki(List<Kierunek> kierunki) async {
    _logger.i('Zapisywanie ${kierunki.length} kierunków');

    for (var batch in _podzielNaBatche(kierunki, 100)) {
      await _client
          .from('kierunki')
          .upsert(batch.map((k) => k.toJson()).toList(), onConflict: 'id');
    }
  }

  Future<void> wstawGrupy(List<Grupa> grupy) async {
    _logger.i('Zapisywanie ${grupy.length} grup');

    for (var batch in _podzielNaBatche(grupy, 100)) {
      await _client
          .from('grupy')
          .upsert(batch.map((g) => g.toJson()).toList(), onConflict: 'id');
    }
  }

  Future<void> wstawZajecia(List<Zajecia> zajecia) async {
    _logger.i('Zapisywanie ${zajecia.length} zajęć');

    for (var batch in _podzielNaBatche(zajecia, 100)) {
      await _client
          .from('zajecia')
          .upsert(batch.map((z) => z.toJson()).toList(), onConflict: 'uid');
    }
  }

  Future<void> wstawNauczycieli(List<Nauczyciel> nauczyciele) async {
    _logger.i('Zapisywanie ${nauczyciele.length} nauczycieli');

    for (var batch in _podzielNaBatche(nauczyciele, 100)) {
      await _client
          .from('nauczyciele')
          .upsert(batch.map((n) => n.toJson()).toList(), onConflict: 'id');
    }
  }

  List<List<T>> _podzielNaBatche<T>(List<T> items, int rozmiarBatcha) {
    List<List<T>> batches = [];
    for (var i = 0; i < items.length; i += rozmiarBatcha) {
      var end =
          (i + rozmiarBatcha < items.length) ? i + rozmiarBatcha : items.length;
      batches.add(items.sublist(i, end));
    }
    return batches;
  }
}
