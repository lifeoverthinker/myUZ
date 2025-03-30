import 'package:equatable/equatable.dart';

class Grupa extends Equatable {
  final int id;
  final String nazwa;
  final int kierunekId;
  final String urlIcs;
  final DateTime ostatniaAktualizacja;

  // Pola pomocnicze (nie zapisywane do bazy)
  final String rodzajStudiow;
  final String rokAkademicki;
  final String semestr;

  Grupa({
    required this.id,
    required this.nazwa,
    required this.kierunekId,
    required this.urlIcs,
    DateTime? ostatniaAktualizacja,
    this.rodzajStudiow = '',
    this.rokAkademicki = '',
    this.semestr = '',
  }) : this.ostatniaAktualizacja = ostatniaAktualizacja ?? DateTime.now();

  @override
  List<Object?> get props => [
        id,
        nazwa,
        kierunekId,
        urlIcs,
        ostatniaAktualizacja,
        rodzajStudiow,
        rokAkademicki,
        semestr,
      ];

  @override
  String toString() =>
      'Grupa(id: $id, nazwa: $nazwa, kierunekId: $kierunekId, semestr: $semestr)';

  // Kopiowanie z możliwością nadpisania pól
  Grupa copyWith({
    int? id,
    String? nazwa,
    int? kierunekId,
    String? urlIcs,
    DateTime? ostatniaAktualizacja,
    String? rodzajStudiow,
    String? rokAkademicki,
    String? semestr,
  }) {
    return Grupa(
      id: id ?? this.id,
      nazwa: nazwa ?? this.nazwa,
      kierunekId: kierunekId ?? this.kierunekId,
      urlIcs: urlIcs ?? this.urlIcs,
      ostatniaAktualizacja: ostatniaAktualizacja ?? this.ostatniaAktualizacja,
      rodzajStudiow: rodzajStudiow ?? this.rodzajStudiow,
      rokAkademicki: rokAkademicki ?? this.rokAkademicki,
      semestr: semestr ?? this.semestr,
    );
  }

  // Konwersja z JSON
  factory Grupa.fromJson(Map<String, dynamic> json) {
    return Grupa(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      nazwa: json['nazwa'] as String,
      kierunekId: json['kierunek_id'] is String
          ? int.parse(json['kierunek_id'])
          : json['kierunek_id'] as int,
      urlIcs: json['url_ics'] as String? ?? '',
      ostatniaAktualizacja: json['ostatnia_aktualizacja'] != null
          ? DateTime.parse(json['ostatnia_aktualizacja'])
          : DateTime.now(),
      rodzajStudiow: json['rodzaj_studiow'] as String? ?? '',
      rokAkademicki: json['rok_akademicki'] as String? ?? '',
      semestr: json['semestr'] as String? ?? '',
    );
  }

  // Konwersja do JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nazwa': nazwa,
      'kierunek_id': kierunekId,
      'url_ics': urlIcs,
      'ostatnia_aktualizacja': ostatniaAktualizacja.toIso8601String(),
      'rodzaj_studiow': rodzajStudiow,
      'rok_akademicki': rokAkademicki,
      'semestr': semestr,
    };
  }

  // Walidacja danych grupy
  bool get isValid => id > 0 && nazwa.isNotEmpty && kierunekId > 0;
}
