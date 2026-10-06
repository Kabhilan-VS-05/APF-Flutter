import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'common_login_page.dart';

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
    // Check if email is already verified
    _isEmailVerified = widget.user.emailVerified;
    
    // Auto-check email verification status periodically
    _checkEmailVerification();
  }

  Future<void> _checkEmailVerification() async {
    // Reload user to get latest verification status
    await widget.user.reload();
    
    if (mounted) {
      setState(() {
        _isEmailVerified = widget.user.emailVerified;
      });

      // If email is verified, navigate to login
      if (_isEmailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully! You can now login.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to login after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const CommonLoginPage()),
              (route) => false,
            );
          }
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _resendLoading = true);

    try {
      await widget.user.sendEmailVerification();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent again! Please check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend verification email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _resendLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/E1045Y1G.jpg',
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isEmailVerified ? Icons.verified : Icons.email_outlined,
                      size: 80,
                      color: _isEmailVerified ? Colors.green : const Color(0xFF003366),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isEmailVerified ? "Email Verified!" : "Verify Your Email",
                      style: TextStyle(
                        color: const Color(0xFF003366),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _isEmailVerified
                          ? "Your email has been verified successfully."
                          : "We've sent a verification email to:",
                      style: const TextStyle(
                        color: Color(0xFF003366),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.email,
                      style: const TextStyle(
                        color: Color(0xFF003366),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!_isEmailVerified) ...[
                      const SizedBox(height: 20),
                      const Text(
                        "Please check your inbox and click the verification link. If you don't see the email, check your spam folder.",
                        style: TextStyle(
                          color: Color(0xFF003366),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _resendLoading ? null : _resendVerificationEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                        child: _resendLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Resend Verification Email",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: _isLoading ? null : _checkEmailVerification,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF003366),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "I've verified my email",
                                style: TextStyle(
                                  color: Color(0xFF003366),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const CommonLoginPage()),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        "Back to Login",
                        style: TextStyle(
                          color: Color(0xFF003366),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
