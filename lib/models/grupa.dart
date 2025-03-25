class Grupa {
  final int? id;
  final String nazwa;
  final int? kierunekId;
  final String urlIcs;
  final DateTime? ostatniaAktualizacja;

  Grupa({
    this.id,
    required this.nazwa,
    this.kierunekId,
    required this.urlIcs,
    this.ostatniaAktualizacja,
  });

  Grupa copyWith({
    int? id,
    String? nazwa,
    int? kierunekId,
    String? urlIcs,
    DateTime? ostatniaAktualizacja,
  }) {
    return Grupa(
      id: id ?? this.id,
      nazwa: nazwa ?? this.nazwa,
      kierunekId: kierunekId ?? this.kierunekId,
      urlIcs: urlIcs ?? this.urlIcs,
      ostatniaAktualizacja: ostatniaAktualizacja ?? this.ostatniaAktualizacja,
    );
  }

  Map<String, dynamic> toJson() => {
        'nazwa': nazwa,
        'kierunek_id': kierunekId,
        'url_ics': urlIcs,
      };

  factory Grupa.fromJson(Map<String, dynamic> json) => Grupa(
        id: json['id'],
        nazwa: json['nazwa'],
        kierunekId: json['kierunek_id'],
        urlIcs: json['url_ics'],
        ostatniaAktualizacja: json['ostatnia_aktualizacja'] != null
            ? DateTime.parse(json['ostatnia_aktualizacja'])
            : null,
      );
}
