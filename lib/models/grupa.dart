import 'package:equatable/equatable.dart';

class Grupa extends Equatable {
  final String id;
  final String nazwa;
  final String kierunekId;
  final String url;
  final String rodzajStudiow;
  final String rokAkademicki;
  final String semestr;

  const Grupa({
    required this.id,
    required this.nazwa,
    required this.kierunekId,
    required this.url,
    this.rodzajStudiow = '',
    this.rokAkademicki = '',
    this.semestr = '',
  });

  @override
  List<Object?> get props => [
        id,
        nazwa,
        kierunekId,
        url,
        rodzajStudiow,
        rokAkademicki,
        semestr,
      ];

  @override
  String toString() =>
      'Grupa(id: $id, nazwa: $nazwa, kierunekId: $kierunekId, semestr: $semestr)';

  // Kopiowanie z możliwością nadpisania pól
  Grupa copyWith({
    String? id,
    String? nazwa,
    String? kierunekId,
    String? url,
    String? rodzajStudiow,
    String? rokAkademicki,
    String? semestr,
  }) {
    return Grupa(
      id: id ?? this.id,
      nazwa: nazwa ?? this.nazwa,
      kierunekId: kierunekId ?? this.kierunekId,
      url: url ?? this.url,
      rodzajStudiow: rodzajStudiow ?? this.rodzajStudiow,
      rokAkademicki: rokAkademicki ?? this.rokAkademicki,
      semestr: semestr ?? this.semestr,
    );
  }

  // Konwersja z JSON
  factory Grupa.fromJson(Map<String, dynamic> json) {
    return Grupa(
      id: json['id'] as String,
      nazwa: json['nazwa'] as String,
      kierunekId: json['kierunek_id'] as String,
      url: json['url'] as String? ?? '',
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
      'url': url,
      'rodzaj_studiow': rodzajStudiow,
      'rok_akademicki': rokAkademicki,
      'semestr': semestr,
    };
  }

  // Walidacja danych grupy
  bool get isValid =>
      id.isNotEmpty && nazwa.isNotEmpty && kierunekId.isNotEmpty;
}
