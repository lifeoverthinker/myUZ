class Wydzial {
  final int? id;
  final String nazwa;
  final String url;
  final DateTime? ostatniaAktualizacja;

  Wydzial({
    this.id,
    required this.nazwa,
    required this.url,
    this.ostatniaAktualizacja,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'nazwa': nazwa,
      'url': url,
    };

    // Dodaj id tylko jeśli nie jest null (przy aktualizacji)
    if (id != null) {
      json['id'] = id;
    }

    // Dodaj datę aktualizacji jeśli jest
    if (ostatniaAktualizacja != null) {
      json['ostatnia_aktualizacja'] = ostatniaAktualizacja!.toIso8601String();
    }

    return json;
  }

  factory Wydzial.fromJson(Map<String, dynamic> json) {
    return Wydzial(
      id: json['id'],
      nazwa: json['nazwa'],
      url: json['url'],
      ostatniaAktualizacja: json['ostatnia_aktualizacja'] != null
          ? DateTime.parse(json['ostatnia_aktualizacja'])
          : null,
    );
  }
}