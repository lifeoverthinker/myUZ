class Zajecia {
  final String uid;
  final int? grupaId;
  final DateTime od;
  final DateTime do_;
  final String przedmiot;
  final String? rz;
  final String? miejsce;
  final String? terminy;
  final DateTime? ostatniaAktualizacja;
  final int? nauczycielId;

  Zajecia({
    required this.uid,
    this.grupaId,
    required this.od,
    required this.do_,
    required this.przedmiot,
    this.rz,
    this.miejsce,
    this.terminy,
    this.ostatniaAktualizacja,
    this.nauczycielId,
  });

  String get dzienTygodnia {
    return od.weekday.toString();
  }

  String get godzina {
    return '${od.hour}:${od.minute.toString().padLeft(2, '0')}';
  }

  factory Zajecia.fromJson(Map<String, dynamic> json) {
    return Zajecia(
      uid: json['uid'] as String,
      grupaId: json['grupa_id'] as int?,
      od: DateTime.parse(json['od'] as String),
      do_: DateTime.parse(json['do'] as String),
      przedmiot: json['przedmiot'] as String,
      rz: json['rz'] as String? ?? '',
      miejsce: json['miejsce'] as String? ?? '',
      terminy: json['terminy'] as String? ?? '',
      nauczycielId: json['nauczyciel_id'] as int?,
      ostatniaAktualizacja: json['ostatnia_aktualizacja'] != null
          ? DateTime.parse(json['ostatnia_aktualizacja'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'grupa_id': grupaId,
      'od': od.toIso8601String(),
      'do': do_.toIso8601String(),
      'przedmiot': przedmiot,
      'rz': rz,
      'miejsce': miejsce,
      'terminy': terminy,
      'nauczyciel_id': nauczycielId,
      'ostatnia_aktualizacja': ostatniaAktualizacja?.toIso8601String(),
    };
  }
}
