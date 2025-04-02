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

  Map<String, dynamic> toJson() => {
    'id': id,
    'nazwa': nazwa,
    'url': url,
  };
}
