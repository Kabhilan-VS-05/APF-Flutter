import 'package:flutter/material.dart';
import 'common_login_page.dart';
import 'theme/app_theme.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Upper Half: Light Blue - Parent / Caregiver
          Expanded(
            child: _HalfScreenPortal(
              backgroundColor: const Color(0xFFEFF6FF), // Light Medical Blue
              accentColor: AppTheme.primary,
              borderColor: const Color(0xFFBFDBFE),
              icon: Icons.family_restroom_rounded,
              title: "Parent / Caregiver",
              subtitle: "Track child milestones, questionnaires & therapist updates",
              actionLabel: "Enter Parent Portal",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CommonLoginPage(role: 'Parent')),
                );
              },
            ),
          ),

          // Lower Half: Light Green - Pediatric Therapist
          Expanded(
            child: _HalfScreenPortal(
              backgroundColor: const Color(0xFFF0FDF4), // Light Clinical Green
              accentColor: const Color(0xFF0D9488), // Pediatric Teal
              borderColor: const Color(0xFFA7F3D0),
              isBottomHalf: true,
              icon: Icons.medical_services_rounded,
              title: "Pediatric Therapist",
              subtitle: "Manage patient rosters, clinical scoring & export PDF reports",
              actionLabel: "Enter Therapist Portal",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CommonLoginPage(role: 'Therapist')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HalfScreenPortal extends StatelessWidget {
  final Color backgroundColor;
  final Color accentColor;
  final Color borderColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  final bool isBottomHalf;

  const _HalfScreenPortal({
    required this.backgroundColor,
    required this.accentColor,
    required this.borderColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    this.isBottomHalf = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        splashColor: accentColor.withValues(alpha: 0.08),
        highlightColor: accentColor.withValues(alpha: 0.04),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            border: isBottomHalf
                ? const Border(
                    top: BorderSide(color: AppTheme.border, width: 1.5),
                  )
                : null,
          ),
          padding: EdgeInsets.only(
            left: 28,
            right: 28,
            top: isBottomHalf ? 24 : 64, // Extra top clearance for top half behind app bar
            bottom: isBottomHalf ? 36 : 24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Sharp Box Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: accentColor, size: 36),
              ),

              const SizedBox(height: 18),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Button / Badge with sharp edges
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: accentColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}