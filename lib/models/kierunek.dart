class Kierunek {
  final int? id;
  final String nazwa;
  final String url;
  final DateTime? ostatniaAktualizacja;

  Kierunek({
    this.id,
    required this.nazwa,
    required this.url,
    this.ostatniaAktualizacja,
  });

  Kierunek copyWith({
    int? id,
    String? nazwa,
    String? url,
    DateTime? ostatniaAktualizacja,
  }) {
    return Kierunek(
      id: id ?? this.id,
      nazwa: nazwa ?? this.nazwa,
      url: url ?? this.url,
      ostatniaAktualizacja: ostatniaAktualizacja ?? this.ostatniaAktualizacja,
    );
  }

  Map<String, dynamic> toJson() => {
        'nazwa': nazwa,
        'url': url,
      };

  factory Kierunek.fromJson(Map<String, dynamic> json) => Kierunek(
    id: json['id'],
    nazwa: json['nazwa'],
    url: json['url'],
    ostatniaAktualizacja: json['ostatnia_aktualizacja'] != null
        ? DateTime.parse(json['ostatnia_aktualizacja'])
        : null,
  );
}
