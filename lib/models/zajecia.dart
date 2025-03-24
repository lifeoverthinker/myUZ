class Zajecia {
  final String uid;
  final int grupaId;
  final String od;
  final String do_;
  final String przedmiot;
  final String? rz;
  final String nauczyciel;
  final String miejsce;
  final String? terminy;
  final DateTime? ostatniaAktualizacja;
  final int? nauczycielId;

  Zajecia({
    required this.uid,
    required this.grupaId,
    required this.od,
    required this.do_,
    required this.przedmiot,
    this.rz,
    required this.nauczyciel,
    required this.miejsce,
    this.terminy,
    this.nauczycielId,
    this.ostatniaAktualizacja,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'grupa_id': grupaId,
      'od': od,
      'do': do_,
      'przedmiot': przedmiot,
      'rz': rz,
      'miejsce': miejsce,
      'terminy': terminy,
      'nauczyciel_id': nauczycielId,
      'ostatnia_aktualizacja': ostatniaAktualizacja?.toIso8601String(),
    };
  }

  factory Zajecia.fromJson(Map<String, dynamic> json) {
    return Zajecia(
      uid: json['uid'],
      grupaId: json['grupa_id'],
      od: json['od'],
      do_: json['do'],
      przedmiot: json['przedmiot'],
      rz: json['rz'],
      nauczyciel: json['nauczyciel'] ?? '',
      miejsce: json['miejsce'] ?? 'Brak sali',
      terminy: json['terminy'],
      nauczycielId: json['nauczyciel_id'],
      ostatniaAktualizacja: json['ostatnia_aktualizacja'] != null
          ? DateTime.parse(json['ostatnia_aktualizacja'])
          : null,
    );
  }
}