import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../theme/fonts.dart';
import '../components/profile/user_profile.dart' show userProfile;
import '../components/profile/profile_avatar_name.dart';
import '../my_uz_icons.dart';
import '../components/profile/group_profile.dart';
import '../components/settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    // Dynamiczny kolor motywu użytkownika
    final int selectedColorIdx = userProfile.selectedThemeColor;
    final Color mainColor = kMaterialPalette[selectedColorIdx];

    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // AppBar
                SliverAppBar(
                  backgroundColor: kWhite,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  pinned: false,
                  toolbarHeight: 56,
                  titleSpacing: 24,
                  title: Text(
                    'Konto',
                    style: AppTextStyles.profileSectionTitle(
                      context,
                    ).copyWith(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                ),
                // Avatar + imię i nazwisko
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32, bottom: 24),
                    child: Center(
                      child: ValueListenableBuilder(
                        valueListenable: userProfile.initialsNotifier,
                        builder: (context, _, __) {
                          return ProfileAvatarName(
                            userName: userProfile.fullName,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Karty podsumowania dla każdej grupy/kierunku
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ValueListenableBuilder<List<GroupProfile>>(
                      valueListenable: userProfile.grupy,
                      builder: (context, grupy, _) {
                        if (grupy.isEmpty) {
                          return _emptyGroupCard(context, mainColor);
                        }
                        return Column(
                          children:
                              grupy
                                  .map(
                                    (group) => _groupSummaryCard(
                                      context,
                                      group,
                                      mainColor,
                                    ),
                                  )
                                  .toList(),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
            // Ikona ustawień na fioletowym (motywowym) kółku w prawym górnym rogu
            Positioned(
              top: 18,
              right: 18,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFE8DEF8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      MyUzIcons.settings_02_svgrepo_com,
                      color: const Color(0xFF1D192B),
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    splashRadius: 24,
                    padding: const EdgeInsets.all(8),
                    tooltip: 'Ustawienia',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupSummaryCard(
    BuildContext context,
    GroupProfile group,
    Color mainColor,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mainColor.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _profileInfoRow(context, 'Wydział', group.wydzial),
          const SizedBox(height: 12),
          _profileInfoRow(context, 'Kierunek', group.kierunek),
          const SizedBox(height: 12),
          _profileInfoRow(context, 'Grupa', group.kodGrupy),
          const SizedBox(height: 12),
          _profileInfoRow(context, 'Podgrupa', group.podgrupa),
          const SizedBox(height: 12),
          _profileInfoRow(context, 'Tryb studiów', group.trybStudiow),
        ],
      ),
    );
  }

  Widget _emptyGroupCard(BuildContext context, Color mainColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mainColor.withOpacity(0.15), width: 1),
      ),
      child: Center(
        child: Text(
          'Brak przypisanej grupy.\nDodaj grupę w ustawieniach.',
          textAlign: TextAlign.center,
          style: AppTextStyles.cardDescription(context).copyWith(fontSize: 16),
        ),
      ),
    );
  }

  Widget _profileInfoRow(BuildContext context, String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.cardDescription(
            context,
          ).copyWith(color: kMainText.withOpacity(0.7), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value?.isNotEmpty == true ? value! : 'Nie wybrano',
          style: AppTextStyles.cardTitle(context).copyWith(fontSize: 16),
        ),
      ],
    );
  }
}
