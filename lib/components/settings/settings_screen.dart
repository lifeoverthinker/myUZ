import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../theme/fonts.dart';
import '../profile/user_profile.dart' show userProfile;
import 'groups_section.dart';
import 'subject_colors_section.dart';
import 'about_section.dart';
import '../../my_uz_icons.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color iconColor = Color(0xFF1D192B);

    return Scaffold(
      backgroundColor: kPanelBackground,
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
            'Ustawienia',
            style: AppTextStyles.sectionHeader(context).copyWith(fontSize: 20),
          ),
        ),
        centerTitle: false,
        actions: [
          const SizedBox(width: 16), // padding po prawej
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _NavCard(
                icon: MyUzIcons.user,
                label: 'Imię i nazwisko',
                description: userProfile.fullName,
                onTap: () => _showEditNameDialog(context),
                iconColor: iconColor,
              ),
              const SizedBox(height: 16),
              _NavCard(
                icon: MyUzIcons.graduation_hat,
                label: 'Kierunki studiów',
                description: '${userProfile.grupy.value.length} kierunki',
                onTap: () {},
                iconColor: iconColor,
              ),
              const SizedBox(height: 16),
              _ThemeCard(iconColor: iconColor),
              const SizedBox(height: 16),
              _NavCard(
                icon: MyUzIcons.moon,
                label: 'Tryb ciemny',
                description: 'Włącz/wyłącz tryb ciemny',
                trailing: Switch(
                  value: false,
                  onChanged: (v) {},
                  activeColor: iconColor,
                ),
                onTap: () {},
                iconColor: iconColor,
              ),
              const SizedBox(height: 16),
              _NavCard(
                icon: MyUzIcons.users,
                label: 'Grupy',
                description: 'Zarządzaj grupami dla wszystkich kierunków',
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GroupsSection()),
                    ),
                iconColor: iconColor,
              ),
              const SizedBox(height: 16),
              _NavCard(
                icon: MyUzIcons.palette,
                label: 'Kolory typów zajęć',
                description: 'Dostosuj kolory',
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SubjectColorsSection()),
                    ),
                iconColor: iconColor,
              ),
              const SizedBox(height: 16),
              _NavCard(
                icon: MyUzIcons.info_circle,
                label: 'O aplikacji',
                description: 'Wersja 1.0.0',
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AboutSection()),
                    ),
                iconColor: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showEditNameDialog(BuildContext context) {
    final controller = TextEditingController(text: userProfile.fullName);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            title: Text(
              'Edytuj imię i nazwisko',
              style: AppTextStyles.cardTitle(context).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kMainText,
              ),
            ),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: kMainText),
              decoration: InputDecoration(
                labelText: 'Imię i nazwisko',
                labelStyle: const TextStyle(color: kGreyText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: kAvatarZajecia, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: kGreyText,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Anuluj',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        userProfile.setFullName(controller.text);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAvatarZajecia,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text(
                        'Zapisz',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color iconColor;

  const _NavCard({
    required this.icon,
    required this.label,
    required this.description,
    this.trailing,
    required this.onTap,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    const Color iconBg = Color(0xFFE8DEF8);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: iconBg,
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(label, style: AppTextStyles.cardTitle(context)),
        subtitle: Text(
          description,
          style: AppTextStyles.cardDescription(context),
        ),
        trailing:
            trailing ??
            Icon(MyUzIcons.chevron_right, color: iconColor, size: 20),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _ThemeCard extends StatefulWidget {
  final Color iconColor;

  const _ThemeCard({required this.iconColor});

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  int _selectedTheme = userProfile.selectedThemeColor;
  final List<Color> themeColors = [
    kCardPurple,
    kCardGreen,
    kCardYellow,
    kCardPink,
    kCardBlue,
  ];
  final List<Color> themeBorders = [
    Color(0xFFB39DDB),
    Color(0xFF81C784),
    Color(0xFFFFE082),
    Color(0xFFF8BBD0),
    Color(0xFF80CBC4),
  ];

  @override
  Widget build(BuildContext context) {
    const Color iconBg = Color(0xFFE8DEF8);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: iconBg,
                child: Icon(
                  MyUzIcons.palette,
                  color: widget.iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Motyw kolorystyczny',
                      style: AppTextStyles.cardDescription(context),
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
          Row(
            children: List.generate(themeColors.length, (i) {
              final selected = _selectedTheme == i;
              return GestureDetector(
                onTap:
                    () => setState(
                      () => userProfile.selectedThemeColor = _selectedTheme = i,
                    ),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: themeColors[i],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? themeBorders[i] : Colors.transparent,
                      width: 3,
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
