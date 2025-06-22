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
    // Główny kolor na podstawie wybranego motywu
    final int selectedColorIdx = userProfile.selectedThemeColor;
    final Color mainColor = kMaterialPalette[selectedColorIdx];

    return Scaffold(
      backgroundColor: kPanelBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // --- AppBar z napisem "Konto" i ikoną Ustawień ---
            SliverAppBar(
              backgroundColor: kPanelBackground,
              elevation: 0,
              automaticallyImplyLeading: false,
              toolbarHeight: 56,
              titleSpacing: 16,
              title: Text(
                'Konto',
                style: AppTextStyles.profileSectionTitle(context)
                    .copyWith(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8),
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
                      icon: const Icon(
                        MyUzIcons.settings,
                        color: Color(0xFF1D192B),
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsScreen()),
                        );
                      },
                      splashRadius: 24,
                      padding: const EdgeInsets.all(8),
                      tooltip: 'Ustawienia',
                    ),
                  ),
                ),
              ],
            ),

            // --- Avatar i imię i nazwisko ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 24),
                child: Center(
                  child: ValueListenableBuilder(
                    valueListenable: userProfile.initialsNotifier,
                    builder: (context, _, __) =>
                        ProfileAvatarName(userName: userProfile.fullName),
                  ),
                ),
              ),
            ),

            // --- Nagłówek sekcji "Moje kierunki" ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Moje kierunki',
                  style: AppTextStyles.profileSectionTitle(context).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // --- Karty z kierunkami/studiami ---
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
                      children: grupy.asMap().entries.map((entry) {
                        final group = entry.value;
                        final idx = entry.key;
                        // Rok III dla pierwszej, Rok II dla pozostałych
                        final rok = idx == 0 ? 'Rok III' : 'Rok II';
                        final dotColor = kMaterialPalette[idx % kMaterialPalette.length];
                        return _groupSummaryCard(
                            context, group, dotColor, rok);
                      }).toList(),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  /// Karta z podsumowaniem jednego kierunku
  Widget _groupSummaryCard(BuildContext context, GroupProfile group,
      Color dotColor, String rokStudiow) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Nagłówek z kropką, nazwą i badge rocznika
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.kierunek,
                  style: AppTextStyles.cardTitle(context)
                      .copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kAvatarZajecia.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rokStudiow,
                  style: AppTextStyles.cardDescription(context)
                      .copyWith(color: kAvatarZajecia, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Wydział
          Text('Wydział',
              style: AppTextStyles.cardDescription(context)
                  .copyWith(color: kGreyText, fontSize: 12)),
          Text(group.wydzial,
              style: AppTextStyles.cardTitle(context).copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          // Grupa, Podgrupa, Tryb
          Row(
            children: [
              _profileInfoLabelValue(context, 'Grupa', group.kodGrupy),
              const SizedBox(width: 24),
              _profileInfoLabelValue(context, 'Podgrupa', group.podgrupa),
              const SizedBox(width: 24),
              _profileInfoLabelValue(
                  context, 'Tryb', group.trybStudiow),
            ],
          ),
        ],
      ),
    );
  }

  /// Karta informująca o braku grup
  Widget _emptyGroupCard(BuildContext context, Color mainColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mainColor.withOpacity(0.15), width: 1),
      ),
      child: Center(
        child: Text(
          'Brak przypisanej grupy.\nDodaj grupę w ustawieniach.',
          textAlign: TextAlign.center,
          style:
          AppTextStyles.cardDescription(context).copyWith(fontSize: 16),
        ),
      ),
    );
  }

  /// Pomocniczy widget label+value (np. Grupa: 23INF-SP)
  Widget _profileInfoLabelValue(
      BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.cardDescription(context)
                  .copyWith(color: kGreyText, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.cardTitle(context).copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}
