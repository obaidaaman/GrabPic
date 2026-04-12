// lib/utils/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Base
  static const Color bg       = Color(0xFF0D0D14);
  static const Color surface  = Color(0xFF13131F);
  static const Color card     = Color(0xFF1A1A2E);
  static const Color border   = Color(0xFF2A2A45);

  // Accent
  static const Color purple   = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFF9F5FFF);
  static const Color cyan     = Color(0xFF06B6D4);
  static const Color cyanLight = Color(0xFF22D3EE);

  // Gradients
  static const List<Color> heroGradient = [Color(0xFF7C3AED), Color(0xFF06B6D4)];
  static const List<Color> cardGradient = [Color(0xFF1A1A2E), Color(0xFF111128)];

  // Text
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted     = Color(0xFF475569);

  // Status
  static const Color success  = Color(0xFF10B981);
  static const Color error    = Color(0xFFEF4444);
  static const Color warning  = Color(0xFFF59E0B);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary:        AppColors.purple,
        secondary:      AppColors.cyan,
        surface:        AppColors.surface,
        onSurface:      AppColors.textPrimary,
        outline:        AppColors.border,
        error:          AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 56, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
          letterSpacing: -2,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
          letterSpacing: -1.5,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
          letterSpacing: -1,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, color: AppColors.textSecondary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.purple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        prefixIconColor: AppColors.textSecondary,
        errorStyle: GoogleFonts.inter(color: AppColors.error, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.purple,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.card,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: Color(0x337C3AED),
        selectedIconTheme: IconThemeData(color: AppColors.purple),
        unselectedIconTheme: IconThemeData(color: AppColors.textMuted),
        selectedLabelTextStyle: TextStyle(color: AppColors.purple, fontSize: 12),
        unselectedLabelTextStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.purple,
        unselectedItemColor: AppColors.textMuted,
      ),
    );
  }
}

// Shared widget helpers
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final List<Color> colors;

  const GradientText(this.text, {super.key, this.style, this.colors = AppColors.heroGradient});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      child: Text(text, style: style),
    );
  }
}

class GradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? width;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.isLoading = false,
    this.width,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hovered
                  ? [AppColors.purpleLight, AppColors.cyanLight]
                  : AppColors.heroGradient,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _hovered
                ? [BoxShadow(color: AppColors.purple.withOpacity(0.5), blurRadius: 24, spreadRadius: 0)]
                : [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 12, spreadRadius: 0)],
          ),
          child: Row(
            mainAxisSize: widget.width != null ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
              ],
              if (!widget.isLoading)
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;

  const GlassCard({super.key, required this.child, this.padding, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}