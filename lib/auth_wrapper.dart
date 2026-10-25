import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'common_login_page.dart';
import 'therapist_dashboard.dart';
import 'parent_dashboard.dart';
import 'theme/app_theme.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const DashboardRouter();
        } else {
          return const LoginOrRegister();
        }
      },
    );
  }
}

class DashboardRouter extends StatefulWidget {
  const DashboardRouter({super.key});

  @override
  State<DashboardRouter> createState() => _DashboardRouterState();
}

class _DashboardRouterState extends State<DashboardRouter> {
  final AuthService _authService = AuthService();
  String? _userRole;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _needsRoleSelection = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _needsRoleSelection = false;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await _authService.getUserRole(user.uid).timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
        final userData = await _authService.getUserData(user.uid).timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );

        if (role == null) {
          // User exists in Firebase Auth but has no Firestore profile / role
          // Allow them to pick role and complete setup immediately!
          if (mounted) {
            setState(() {
              _userRole = null;
              _needsRoleSelection = true;
              _isLoading = false;
            });
          }
          return;
        }

        if (mounted) {
          setState(() {
            _userRole = role;
            _userData = userData;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text("Loading profile..."),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text("Cancel & Sign Out"),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  "Error loading user profile:\n$_errorMessage",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadUserRole,
                  child: const Text("Retry"),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  child: const Text("Sign Out & Return to Login"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_needsRoleSelection) {
      return ProfileRoleSetupScreen(
        onRoleSelected: (role) {
          setState(() {
            _userRole = role;
            _needsRoleSelection = false;
          });
        },
      );
    }

    switch (_userRole) {
      case 'Therapist':
        return const TherapistDashboard();
      case 'Parent':
        return const ParentDashboard();
      default:
        return const LoginOrRegister();
    }
  }
}

class ProfileRoleSetupScreen extends StatefulWidget {
  final Function(String role) onRoleSelected;

  const ProfileRoleSetupScreen({super.key, required this.onRoleSelected});

  @override
  State<ProfileRoleSetupScreen> createState() => _ProfileRoleSetupScreenState();
}

class _ProfileRoleSetupScreenState extends State<ProfileRoleSetupScreen> {
  bool _isSaving = false;

  Future<void> _selectRole(String role) async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email ?? '',
          'username': user.email?.split('@')[0] ?? 'User',
          'role': role,
          'phone': '',
          'panCard': '',
          'address': '',
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        }, SetOptions(merge: true));

        widget.onRoleSelected(role);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save role: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Complete Account Setup"),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text("Sign Out"),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LightAuraBackground(
        child: _isSaving
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.badge_outlined, size: 42, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Welcome, ${user?.email?.split('@')[0] ?? 'User'}!",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Please select your portal role to finish initializing your account:",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Role Selection Cards
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _selectRole('Parent'),
                                borderRadius: BorderRadius.zero,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.zero,
                                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5),
                                    boxShadow: AppTheme.cardShadow,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primaryLight,
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        child: const Icon(Icons.family_restroom_rounded, size: 36, color: AppTheme.primary),
                                      ),
                                      const SizedBox(height: 14),
                                      const Text(
                                        "Parent",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Track Child Milestones",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _selectRole('Therapist'),
                                borderRadius: BorderRadius.zero,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.zero,
                                    border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3), width: 1.5),
                                    boxShadow: AppTheme.cardShadow,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.secondaryLight,
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        child: const Icon(Icons.medical_services_rounded, size: 36, color: AppTheme.secondary),
                                      ),
                                      const SizedBox(height: 14),
                                      const Text(
                                        "Therapist",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Clinical Workspace",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class LoginOrRegister extends StatelessWidget {
  const LoginOrRegister({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommonLoginPage();
  }
}
