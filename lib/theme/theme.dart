import 'package:flutter/material.dart';

// Komentarze sekcji nawiązujące do Figma & użycia w kodzie

// --- Kolory główne nawigacji (Figma: Navigation bar, Home, Cards) ---
const Color kNavSelected = Color(0xFF381E72); // Wybrany element nawigacji (Figma: navigation selected)
const Color kNavUnselected = Color(0xFF787579); // Nieaktywny element nawigacji (Figma: navigation unselected)
const Color kNavBorder = Color(0xFFEDE6F3); // Border nawigacji (Figma: navigation border)

// --- Kolory tekstów i sekcji głównych (Figma: Home, Cards, Index) ---
const Color kMainText = Color(0xFF1D192B); // Teksty główne, sekcje (Figma: primary text)
const Color kCardTitle = Color(0xFF222222); // Tytuły kart, IndexTitle (Figma: cardTitle/indexTitle)
const Color kCardDesc = Color(0xFF4A4A4A); // Opis w kartach (Figma: cardDescription)
const Color kSectionHeader = Color(0xFF1D192B); // Sekcja header (Figma: sectionHeader)
const Color kFooterText = Color(0xFF787579); // Tekst w stopce (Figma: footerText)
const Color kKierunekText = Color(0xFF363535); // Kierunek (Home) (Figma: kierunekText)

// --- Kolory kart / elementy tła (Figma: Cards, Index pastel cards) ---
const Color kCardPurple = Color(0xFFE8DEF8); // Card (purple) - ZajęciaCard, ZadaniaCard, Index pastel
const Color kCardPink = Color(0xFFFFD8E4); // Card (pink) - ZadaniaCard, Index pastel
const Color kCardGreen = Color(0xFFDAF4D6); // Card (green) - WydarzeniaCard, Index pastel
const Color kCardYellow = Color(0xFFFFF8E1); // Card (yellow) - Index pastel
const Color kCardBlue = Color(0xFFE6F3EC); // Card (blue/green) - Index pastel
const Color kCardRed = Color(0xFFE46962); // (Figma: materialPalette[red])
const Color kCardGold = Color(0xFFFFD600); // (Figma: materialPalette[yellow/gold])
const Color kCalendarLine = Color(0xFFEDE6F3); // pastelowy fiolet

// --- Kolory ikon i avatarów ---
const Color kAvatarZajecia = Color(0xFF6750A4); // Avatar ZajęciaCard (Figma: avatar zajecia)
const Color kAvatarZadanie = Color(0xFF7D5260); // Avatar ZadaniaCard (Figma: avatar zadanie)
const Color kIndexPrimary = Color(0xFF6750A4); // Ikony Index, AbsencesTab licznik (Figma: indexGrade)
const Color kCircleButton = Color(0xFFF7F2F9); // Figma: circle button bg
const Color kSelectedDayCircle = Color(0xFF6750A4); // Figma: selected day

// --- Kolory tła sekcji, screenów ---
const Color kBackground = kWhite; // Tło Home, sekcja listy (Figma: background)
const Color kWhite = Colors.white;
const Color kPanelBackground = Color(0xFFF8F9FA); // Kolor tła dla settings/profile (jasny szary)


// --- Kolory własne do settings_screen ---
const Color kCardBackground = kWhite; // lub inny kolor jeśli chcesz
const Color kAccent = kAvatarZajecia; // lub inny fioletowy z Twojej palety
const Color kSecondaryText = kGreyText; // lub inny szary z Twojej palety

// --- Kolory akcentów, error, powiadomienia ---
const Color kError = Color(0xFFB3261E); // Kropka powiadomień (Figma: error)
const Color kCardBorder = Color(0xFF79747E); // Border nieaktywny np. TabBarRow
const Color kActionAccent = kAvatarZajecia; // fiolet przycisku „Dodaj”[1]

// --- Kolory utility (np. szare teksty, border, inne) ---
const Color kGreyText = Color(0xFF49454F); // Tekst nieaktywny np. TabBarRow, godziny

const List kMaterialPalette = [
  kCardPurple,
  kCardGreen,
  kCardYellow,
  kCardPink,
  kCardBlue,
];

// Nazwy typów zajęć dla UI
const Map kSubjectTypeNames = {
  'W': 'Wykłady',
  'C': 'Ćwiczenia',
  'L': 'Laboratoria',
  'P': 'Projekty',
  'S': 'Seminaria',
};

// --- ThemeData uproszczony ---
// To pozwala łatwo zarządzać kolorami globalnie
ThemeData buildAppTheme({bool dark = false, int paletteIdx = 0}) {
  final primary = kMaterialPalette[paletteIdx];
  final brightness = dark ? Brightness.dark : Brightness.light;
  final surface = dark ? Colors.grey[900]! : kWhite;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Inter',
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: kWhite,
      secondary: kCardPurple,
      onSecondary: kMainText,
      error: kError,
      onError: kWhite,
      surface: surface,
      onSurface: kMainText,
    ),
    scaffoldBackgroundColor: dark ? Colors.grey[900]! : kBackground,
    canvasColor: kWhite,
  );
}
