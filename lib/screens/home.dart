import 'package:flutter/material.dart';
import '../theme/fonts.dart';
import '../components/cards/ZajeciaCard.dart';
import '../components/cards/ZadaniaCard.dart';
import '../components/cards/WydarzeniaCard.dart';
import '../services/supabase_service.dart';
import '../my_uz_icons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> zajeciaFuture;

  @override
  void initState() {
    super.initState();
    zajeciaFuture = _supabaseService.fetchNajblizszeZajecia();
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
                    MyUZicons.map,
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
                        MyUZicons.mail,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cześć, Martyna 👋', style: AppTextStyles.welcomeText(context)),
          const SizedBox(height: 4),
          Text(
            'UZ, Wydział Informatyki',
            style: AppTextStyles.kierunekText(context),
          ),
        ],
      ),
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

  Widget _buildClassesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 0, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                MyUZicons.calendar_check,
                color: Color(0xFF1D192B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Najbliższe zajęcia',
                style: AppTextStyles.sectionHeader(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: zajeciaFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Błąd: ${snapshot.error}');
              }
              final zajecia = snapshot.data ?? [];
              if (zajecia.isEmpty) {
                return const Text('Brak nadchodzących zajęć');
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.only(right: 16),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < zajecia.length; i++) ...[
                      ZajeciaCard(
                        title: zajecia[i]['przedmiot']?.toString() ?? '',
                        time: _formatTime(zajecia[i]['od'], zajecia[i]['do_']),
                        room: zajecia[i]['miejsce']?.toString() ?? '',
                        avatarText:
                            (zajecia[i]['rz']?.toString() ?? '').isNotEmpty
                                ? zajecia[i]['rz'][0].toUpperCase()
                                : '?',
                        backgroundColor: const Color(0xFFE8DEF8),
                      ),
                      if (i != zajecia.length - 1) const SizedBox(width: 8),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
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
                MyUZicons.book_open,
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
                MyUZicons.marker_pin,
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
}
