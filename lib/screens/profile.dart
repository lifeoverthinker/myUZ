import 'package:flutter/material.dart';

// Kolory Material Theme Builder 2024
const List<Color> materialPalette = [
  Color(0xFF6750A4), // Blue/Purple
  Color(0xFF006E2C), // Green
  Color(0xFFFFD600), // Yellow/Gold
  Color(0xFFE46962), // Pink
  Color(0xFFFF8A00), // Orange
  Color(0xFFB3261E), // Red
];

class ProfileScreen extends StatelessWidget {
  final String name;
  final String initials;
  final bool isDarkMode;
  final int selectedTheme;
  final void Function(int) onThemeSelected;
  final void Function(bool) onDarkModeChanged;
  final VoidCallback onStudentDataTap;

  const ProfileScreen({
    Key? key,
    this.name = "Imię i Nazwisko",
    this.initials = "MN",
    this.isDarkMode = false,
    this.selectedTheme = 0,
    required this.onThemeSelected,
    required this.onDarkModeChanged,
    required this.onStudentDataTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mainColor = materialPalette[selectedTheme];
    final surface = isDarkMode ? Colors.grey[900]! : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final bgAccent = mainColor.withOpacity(0.09);

    return Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        child: Column(
          children: [
            // Górny header (jak classroom)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 36, bottom: 24),
              decoration: BoxDecoration(
                color: bgAccent,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: mainColor,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 21,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: onStudentDataTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Text(
                        "Dane studenta",
                        style: TextStyle(
                          fontSize: 14,
                          color: mainColor,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                children: [
                  // Motyw aplikacji (karta)
                  Card(
                    elevation: 0,
                    color: isDarkMode ? mainColor.withOpacity(0.13) : mainColor.withOpacity(0.07),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.palette_outlined, size: 22),
                          const SizedBox(width: 12),
                          Text(
                            "Motyw aplikacji",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          _ThemeRow(
                            palette: materialPalette,
                            selected: selectedTheme,
                            onChanged: onThemeSelected,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Dark mode (karta)
                  Card(
                    elevation: 0,
                    color: isDarkMode ? mainColor.withOpacity(0.13) : mainColor.withOpacity(0.07),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: SwitchListTile(
                      value: isDarkMode,
                      onChanged: onDarkModeChanged,
                      title: Text(
                        "Tryb ciemny",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                      secondary: Icon(Icons.dark_mode, color: mainColor),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      activeColor: mainColor,
                    ),
                  ),
                  // Tu można dodać inne ustawienia, np. powiadomienia/offline
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final List<Color> palette;
  final int selected;
  final void Function(int) onChanged;

  const _ThemeRow({
    required this.palette,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: palette.asMap().entries.map((entry) {
        final idx = entry.key;
        final color = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.5),
          child: GestureDetector(
            onTap: () => onChanged(idx),
            child: CircleAvatar(
              radius: selected == idx ? 15 : 13,
              backgroundColor: color,
              child: selected == idx
                  ? const Icon(Icons.check, color: Colors.white, size: 17)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}