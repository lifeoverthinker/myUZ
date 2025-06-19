import 'package:flutter/material.dart';

class AppTextStyles {
  //------------ Main ------------
  static TextStyle navigationLabel(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    // Medium
    fontSize: 11,
    height: 16 / 11,
    letterSpacing: 0,
    color: Color(0xFF787579), // normal state color
    // color: Color(0xFF381E72) // selected state color
  );

  //------------ Home screen ------------

  //TopSection "wtorek, 16 lipca"
  static TextStyle dateTopSectionText(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    // Medium
    fontSize: 14,
    height: 16 / 14,
    letterSpacing: 0,
    color: Color(0xFF1D192B),
  );

  //Sekcja powitalna "Cześć, [imię]!"
  static TextStyle welcomeText(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    // Semi-bold
    fontSize: 28,
    height: 36 / 28,
    letterSpacing: 0,
    color: Color(0xFF1D192B),
  );

  //Sekcja powitalna "UZ, Wydział Informatyki"
  static TextStyle kierunekText(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    // Regular
    fontSize: 12,
    height: 24 / 12,
    letterSpacing: 0,
    color: Color(0xFF363535),
  );

  //ZajeciaCard, ZadaniaCard, WydarzeniaCard
  static TextStyle cardTitle(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    // Medium
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    color: Color(0xFF222222),
  );

  static TextStyle cardDescription(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    // Regular
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
    color: Color(0xFF4A4A4A),
  );

  //Footer "Stopka 2025"
  static TextStyle footerText(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    // Medium
    fontSize: 14,
    height: 16 / 14,
    letterSpacing: 0,
    color: Color(0xFF787579),
  );

  //Section headers "Zajęcia", "Zadania", "Wydarzenia"
  static TextStyle sectionHeader(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    // Medium
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: 0,
    color: Color(0xFF1D192B),
  );

  //Initial rodzaj zajęć "Wykład", "Ćwiczenia", "Laboratoria" i typ zadania "Zadanie", "Projekt"
  static TextStyle initialLetter(BuildContext context) => TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    // Medium
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 0.15,
    color: Theme.of(context).colorScheme.surface,
  );

  //------------ Calendar screen ------------

  //Month name "Styczeń", "Luty", etc.
  static TextStyle calendarMonthName(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    // Semi-bold
    fontSize: 24,
    height: 24 / 24,
    letterSpacing: 0,
    color: Color(0xFF1D192B),
  );

  //Day number "1", "2", etc.
  static TextStyle calendarDayNumber(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    // Medium
    fontSize: 16,
    height: 16 / 16,
    letterSpacing: 0,
    color: Color(0xFF4A4A4A),
  );

  //Hour "08:00", "09:00", etc.
  static TextStyle calendarHour(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    // Medium
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
    color: Color(0xFF4A4A4A),
  );

  //-------------- Index screen ------------

  // Index screen title "Indeks"
  static TextStyle indexTitle(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    // Semi-bold
    fontSize: 24,
    height: 48 / 24,
    letterSpacing: 0,
    color: Color(0xFF222222),
  );

  //Index category title "Oceny", "Nieobecności", etc.
  static TextStyle indexCategoryTitle(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    // Medium
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.1,
    color: Theme.of(context).colorScheme.secondary,
  );

  //Index Przedmiot title
  static TextStyle indexSubjectTitle(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    // Medium
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: 0,
    color: Color(0xFF222222),
  );

  // Styl do labeli formularzy (niepogrubione, regular)
  static TextStyle formLabel(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    // Regular
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    color: Color(0xFF222222),
  );

  //Index Średnia value
  static TextStyle indexAverageValue(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    // Medium
    fontSize: 23,
    height: 23 / 24,
    letterSpacing: 0,
    color: Color(0xFF222222),
  );

  //Index Ocena
  static TextStyle indexGrade(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    // Medium
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: 0,
    color: Color(0xFF222222),
  );

  //------------ Profile screen ------------

  // Profile initials "AB"
  static TextStyle profileInitials(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    // Medium
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: 0,
    color: Color(0xFFFFFFFF),
  );

  // Profile name "Anna Kowalska"
  static TextStyle profileName(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    // Medium
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 0,
    color: Color(0xFF222222),
  );

  // Profile section title "Moje dane", "Ustawienia", etc.
  static TextStyle profileSectionTitle(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    // Medium
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 0,
    color: Color(0xFF222222),
  );
}
