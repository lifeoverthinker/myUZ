class Zajecia {
  final String uid;
  final int? grupaId;
  final int? nauczycielId;
  final DateTime od;
  final DateTime do_;
  final String przedmiot;
  final String? rz;
  final String? miejsce;
  final String? terminy;
  final DateTime? ostatniaAktualizacja;

  Zajecia({
    required this.uid,
    this.grupaId,
    this.nauczycielId,
    required this.od,
    required this.do_,
    required this.przedmiot,
    this.rz,
    this.miejsce,
    this.terminy,
    this.ostatniaAktualizacja,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'grupa_id': grupaId,
        'nauczyciel_id': nauczycielId,
        'od': od.toIso8601String(),
        'do': do_.toIso8601String(),
        'przedmiot': przedmiot,
        'rz': rz,
        'miejsce': miejsce,
        'terminy': terminy,
      };

  factory Zajecia.fromJson(Map<String, dynamic> json) => Zajecia(
        uid: json['uid'],
        grupaId: json['grupa_id'],
        nauczycielId: json['nauczyciel_id'],
        od: DateTime.parse(json['od']),
        do_: DateTime.parse(json['do']),
        przedmiot: json['przedmiot'],
        rz: json['rz'],
        miejsce: json['miejsce'],
        terminy: json['terminy'],
        ostatniaAktualizacja: json['ostatnia_aktualizacja'] != null
            ? DateTime.parse(json['ostatnia_aktualizacja'])
            : null,
      );
}
