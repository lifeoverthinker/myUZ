import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../theme/fonts.dart';
import '../profile/user_profile.dart';

class SubjectColorsSection extends StatefulWidget {
  const SubjectColorsSection({super.key});

  @override
  State<SubjectColorsSection> createState() => _SubjectColorsSectionState();
}

class _SubjectColorsSectionState extends State<SubjectColorsSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: kCardPurple,
              child: const Icon(Icons.color_lens, color: kMainText, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kolory typów zajęć',
                    style: AppTextStyles.cardDescription(
                      context,
                    ).copyWith(color: kMainText.withOpacity(0.7), fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dostosuj kolory dla typów zajęć',
                    style: AppTextStyles.cardTitle(
                      context,
                    ).copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...{
          'W': 'Wykład',
          'C': 'Ćwiczenia',
          'L': 'Laboratoria',
          'P': 'Projekt',
          'S': 'Seminarium',
        }.entries.map((entry) => _buildSubjectColorRow(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildSubjectColorRow(String typeCode, String typeName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              typeName,
              style: AppTextStyles.cardDescription(
                context,
              ).copyWith(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  kMaterialPalette.length,
                  (index) => GestureDetector(
                    onTap: () {
                      setState(() {
                        userProfile.setColorForSubjectType(typeCode, index);
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: kMaterialPalette[index],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              userProfile.subjectColorMapping[typeCode] == index
                                  ? kMainText
                                  : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
