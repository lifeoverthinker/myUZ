import 'package:flutter/material.dart';

class AppTextStyles {
  // Display styles
  static TextStyle displayLarge(BuildContext context) => TextStyle(
    fontSize: 28,
    height: 36/28,
    fontWeight: FontWeight.w600, // Semi-bold
    color: Theme.of(context).colorScheme.onSurface,
  );

  // Headline styles
  static TextStyle headlineMedium(BuildContext context) => TextStyle(
    fontSize: 24,
    height: 24/24,
    fontWeight: FontWeight.w500, // Medium
    color: Theme.of(context).colorScheme.onSurface,
  );

  // Title styles
  static TextStyle titleLarge(BuildContext context) => TextStyle(
    fontSize: 18,
    height: 24/18,
    fontWeight: FontWeight.w500, // Medium
    color: Theme.of(context).colorScheme.onSurface,
  );

  // Body styles
  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontSize: 14,
    height: 20/14,
    fontWeight: FontWeight.w400, // Regular
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontSize: 14,
    height: 16/14,
    fontWeight: FontWeight.w500, // Medium
    color: Theme.of(context).colorScheme.onSurface,
  );

  // Label styles
  static TextStyle labelLarge(BuildContext context) => TextStyle(
    fontSize: 12,
    height: 16/12,
    fontWeight: FontWeight.w500, // Medium
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  static TextStyle labelMedium(BuildContext context) => TextStyle(
    fontSize: 12,
    height: 24/12,
    fontWeight: FontWeight.w400, // Regular
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  static TextStyle classTypeInitial(BuildContext context) => TextStyle(
    fontSize: 16,
    fontFamily: 'Roboto',
    height: 24/16,
    fontWeight: FontWeight.w500, // Medium
    letterSpacing: 0.15,
    color: Theme.of(context).colorScheme.onPrimary,
  );

  static TextStyle calendarDayNumber(BuildContext context) => TextStyle(
    fontSize: 16,
    height: 16/16,
    fontWeight: FontWeight.w500, // Medium
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle calendarDayLetter(BuildContext context) => TextStyle(
    fontSize: 12,
    height: 16/12,
    fontWeight: FontWeight.w400, // Regular
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  static TextStyle calendarMonth(BuildContext context) => TextStyle(
    fontSize: 24,
    height: 24/24,
    fontWeight: FontWeight.w500, // Medium
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle navigationLabel(BuildContext context) => TextStyle(
    fontSize: 11,
    height: 16/11,
    fontWeight: FontWeight.w500, // Medium
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  static TextStyle classTitle(BuildContext context) => const TextStyle(
    color: Color(0xFF1D192B),
    fontSize: 14,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    height: 20/14,
    letterSpacing: 0,
  );

  static TextStyle classInfoText(BuildContext context) => const TextStyle(
    color: Color(0xFF4A4A4A),
    fontSize: 12,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    height: 16/12,
  );
}

