import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../theme/fonts.dart';
import '../profile/user_profile.dart';

class AppearanceSection extends StatefulWidget {
  const AppearanceSection({super.key});

  @override
  State<AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends State<AppearanceSection> {
  bool _isDarkMode = false;
  int _selectedTheme = 0;
  final List<Color> themeColors = [
    kCardPurple,
    kCardGreen,
    kCardYellow,
    kCardPink,
    kCardBlue,
    kBackground,
  ];

  @override
  void initState() {
    super.initState();
    _selectedTheme = userProfile.selectedThemeColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildThemeRow(context),
        const SizedBox(height: 16),
        _buildDarkModeRow(context),
      ],
    );
  }

  Widget _buildThemeRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: kCardPurple,
              child: const Icon(Icons.palette, color: kMainText, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Motyw kolorystyczny',
                    style: AppTextStyles.cardDescription(
                      context,
                    ).copyWith(color: kMainText.withOpacity(0.7), fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Wybierz kolor główny aplikacji',
                    style: AppTextStyles.cardTitle(
                      context,
                    ).copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(
            themeColors.length,
            (index) => GestureDetector(
              onTap:
                  () => setState(() {
                    _selectedTheme = index;
                    userProfile.selectedThemeColor = index;
                  }),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: themeColors[index],
                child:
                    _selectedTheme == index
                        ? Icon(Icons.check, color: kMainText)
                        : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDarkModeRow(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: kCardPurple,
          child: const Icon(Icons.dark_mode, color: kMainText, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tryb ciemny',
                style: AppTextStyles.cardDescription(
                  context,
                ).copyWith(color: kMainText.withOpacity(0.7), fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                'Włącz/wyłącz tryb ciemny',
                style: AppTextStyles.cardTitle(context).copyWith(fontSize: 16),
              ),
            ],
          ),
        ),
        Switch(
          value: _isDarkMode,
          onChanged: (value) => setState(() => _isDarkMode = value),
          activeColor: kCardPurple,
        ),
      ],
    );
  }
}
