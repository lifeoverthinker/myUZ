class Zajecia {
    final String uid;
    final int? grupaId;
    final DateTime od;
    final DateTime do_;
    final String przedmiot;
    final String? rz;
    final String? miejsce;
    final String? terminy;
    final int? nauczycielId;
    final DateTime? ostatniaAktualizacja;

    Zajecia({
      required this.uid,
      this.grupaId,
      required this.od,
      required this.do_,
      required this.przedmiot,
      this.rz,
      this.miejsce,
      this.terminy,
      this.nauczycielId,
      this.ostatniaAktualizacja,
    });

    factory Zajecia.fromJson(Map<String, dynamic> json) {
      return Zajecia(
        uid: json['uid'],
        grupaId: json['grupa_id'],
        od: DateTime.parse(json['od']),
        do_: DateTime.parse(json['do_']),
        przedmiot: json['przedmiot'],
        rz: json['rz'],
        miejsce: json['miejsce'],
        terminy: json['terminy'],
        nauczycielId: json['nauczyciel_id'],
        ostatniaAktualizacja: json['ostatnia_aktualizacja'] != null
            ? DateTime.parse(json['ostatnia_aktualizacja'])
            : null,
      );
    }

    Map<String, dynamic> toJson() {
      return {
        'uid': uid,
        'grupa_id': grupaId,
        'od': od.toIso8601String(),
        'do_': do_.toIso8601String(),
        'przedmiot': przedmiot,
        'rz': rz,
        'miejsce': miejsce,
        'terminy': terminy,
        'nauczyciel_id': nauczycielId,
      };
    }
  }