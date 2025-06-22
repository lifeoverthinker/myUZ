import 'package:flutter/material.dart';
import '../../theme/fonts.dart';
import '../../theme/theme.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

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
            icon: const Icon(Icons.chevron_left, color: iconColor),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Wróć',
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'O aplikacji',
            style: AppTextStyles.sectionHeader(context),
          ),
        ),
        centerTitle: false,
        actions: [const SizedBox(width: 16)],
      ),
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(24),
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
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo_uz.png',
                  height: 64,
                  width: 64,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  'MyUZ',
                  style: AppTextStyles.cardTitle(
                    context,
                  ).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aplikacja mobilna dla studentów i nauczycieli Uniwersytetu Zielonogórskiego, umożliwiająca szybkie przeglądanie i porównywanie planów zajęć.',
                  style: AppTextStyles.cardDescription(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Wersja 1.0.0',
                  style: AppTextStyles.cardDescription(context),
                ),
                const SizedBox(height: 6),
                Text(
                  'Projekt rozwijany w celach edukacyjnych',
                  style: AppTextStyles.cardDescription(
                    context,
                  ).copyWith(fontSize: 12, color: kGreyText),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
