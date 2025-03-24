class Kierunek {
  final int? id;
  final String nazwa;
  final String url;

  Kierunek({
    this.id,
    required this.nazwa,
    required this.url,
  });

  factory Kierunek.fromJson(Map<String, dynamic> json) {
    return Kierunek(
      id: json['id'],
      nazwa: json['nazwa'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nazwa': nazwa,
      'url': url,
      if (id != null) 'id': id,
    };
  }
}