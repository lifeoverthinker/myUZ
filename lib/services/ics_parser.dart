import 'package:my_uz/models/zajecia_model.dart';

class IcsParser {
  static List<Zajecia> parsujZajecia(String icsContent, {int? nauczycielId}) {
    final List<Zajecia> zajecia = [];
    final lines = icsContent.split('\n');

    String? uid;
    DateTime? start;
    DateTime? end;
    String? summary;
    String? location;
    String? description;

    bool inEvent = false;

    for (var line in lines) {
      line = line.trim();

      if (line == 'BEGIN:VEVENT') {
        inEvent = true;
        uid = null;
        start = null;
        end = null;
        summary = null;
        location = null;
        description = null;
      } else if (line == 'END:VEVENT') {
        inEvent = false;

        if (uid != null && start != null && end != null && summary != null) {
          zajecia.add(Zajecia(
            uid: uid,
            od: start,
            do_: end,
            przedmiot: summary,
            miejsce: location,
            terminy: description,
            nauczycielId: nauczycielId,
          ));
        }
      }

      if (inEvent) {
        if (line.startsWith('UID:')) {
          uid = line.substring(4);
        } else if (line.startsWith('DTSTART:')) {
          start = _parseIcsDate(line.substring(8));
        } else if (line.startsWith('DTEND:')) {
          end = _parseIcsDate(line.substring(6));
        } else if (line.startsWith('SUMMARY:')) {
          summary = line.substring(8);
        } else if (line.startsWith('LOCATION:')) {
          location = line.substring(9);
        } else if (line.startsWith('DESCRIPTION:')) {
          description = line.substring(12);
        }
      }
    }

    return zajecia;
  }

  static DateTime _parseIcsDate(String icsDate) {
    // Format: YYYYMMDDTHHMMSSZ
    final year = int.parse(icsDate.substring(0, 4));
    final month = int.parse(icsDate.substring(4, 6));
    final day = int.parse(icsDate.substring(6, 8));
    final hour = int.parse(icsDate.substring(9, 11));
    final minute = int.parse(icsDate.substring(11, 13));
    final second = int.parse(icsDate.substring(13, 15));

    return DateTime.utc(year, month, day, hour, minute, second);
  }
}
