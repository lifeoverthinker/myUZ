import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/fonts.dart';
import '../components/ZajeciaCard.dart';
import '../components/ZadaniaCard.dart';
import '../components/WydarzeniaCard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SupabaseClient supabase;
  late Future<List<Map<String, dynamic>>> zajeciaFuture;

  @override
  void initState() {
    super.initState();
    supabase = SupabaseClient(
      dotenv.env['SUPABASE_URL']!,
      dotenv.env['SUPABASE_KEY']!, // Poprawny klucz!
    );
    zajeciaFuture = fetchNajblizszeZajecia();
  }

  Future<List<Map<String, dynamic>>> fetchNajblizszeZajecia() async {
    final response = await supabase
        .from('zajecia')
        .select('przedmiot, od, do_, miejsce, kod_grupy, rz')
        .eq('kod_grupy', '23INF-SP')
        .eq('podgrupa', 'A')
        .order('od', ascending: true)
        .limit(5);
    if (response == null) return [];
    return List<Map<String, dynamic>>.from(response);
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _getCurrentDate(),
            style: AppTextStyles.bodyMedium(context).copyWith(color: const Color(0xFF1D192B)),
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
                  icon: SvgPicture.asset(
                    'assets/icons/map.svg',
                    height: 24,
                    width: 24,
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
                      icon: SvgPicture.asset(
                        'assets/icons/mail.svg',
                        height: 24,
                        width: 24,
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
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cześć, Martyna 👋',
            style: AppTextStyles.displayLarge(context).copyWith(color: const Color(0xFF1D192B)),
          ),
          const SizedBox(height: 4),
          Text(
            'UZ, Wydział Informatyki',
            style: AppTextStyles.labelMedium(context).copyWith(color: const Color(0xFF363535)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'Stopka 2025',
        style: AppTextStyles.bodyMedium(context).copyWith(color: const Color(0xFF787579)),
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
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/calendar-check.svg',
                height: 20,
                width: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Najbliższe zajęcia',
                style: AppTextStyles.titleLarge(context),
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
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('Brak zajęć grupowych');
              }
              final zajecia = snapshot.data!;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: zajecia.map((zajecie) {
                    final title = zajecie['przedmiot'] ?? '';
                    final od = zajecie['od'] != null
                        ? TimeOfDay.fromDateTime(DateTime.parse(zajecie['od']))
                        : null;
                    final do_ = zajecie['do_'] != null
                        ? TimeOfDay.fromDateTime(DateTime.parse(zajecie['do_']))
                        : null;
                    final time = od != null && do_ != null
                        ? '${od.format(context)} - ${do_.format(context)}'
                        : '';
                    final room = zajecie['miejsce'] ?? '';
                    final avatarText = (zajecie['rz'] ?? '').isNotEmpty
                        ? zajecie['rz'][0].toUpperCase()
                        : '?';
                    final backgroundColor = const Color(0xFFE8DEF8);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ZajeciaCard(
                        title: title,
                        time: time,
                        room: room,
                        avatarText: avatarText,
                        backgroundColor: backgroundColor,
                      ),
                    );
                  }).toList(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/book-open.svg',
                height: 20,
                width: 20,
              ),
              const SizedBox(width: 8),
              Text('Zadania', style: AppTextStyles.titleLarge(context)),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/marker-pin.svg',
                height: 20,
                width: 20,
              ),
              const SizedBox(width: 8),
              Text('Wydarzenia', style: AppTextStyles.titleLarge(context)),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
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
