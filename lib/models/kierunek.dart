import 'package:equatable/equatable.dart';

class Kierunek extends Equatable {
  final String id;
  final String nazwa;
  final String wydzial;
  final String url;

  const Kierunek({
    required this.id,
    required this.nazwa,
    required this.wydzial,
    required this.url,
  });

  @override
  List<Object?> get props => [id, nazwa, wydzial, url];

  @override
  String toString() => 'Kierunek(id: $id, nazwa: $nazwa, wydział: $wydzial)';

  // Kopiowanie z możliwością nadpisania pól
  Kierunek copyWith({
    String? id,
    String? nazwa,
    String? wydzial,
    String? url,
  }) {
    return Kierunek(
      id: id ?? this.id,
      nazwa: nazwa ?? this.nazwa,
      wydzial: wydzial ?? this.wydzial,
      url: url ?? this.url,
    );
  }

  // Konwersja z JSON
  factory Kierunek.fromJson(Map<String, dynamic> json) {
    return Kierunek(
      id: json['id'] as String,
      nazwa: json['nazwa'] as String,
      wydzial: json['wydzial'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  // Konwersja do JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nazwa': nazwa,
      'wydzial': wydzial,
      'url': url,
    };
  }

  // Walidacja danych kierunku
  bool get isValid => id.isNotEmpty && nazwa.isNotEmpty && url.isNotEmpty;
}
