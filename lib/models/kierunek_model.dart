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
      ostatniaAktualizacja: DateTime.parse(json['ostatnia_aktualizacja']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nazwa': nazwa,
      'url': url,
    };
  }
}