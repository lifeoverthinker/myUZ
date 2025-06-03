import 'package:flutter/material.dart';
import '../../theme/fonts.dart';

class AbsencesTab extends StatelessWidget {
  final List<Map<String, dynamic>> absences;
  final void Function(int subjectIdx)? onAddAbsence;
  final void Function(int subjectIdx, int absenceIdx)? onEditAbsence;

  const AbsencesTab({
    Key? key,
    required this.absences,
    this.onAddAbsence,
    this.onEditAbsence,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (absences.isEmpty) {
      return Center(
        child: Text(
          'Brak nieobecności',
          style: AppTextStyles.cardDescription(context),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
      itemCount: absences.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, subjectIdx) {
        final subject = absences[subjectIdx];
        final List<Map<String, dynamic>> subjectAbsences =
            subject['absences'] as List<Map<String, dynamic>>? ?? [];
        final int used = subjectAbsences.length;
        final int? limit = subject['limit']; // można przekazać w danych, np. 3
        final int remaining = limit != null ? (limit - used) : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek: nazwa przedmiotu + licznik po prawej
            Row(
              children: [
                Expanded(
                  child: Text(
                    subject['subject'],
                    style: AppTextStyles.indexSubjectTitle(context).copyWith(
                      color: const Color(0xFF1D192B),
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8DEF8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_busy, size: 17, color: Color(0xFF6750A4)),
                      const SizedBox(width: 4),
                      Text(
                        limit != null
                            ? '$used/$limit'
                            : used.toString(),
                        style: AppTextStyles.indexGrade(context).copyWith(
                          color: const Color(0xFF6750A4),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Lista nieobecności
            if (subjectAbsences.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Brak nieobecności',
                  style: AppTextStyles.cardDescription(context).copyWith(
                    color: Colors.black54,
                  ),
                ),
              )
            else
              Column(
                children: List.generate(subjectAbsences.length, (absenceIdx) {
                  final absence = subjectAbsences[absenceIdx];
                  final date = absence['date'] as DateTime?;
                  final dateStr = date != null
                      ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'
                      : '-';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Material(
                      color: const Color(0xFFF7F2F9),
                      borderRadius: BorderRadius.circular(10),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        leading: const Icon(Icons.calendar_today, size: 20, color: Color(0xFF79747E)),
                        title: Text(
                          dateStr,
                          style: AppTextStyles.indexGrade(context).copyWith(
                            color: const Color(0xFF1D192B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: onEditAbsence != null
                            ? () => onEditAbsence!(subjectIdx, absenceIdx)
                            : null,
                        trailing: onEditAbsence != null
                            ? Icon(Icons.edit, color: Colors.grey.shade500, size: 18)
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            // Dodaj nieobecność
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 2),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  textStyle: AppTextStyles.cardDescription(context).copyWith(fontWeight: FontWeight.w500),
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Dodaj nieobecność'),
                onPressed: onAddAbsence != null
                    ? () => onAddAbsence!(subjectIdx)
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}