import 'package:flutter/material.dart';

class FitTrackColors {
  static const graphiteBlack = Color(0xFF090B10);
  static const carbon = Color(0xFF11151D);
  static const darkSteel = Color(0xFF1A202B);
  static const electricLime = Color(0xFFB6FF3B);
  static const pulseCyan = Color(0xFF2EE6FF);
  static const heatOrange = Color(0xFFFF8A2A);
  static const premiumGold = Color(0xFFFFD166);
  static const snow = Color(0xFFF7F8FA);
  static const mistGray = Color(0xFFA7AFBE);
  static const steelGray = Color(0xFF6F7888);
  static const coralRed = Color(0xFFFF4D5E);
}

class FitTrackTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: FitTrackColors.graphiteBlack,
      colorScheme: const ColorScheme.dark(
        primary: FitTrackColors.electricLime,
        secondary: FitTrackColors.pulseCyan,
        tertiary: FitTrackColors.premiumGold,
        surface: FitTrackColors.carbon,
        error: FitTrackColors.coralRed,
        onPrimary: FitTrackColors.graphiteBlack,
        onSurface: FitTrackColors.snow,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: FitTrackColors.graphiteBlack,
        foregroundColor: FitTrackColors.snow,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: FitTrackColors.carbon,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FitTrackColors.carbon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: FitTrackColors.electricLime),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: FitTrackColors.graphiteBlack,
          backgroundColor: FitTrackColors.electricLime,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: FitTrackColors.snow,
        displayColor: FitTrackColors.snow,
      ),
    );
  }
}
