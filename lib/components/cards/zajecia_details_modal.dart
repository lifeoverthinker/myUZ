import 'package:flutter/material.dart';
import '../../theme/fonts.dart';

void showZajeciaDetailsModal(
  BuildContext context,
  Map<String, dynamic> zajecie, {
  required Color backgroundColor,
  required Color
  dotColor, // Możesz usunąć ten parametr, jeśli nie jest już używany
}) {
  final double maxWidth = 328; // 8-grid na mobile
  final start = DateTime.tryParse(zajecie['od'] ?? '') ?? DateTime.now();
  final end = DateTime.tryParse(zajecie['do_'] ?? '') ?? DateTime.now();
  final prowadzacy = zajecie['nauczyciel'] ?? 'Brak danych';
  final sala = zajecie['miejsce'] ?? '-';
  final typ = zajecie['rz'] ?? '-';
  final przedmiot = zajecie['przedmiot'] ?? '-';

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor, // Kolor jak na karcie zajęć!
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        przedmiot,
                        style: AppTextStyles.cardTitle(
                          context,
                        ).copyWith(fontSize: 18),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Kropka została usunięta
                  ],
                ),
                const SizedBox(height: 16),
                _row(
                  'Godzina',
                  '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                  context,
                ),
                const SizedBox(height: 8),
                _row('Sala', sala, context),
                const SizedBox(height: 8),
                _row('Typ zajęć', typ, context),
                const SizedBox(height: 8),
                _row('Prowadzący', prowadzacy, context),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Zamknij'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _row(String label, String value, BuildContext context) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 2),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 90,
        child: Text(
          '$label:',
          style: AppTextStyles.cardDescription(
            context,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      Expanded(
        child: Text(
          value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.cardDescription(context),
        ),
      ),
    ],
  ),
);
