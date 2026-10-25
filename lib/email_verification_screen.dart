import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'common_login_page.dart';
import 'theme/app_theme.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final User user;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.user,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isEmailVerified = false;
  bool _isLoading = false;
  bool _resendLoading = false;

  @override
  void initState() {
    super.initState();
    _isEmailVerified = widget.user.emailVerified;
    _checkEmailVerification(silent: true);
  }

  Future<void> _checkEmailVerification({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser ?? widget.user;
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser ?? user;

      if (mounted) {
        setState(() {
          _isEmailVerified = refreshedUser.emailVerified;
        });

        if (_isEmailVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Email verified successfully! Taking you to login...'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          );

          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const CommonLoginPage()),
                (route) => false,
              );
            }
          });
        } else if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Email not verified yet. Please click the link sent to your inbox.'),
              backgroundColor: AppTheme.warning,
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check verification status: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _resendLoading = true);

    try {
      await widget.user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New verification link sent! Please check your inbox.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend verification email: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _resendLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const CommonLoginPage()),
              (route) => false,
            );
          },
        ),
      ),
      body: LightAuraBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: _isEmailVerified ? AppTheme.successLight : AppTheme.primaryLight,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: _isEmailVerified
                            ? AppTheme.success.withValues(alpha: 0.3)
                            : AppTheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      _isEmailVerified ? Icons.verified_rounded : Icons.mark_email_unread_outlined,
                      size: 40,
                      color: _isEmailVerified ? AppTheme.success : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isEmailVerified ? "Email Verified!" : "Verify Your Email",
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEmailVerified
                        ? "Your account has been successfully verified."
                        : "We've dispatched a secure verification link to:",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Text(
                      widget.email,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (!_isEmailVerified) ...[
                    const SizedBox(height: 18),
                    const Text(
                      "Open your mail app and click the confirmation link. Be sure to check your spam or promotional folders if you don't see it within a minute.",
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _checkEmailVerification(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, size: 20, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    "I've Verified My Email",
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _resendLoading ? null : _resendVerificationEmail,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.border),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        child: _resendLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                              )
                            : const Text(
                                "Resend Verification Email",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary),
                              ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const CommonLoginPage()),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      "Back to Login Screen",
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
