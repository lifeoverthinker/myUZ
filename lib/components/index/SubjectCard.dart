import 'package:flutter/material.dart';
import '../../theme/fonts.dart';
import '../../theme/theme.dart';
import '../../my_uz_icons.dart';

class SubjectCard extends StatelessWidget {
  final String subjectName;
  final double? average;
  final List<Map<String, dynamic>> grades;
  final int absences;
  final VoidCallback onTap;

  const SubjectCard({
    super.key,
    required this.subjectName,
    required this.average,
    required this.grades,
    required this.absences,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header z nazwą i średnią
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subjectName,
                      style: AppTextStyles.indexSubjectTitle(context).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (average != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getAverageColor(average!).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        average!.toStringAsFixed(2),
                        style: AppTextStyles.indexAverageValue(context).copyWith(
                          color: _getAverageColor(average!),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Ostatnie oceny i nieobecności
              Row(
                children: [
                  // Ostatnie oceny
                  Expanded(
                    flex: 2,
                    child: _buildRecentGrades(context),
                  ),

                  const SizedBox(width: 16),

                  // Nieobecności
                  _buildAbsencesBadge(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentGrades(BuildContext context) {
    if (grades.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Brak ocen',
          style: AppTextStyles.cardDescription(context).copyWith(
            color: kGreyText,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final recentGrades = grades.take(3).toList();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: recentGrades.map((grade) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: kCardPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kCardPurple.withOpacity(0.3)),
        ),
        child: Text(
          grade['value'].toString(),
          style: AppTextStyles.indexGrade(context).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildAbsencesBadge(BuildContext context) {
    final isWarning = absences >= 3; // Można dostosować próg

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isWarning
            ? kCardRed.withOpacity(0.1)
            : kCardGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning
              ? kCardRed.withOpacity(0.3)
              : kCardGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            MyUzIcons.calendar_minus,
            size: 14,
            color: isWarning ? kCardRed : kCardGreen.withOpacity(0.8),
          ),
          const SizedBox(width: 4),
          Text(
            absences.toString(),
            style: AppTextStyles.cardDescription(context).copyWith(
              color: isWarning ? kCardRed : kCardGreen.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAverageColor(double avg) {
    if (avg >= 4.5) return kCardGreen;
    if (avg >= 3.5) return kCardYellow;
    return kCardRed;
  }
}
