import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home.dart';
import 'screens/calendar.dart';
import 'screens/index.dart';
import 'screens/profile.dart';
import 'theme/fonts.dart';
import 'theme/theme.dart';
import 'my_uz_icons.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/user_profile_loader.dart';
import 'package:device_preview/device_preview.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_KEY']!,
  );
  await loadUserProfileFromDb();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ustawienie stylu systemowego na stały biały kolor z ciemnymi ikonami
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    return MaterialApp(
      title: 'MyUZ',
      theme: buildAppTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pl', 'PL')],
      home: const MainScreen(),
      builder: (context, child) {
        return DevicePreview.appBuilder(context, child);
      },
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
  final ScrollController _scrollController = ScrollController();

  List<Widget> get _screens => [
    const HomeScreen(),
    const CalendarScreen(),
    IndexScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = kNavSelected;
    final unselectedColor = kNavUnselected;
    final borderColor = kNavBorder;
    final navItems = [
      {'icon': MyUzIcons.home, 'label': 'Główna'},
      {'icon': MyUzIcons.calendar_check, 'label': 'Kalendarz'},
      {'icon': MyUzIcons.graduation_hat, 'label': 'Indeks'},
      {'icon': MyUzIcons.user, 'label': 'Konto'},
    ];
    return Scaffold(
      body: NotificationListener(
        onNotification: (scrollNotification) {
          return false;
        },
        child: _wrapWithScrollController(_screens[_selectedIndex]),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kWhite,
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        height: 72,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(navItems.length, (i) {
            final isSelected = i == _selectedIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _onItemTapped(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Icon(
                        navItems[i]['icon'] as IconData,
                        size: 24,
                        color: isSelected ? selectedColor : unselectedColor,
                      ),
                    ),
                    Text(
                      navItems[i]['label'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.navigationLabel(context).copyWith(
                        color: isSelected ? selectedColor : unselectedColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _wrapWithScrollController(Widget screen) {
    if (screen is HomeScreen ||
        screen is CalendarScreen ||
        screen is IndexScreen ||
        screen is ProfileScreen) {
      return Builder(
        builder:
            (context) => PrimaryScrollController(
              controller: _scrollController,
              child: screen,
            ),
      );
    }
    return screen;
  }
}
