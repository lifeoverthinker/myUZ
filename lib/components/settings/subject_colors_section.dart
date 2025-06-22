import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../theme/fonts.dart';
import '../profile/user_profile.dart';
import '../../my_uz_icons.dart';

class SubjectColorsSection extends StatefulWidget {
  const SubjectColorsSection({super.key});

  @override
  State<SubjectColorsSection> createState() => _SubjectColorsSectionState();
}

class _SubjectColorsSectionState extends State<SubjectColorsSection> {
  final List<Color> palette = [
    Color(0xFFFFF8E1),
    Color(0xFFE8DEF8),
    Color(0xFFDAF4D6),
    Color(0xFFFFD8E4),
    Color(0xFFE6F3EC),
  ];
  final List<Color> borders = [
    Color(0xFFFFE082),
    Color(0xFFB39DDB),
    Color(0xFF81C784),
    Color(0xFFF8BBD0),
    Color(0xFF80CBC4),
  ];

  final Map<String, String> subjectTypes = const {
    'W': 'Wykład',
    'C': 'Ćwiczenia',
    'L': 'Laboratoria',
    'P': 'Projekt',
    'S': 'Seminarium',
  };

  @override
  Widget build(BuildContext context) {
    const Color iconColor = Color(0xFF1D192B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: IconButton(
            icon: const Icon(
              MyUzIcons.chevron_left,
              color: iconColor,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Wróć',
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Kolory typów zajęć',
            style: AppTextStyles.sectionHeader(context).copyWith(fontSize: 20),
          ),
        ),
        centerTitle: false,
        actions: [const SizedBox(width: 16)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children:
                subjectTypes.entries
                    .map(
                      (entry) => _buildSubjectColorCard(entry.key, entry.value),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectColorCard(String typeCode, String typeName) {
    final selectedIdx = userProfile.subjectColorMapping[typeCode] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: palette[selectedIdx],
                  shape: BoxShape.circle,
                  border: Border.all(color: borders[selectedIdx], width: 2),
                ),
              ),
              Text(
                typeName,
                style: AppTextStyles.cardTitle(
                  context,
                ).copyWith(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(palette.length, (idx) {
              final isSelected = selectedIdx == idx;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    userProfile.setColorForSubjectType(typeCode, idx);
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: idx < palette.length - 1 ? 16 : 0,
                  ),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: palette[idx],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? borders[idx] : Colors.transparent,
                      width: isSelected ? 3 : 2,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
