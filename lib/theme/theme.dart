import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff4f378a),
      surfaceTint: Color(0xff6750a4),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff6750a4),
      onPrimaryContainer: Color(0xffe0d2ff),
      secondary: Color(0xff63597c),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffe1d4fd),
      onSecondaryContainer: Color(0xff645a7d),
      tertiary: Color(0xff762a5b),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff924274),
      onTertiaryContainer: Color(0xffffcae5),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffdf7ff),
      onSurface: Color(0xff1d1b20),
      onSurfaceVariant: Color(0xff494551),
      outline: Color(0xff7a7582),
      outlineVariant: Color(0xffcbc4d2),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff322f35),
      inversePrimary: Color(0xffcfbcff),
      primaryFixed: Color(0xffe9ddff),
      onPrimaryFixed: Color(0xff22005d),
      primaryFixedDim: Color(0xffcfbcff),
      onPrimaryFixedVariant: Color(0xff4f378a),
      secondaryFixed: Color(0xffe9ddff),
      onSecondaryFixed: Color(0xff1f1635),
      secondaryFixedDim: Color(0xffcdc0e9),
      onSecondaryFixedVariant: Color(0xff4b4263),
      tertiaryFixed: Color(0xffffd8ea),
      onTertiaryFixed: Color(0xff3c002b),
      tertiaryFixedDim: Color(0xffffaedb),
      onTertiaryFixedVariant: Color(0xff752a5b),
      surfaceDim: Color(0xffded8e0),
      surfaceBright: Color(0xfffdf7ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff8f2fa),
      surfaceContainer: Color(0xfff2ecf4),
      surfaceContainerHigh: Color(0xffece6ee),
      surfaceContainerHighest: Color(0xffe6e0e9),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff3e2578),
      surfaceTint: Color(0xff6750a4),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff6750a4),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff3a3151),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff72688b),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff61184a),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff924274),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffdf7ff),
      onSurface: Color(0xff121016),
      onSurfaceVariant: Color(0xff383440),
      outline: Color(0xff55505d),
      outlineVariant: Color(0xff706b78),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff322f35),
      inversePrimary: Color(0xffcfbcff),
      primaryFixed: Color(0xff765fb4),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff5d4699),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff72688b),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff595072),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xffa35083),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff86386a),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffcac5cc),
      surfaceBright: Color(0xfffdf7ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff8f2fa),
      surfaceContainer: Color(0xffece6ee),
      surfaceContainerHigh: Color(0xffe1dbe3),
      surfaceContainerHighest: Color(0xffd5d0d8),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff33196e),
      surfaceTint: Color(0xff6750a4),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff513a8d),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff302747),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff4d4465),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff540c3f),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff782d5e),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffdf7ff),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff2e2a35),
      outlineVariant: Color(0xff4b4753),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff322f35),
      inversePrimary: Color(0xffcfbcff),
      primaryFixed: Color(0xff513a8d),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff3a2174),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff4d4465),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff362e4d),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff782d5e),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff5d1446),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffbcb7bf),
      surfaceBright: Color(0xfffdf7ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff5eff7),
      surfaceContainer: Color(0xffe6e0e9),
      surfaceContainerHigh: Color(0xffd8d2da),
      surfaceContainerHighest: Color(0xffcac5cc),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffcfbcff),
      surfaceTint: Color(0xffcfbcff),
      onPrimary: Color(0xff381e72),
      primaryContainer: Color(0xff6750a4),
      onPrimaryContainer: Color(0xffe0d2ff),
      secondary: Color(0xffcdc0e9),
      onSecondary: Color(0xff342b4b),
      secondaryContainer: Color(0xff4d4465),
      onSecondaryContainer: Color(0xffbfb2da),
      tertiary: Color(0xffffaedb),
      onTertiary: Color(0xff5a1243),
      tertiaryContainer: Color(0xff924274),
      onTertiaryContainer: Color(0xffffcae5),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff141218),
      onSurface: Color(0xffe6e0e9),
      onSurfaceVariant: Color(0xffcbc4d2),
      outline: Color(0xff948e9c),
      outlineVariant: Color(0xff494551),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe6e0e9),
      inversePrimary: Color(0xff6750a4),
      primaryFixed: Color(0xffe9ddff),
      onPrimaryFixed: Color(0xff22005d),
      primaryFixedDim: Color(0xffcfbcff),
      onPrimaryFixedVariant: Color(0xff4f378a),
      secondaryFixed: Color(0xffe9ddff),
      onSecondaryFixed: Color(0xff1f1635),
      secondaryFixedDim: Color(0xffcdc0e9),
      onSecondaryFixedVariant: Color(0xff4b4263),
      tertiaryFixed: Color(0xffffd8ea),
      onTertiaryFixed: Color(0xff3c002b),
      tertiaryFixedDim: Color(0xffffaedb),
      onTertiaryFixedVariant: Color(0xff752a5b),
      surfaceDim: Color(0xff141218),
      surfaceBright: Color(0xff3b383e),
      surfaceContainerLowest: Color(0xff0f0d13),
      surfaceContainerLow: Color(0xff1d1b20),
      surfaceContainer: Color(0xff211f24),
      surfaceContainerHigh: Color(0xff2b292f),
      surfaceContainerHighest: Color(0xff36343a),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffe3d6ff),
      surfaceTint: Color(0xffcfbcff),
      onPrimary: Color(0xff2c1067),
      primaryContainer: Color(0xff9a83db),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffe3d6ff),
      onSecondary: Color(0xff292140),
      secondaryContainer: Color(0xff968bb1),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffffcfe7),
      onTertiary: Color(0xff4c0438),
      tertiaryContainer: Color(0xffcd73a8),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff141218),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffe1dae8),
      outline: Color(0xffb6afbd),
      outlineVariant: Color(0xff948e9b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe6e0e9),
      inversePrimary: Color(0xff50398b),
      primaryFixed: Color(0xffe9ddff),
      onPrimaryFixed: Color(0xff160042),
      primaryFixedDim: Color(0xffcfbcff),
      onPrimaryFixedVariant: Color(0xff3e2578),
      secondaryFixed: Color(0xffe9ddff),
      onSecondaryFixed: Color(0xff140b2a),
      secondaryFixedDim: Color(0xffcdc0e9),
      onSecondaryFixedVariant: Color(0xff3a3151),
      tertiaryFixed: Color(0xffffd8ea),
      onTertiaryFixed: Color(0xff29001d),
      tertiaryFixedDim: Color(0xffffaedb),
      onTertiaryFixedVariant: Color(0xff61184a),
      surfaceDim: Color(0xff141218),
      surfaceBright: Color(0xff46434a),
      surfaceContainerLowest: Color(0xff08070b),
      surfaceContainerLow: Color(0xff1f1d22),
      surfaceContainer: Color(0xff29272d),
      surfaceContainerHigh: Color(0xff343138),
      surfaceContainerHighest: Color(0xff3f3c43),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfff5edff),
      surfaceTint: Color(0xffcfbcff),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffccb8ff),
      onPrimaryContainer: Color(0xff0f0033),
      secondary: Color(0xfff5edff),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffc9bde5),
      onSecondaryContainer: Color(0xff0e0624),
      tertiary: Color(0xffffebf3),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffffa8d9),
      onTertiaryContainer: Color(0xff1f0015),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff141218),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xfff5edfc),
      outlineVariant: Color(0xffc7c0ce),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe6e0e9),
      inversePrimary: Color(0xff50398b),
      primaryFixed: Color(0xffe9ddff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffcfbcff),
      onPrimaryFixedVariant: Color(0xff160042),
      secondaryFixed: Color(0xffe9ddff),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffcdc0e9),
      onSecondaryFixedVariant: Color(0xff140b2a),
      tertiaryFixed: Color(0xffffd8ea),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffffaedb),
      onTertiaryFixedVariant: Color(0xff29001d),
      surfaceDim: Color(0xff141218),
      surfaceBright: Color(0xff524f55),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff211f24),
      surfaceContainer: Color(0xff322f35),
      surfaceContainerHigh: Color(0xff3d3a41),
      surfaceContainerHighest: Color(0xff48464c),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.background,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
