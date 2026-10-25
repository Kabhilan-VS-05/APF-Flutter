import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - Clean, Modern Pediatric Healthcare
  static const Color primary = Color(0xFF2563EB); // Vibrant Medical Blue
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFFEFF6FF); // Soft Blue Tint
  
  static const Color secondary = Color(0xFF0D9488); // Pediatric Teal / Calming Sage
  static const Color secondaryLight = Color(0xFFF0FDFA);
  
  static const Color accentPurple = Color(0xFF7C3AED); // Assessments & Milestones
  static const Color accentPurpleLight = Color(0xFFF5F3FF);
  
  static const Color accentAmber = Color(0xFFD97706); // Notes & Highlights
  static const Color accentAmberLight = Color(0xFFFFFBEB);

  static const Color accentRose = Color(0xFFE11D48);
  static const Color accentRoseLight = Color(0xFFFFF1F2);

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC); // Clean Slate Off-White
  static const Color surface = Color(0xFFFFFFFF); // Pure Card White
  static const Color surfaceSubtle = Color(0xFFF1F5F9);
  
  // Typography Colors
  static const Color textPrimary = Color(0xFF0F172A); // High Contrast Dark Slate
  static const Color textSecondary = Color(0xFF475569); // Muted Body Slate
  static const Color textMuted = Color(0xFF94A3B8); // Light Caption Slate
  
  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocus = Color(0xFF3B82F6);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFF59E0B);

  // Reusable Soft Shadows for a Friendly, Elevated Feel
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF2563EB).withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Reusable Input Field Decoration
  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(
        color: textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(
        color: textMuted,
        fontSize: 14,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: borderFocus, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: error),
      ),
    );
  }

  // Unified Light Material 3 Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
        surfaceContainerLow: background,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// Background Aura Widget for Clean, Modern Pages
class LightAuraBackground extends StatelessWidget {
  final Widget child;

  const LightAuraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Stack(
        children: [
          // Gentle ambient color orbs
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.08),
                    AppTheme.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.secondary.withValues(alpha: 0.08),
                    AppTheme.secondary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
