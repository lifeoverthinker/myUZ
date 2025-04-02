class Kierunek {
  final int id;
  final String nazwa;
  final String url;
  final DateTime? ostatniaAktualizacja;

  Kierunek({
    required this.id,
    required this.nazwa,
    required this.url,
    this.ostatniaAktualizacja,
  });

  factory Kierunek.fromJson(Map<String, dynamic> json) {
    return Kierunek(
      id: json['id'],
      nazwa: json['nazwa'],
      url: json['url'],
      ostatniaAktualizacja: json['ostatnia_aktualizacja'] != null
          ? DateTime.parse(json['ostatnia_aktualizacja'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nazwa': nazwa,
      'url': url,
    };
  }
}