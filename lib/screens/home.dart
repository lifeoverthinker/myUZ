import 'package:flutter/material.dart';
import '../theme/fonts.dart';
import '../theme/theme.dart';
import '../components/cards/ZajeciaCard.dart';
import '../components/cards/ZadaniaCard.dart';
import '../components/cards/WydarzeniaCard.dart';
import '../components/cards/zajecia_details_modal.dart';
import '../services/supabase_service.dart';
import '../my_uz_icons.dart';
import '../components/profile/user_profile.dart';
import '../components/profile/group_profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  String? wydzial;
  bool loadingWydzial = false;

  @override
  void initState() {
    super.initState();
    userProfile.kodGrupy.addListener(_onKodGrupyChanged);
    if (userProfile.kodGrupy.value.isNotEmpty) {
      fetchWydzial(userProfile.kodGrupy.value);
    }
  }

  @override
  void dispose() {
    userProfile.kodGrupy.removeListener(_onKodGrupyChanged);
    super.dispose();
  }

  void _onKodGrupyChanged() {
    final kod = userProfile.kodGrupy.value;
    if (kod.isNotEmpty) {
      fetchWydzial(kod);
    } else {
      setState(() {
        wydzial = null;
      });
    }
  }

  Future fetchWydzial(String kodGrupy) async {
    setState(() => loadingWydzial = true);
    final info = await _supabaseService.fetchKierunekWydzialForGroupByKod(
      kodGrupy,
    );
    setState(() {
      wydzial = info['wydzial'];
      loadingWydzial = false;
    });
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final weekdays = [
      'Poniedziałek',
      'Wtorek',
      'Środa',
      'Czwartek',
      'Piątek',
      'Sobota',
      'Niedziela',
    ];
    final months = [
      'stycznia',
      'lutego',
      'marca',
      'kwietnia',
      'maja',
      'czerwca',
      'lipca',
      'sierpnia',
      'września',
      'października',
      'listopada',
      'grudnia',
    ];
    final weekdayIndex = now.weekday - 1;
    return '${weekdays[weekdayIndex]}, ${now.day} ${months[now.month - 1]}';
  }

  String _formatTime(dynamic od, dynamic do_) {
    if (od == null || do_ == null) return '';
    try {
      final start = TimeOfDay.fromDateTime(DateTime.parse(od.toString()));
      final end = TimeOfDay.fromDateTime(DateTime.parse(do_.toString()));
      return '${start.format(context)} - ${end.format(context)}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildTopSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _getCurrentDate(),
            style: AppTextStyles.dateTopSectionText(context),
          ),
          Row(
            children: [
              Container(
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
                    MyUzIcons.map,
                    color: Color(0xFF1D192B),
                    size: 24,
                  ),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 6),
              Stack(
                children: [
                  Container(
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
                        MyUzIcons.mail,
                        color: Color(0xFF1D192B),
                        size: 24,
                      ),
                      onPressed: () {},
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const ShapeDecoration(
                        color: Color(0xFFB3261E),
                        shape: OvalBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingSection(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: userProfile.initialsNotifier,
      builder: (context, _, __) {
        return ValueListenableBuilder(
          valueListenable: userProfile.kodGrupy,
          builder: (context, kodGrupy, _) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cześć, ${userProfile.imie} 👋',
                    style: AppTextStyles.welcomeText(context),
                  ),
                  const SizedBox(height: 4),
                  loadingWydzial
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(
                        kodGrupy.isNotEmpty &&
                                wydzial != null &&
                                wydzial!.isNotEmpty
                            ? 'UZ, $wydzial'
                            : 'UZ, -',
                        style: AppTextStyles.kierunekText(context),
                      ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Stopka 2025', style: AppTextStyles.footerText(context)),
        ],
      ),
    );
  }

  Widget _buildClassesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 0, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                MyUzIcons.calendar_check,
                color: Color(0xFF1D192B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Dzisiejsze zajęcia',
                style: AppTextStyles.sectionHeader(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<List<GroupProfile>>(
            valueListenable: userProfile.grupy,
            builder: (context, grupy, _) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchAllTodayClasses(grupy),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Błąd: ${snapshot.error}');
                  }
                  final zajeciaDzisiaj = snapshot.data ?? [];
                  if (zajeciaDzisiaj.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.only(right: 16),
                      child: Text(
                        'Brak zajęć na dzisiaj',
                        style: AppTextStyles.cardDescription(context),
                      ),
                    );
                  }
                  zajeciaDzisiaj.sort(
                    (a, b) => DateTime.parse(
                      a['od'],
                    ).compareTo(DateTime.parse(b['od'])),
                  );
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(right: 16),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int i = 0; i < zajeciaDzisiaj.length; i++) ...[
                          Builder(
                            builder: (context) {
                              final rz =
                                  zajeciaDzisiaj[i]['rz']
                                      ?.toString()
                                      .toUpperCase() ??
                                  '';
                              final mainColor = userProfile
                                  .getColorForSubjectType(rz);
                              return ZajeciaCard(
                                title:
                                    zajeciaDzisiaj[i]['przedmiot']
                                        ?.toString() ??
                                    '',
                                time: _formatTime(
                                  zajeciaDzisiaj[i]['od'],
                                  zajeciaDzisiaj[i]['do_'],
                                ),
                                room:
                                    zajeciaDzisiaj[i]['miejsce']?.toString() ??
                                    '',
                                backgroundColor: mainColor,
                                dotColor: mainColor,
                                onTap:
                                    () => showZajeciaDetailsModal(
                                      context,
                                      zajeciaDzisiaj[i],
                                      backgroundColor: mainColor,
                                      dotColor: mainColor,
                                    ),
                              );
                            },
                          ),
                          if (i != zajeciaDzisiaj.length - 1)
                            const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Funkcja pobierająca zajęcia ze wszystkich grup użytkownika na dziś
  Future<List<Map<String, dynamic>>> _fetchAllTodayClasses(
    List<GroupProfile> grupy,
  ) async {
    final supabaseService = SupabaseService();
    final today = DateTime.now();
    final List<Map<String, dynamic>> all = [];
    for (final group in grupy) {
      final zaj = await supabaseService.fetchZajeciaForDay(
        today,
        group.kodGrupy,
        group.podgrupa,
      );
      all.addAll(zaj);
    }
    return all;
  }

  Widget _buildTasksSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 0, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                MyUzIcons.book_open,
                color: Color(0xFF1D192B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Zadania', style: AppTextStyles.sectionHeader(context)),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            padding: const EdgeInsets.only(right: 16),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ZadaniaCard(
                  title: 'Zadanie lorem ipsum',
                  description: 'Lorem ipsum dolor amet tempor dolor ipsum',
                  avatarText: 'Z',
                  backgroundColor: const Color(0xFFFFD8E4),
                ),
                const SizedBox(width: 8),
                ZadaniaCard(
                  title: 'Zadanie lorem ipsum',
                  description: 'Lorem ipsum dolor amet tempor dolor ipsum',
                  avatarText: 'A',
                  backgroundColor: const Color(0xFFE8DEF8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 0, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                MyUzIcons.marker_pin,
                color: Color(0xFF1D192B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Wydarzenia', style: AppTextStyles.sectionHeader(context)),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            padding: const EdgeInsets.only(right: 16),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                WydarzeniaCard(
                  title: 'Lorem ipsum',
                  description: 'Lorem ipsum dolor amet tempor dolor ipsum',
                  backgroundColor: const Color(0xFFDAF4D6),
                ),
                const SizedBox(width: 8),
                WydarzeniaCard(
                  title: 'Zadanie lorem ipsum',
                  description: 'Lorem ipsum dolor amet tempor dolor ipsum',
                  backgroundColor: const Color(0xFFDAF4D6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClassesSection(context),
            _buildTasksSection(context),
            _buildEventsSection(context),
            const SizedBox(height: 10),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopSection(context),
            _buildGreetingSection(context),
            Expanded(child: _buildMainSection(context)),
          ],
        ),
      ),
    );
  }
}
