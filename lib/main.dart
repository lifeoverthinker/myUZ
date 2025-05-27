import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'screens/home.dart';
import 'screens/calendar.dart';
import 'screens/index.dart';
import 'screens/profile.dart';
import 'theme/fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(); // domyślnie szuka .env w katalogu głównym

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikacja Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pl', 'PL'),
      ],
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = const [
    HomeScreen(),
    CalendarScreen(),
    IndexScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color bottomNavSelectedColor = const Color(0xFF381E72);
    final Color bottomNavUnselectedColor = const Color(0xFF787579);
    final Color bottomNavStrokeColor = const Color(0xFFEDE6F3);

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: bottomNavStrokeColor,
              width: 1,
            ),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: AppTextStyles.navigationLabel(context).copyWith(height: 1.0),
            unselectedLabelStyle: AppTextStyles.navigationLabel(context).copyWith(height: 1.0),
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedItemColor: bottomNavSelectedColor,
            unselectedItemColor: bottomNavUnselectedColor,
            showUnselectedLabels: true,
            iconSize: 24,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 8),
                  child: SvgPicture.asset(
                    'assets/icons/home.svg',
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      _selectedIndex == 0 ? bottomNavSelectedColor : bottomNavUnselectedColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                label: 'Strona główna',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 8),
                  child: SvgPicture.asset(
                    'assets/icons/calendar-check.svg',
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      _selectedIndex == 1 ? bottomNavSelectedColor : bottomNavUnselectedColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                label: 'Kalendarz',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 8),
                  child: SvgPicture.asset(
                    'assets/icons/graduation-hat.svg',
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      _selectedIndex == 2 ? bottomNavSelectedColor : bottomNavUnselectedColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                label: 'Indeks',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 8),
                  child: SvgPicture.asset(
                    'assets/icons/user.svg',
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      _selectedIndex == 3 ? bottomNavSelectedColor : bottomNavUnselectedColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                label: 'Profil',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
            enableFeedback: true,
          ),
        ),
      ),
    );
  }
}
