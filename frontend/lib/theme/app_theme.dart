
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core Colors for TravelSense AI
  static const Color primaryColor = Color(0xFF009688);
  static const Color secondaryColor = Color(0xFFFF7043);
  static const Color backgroundColor = Color(0xFFF7F9FB);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color cardColor = Colors.white;

  // Font family names
  static final String interFont = GoogleFonts.inter().fontFamily!;
  static final String playfairFont =
      GoogleFonts.playfairDisplay().fontFamily!;

  // Global Light Theme
  static ThemeData get lightTheme {
    final TextTheme baseTextTheme = ThemeData.light().textTheme;

    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,

      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
      ),

      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontFamily: playfairFont,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontFamily: playfairFont,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontFamily: interFont,
          color: textColor,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontFamily: interFont,
          color: textColor.withValues(alpha: 0.8),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 24,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      useMaterial3: true,
    );
  }
}
