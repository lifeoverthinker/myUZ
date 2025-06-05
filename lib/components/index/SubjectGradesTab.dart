import 'package:flutter/material.dart';
import '../../theme/fonts.dart';
import '../../theme/theme.dart';

// --- Index: zakładka Oceny (Figma: pastel cards, typography) ---
class SubjectGradesTab extends StatelessWidget {
  final List<Map<String, dynamic>> subjects;
  final void Function(int subjectIdx, int sectionIdx)? onGoToSection;
  final void Function(int subjectIdx)? onAddSection;

  const SubjectGradesTab({
    Key? key,
    required this.subjects,
    this.onGoToSection,
    this.onAddSection,
  }) : super(key: key);

  Color _getCardColor(int idx) {
    // Figma: pastel cards Index
    final colors = [kCardPurple, kCardPink, kCardBlue, kCardYellow];
    return colors[idx % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: subjects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, subjectIdx) {
        final subject = subjects[subjectIdx];
        final sections = subject['sections'] as List;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: Text(
                subject['name'],
                style: AppTextStyles.indexSubjectTitle(context).copyWith(
                  color: kMainText,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (sections.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Brak typu zajęć',
                  style: AppTextStyles.cardDescription(context),
                ),
              ),
            ...List.generate(sections.length, (sectionIdx) {
              final section = sections[sectionIdx];
              final grades = section['grades'] as List;
              final avg = grades.isEmpty
                  ? null
                  : grades
                  .map((g) => g['value'] as num)
                  .reduce((a, b) => a + b) /
                  grades.length;
              final gradesString = grades.isNotEmpty
                  ? grades.map((g) => g['value'].toString()).join(', ')
                  : "";

              return Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: _getCardColor(sectionIdx),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onGoToSection?.call(subjectIdx, sectionIdx),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 64,
                              child: avg != null
                                  ? Text(
                                avg.toStringAsFixed(2),
                                style: AppTextStyles.indexAverageValue(
                                  context,
                                ).copyWith(
                                  color: kMainText,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                                  : Text(
                                "Brak ocen",
                                style: AppTextStyles.cardDescription(
                                  context,
                                ).copyWith(color: Colors.black54),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: grades.isNotEmpty
                                  ? Text(
                                gradesString,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.indexGrade(
                                  context,
                                ).copyWith(
                                  color: kMainText,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                              )
                                  : Container(),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.black38,
                              size: 20,
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 2, top: 6),
                          child: Text(
                            section['type'],
                            style: AppTextStyles.cardDescription(
                              context,
                            ).copyWith(
                              color: Colors.black45,
                              fontWeight: FontWeight.w500,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  textStyle: AppTextStyles.cardDescription(context)
                      .copyWith(fontWeight: FontWeight.w500),
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Dodaj typ zajęć'),
                onPressed: () => onAddSection?.call(subjectIdx),
              ),
            ),
          ],
        );
      },
    );
  }
}