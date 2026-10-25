import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'parent_dashboard.dart';
import 'therapist_dashboard.dart';
import 'signup_page.dart';
import 'theme/app_theme.dart';

class CommonLoginPage extends StatefulWidget {
  final String? role;
  const CommonLoginPage({super.key, this.role = 'Parent'});

  @override
  State<CommonLoginPage> createState() => _CommonLoginPageState();
}

class _CommonLoginPageState extends State<CommonLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final input = _emailOrUsernameController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final userCredential = await authService.signIn(
        emailOrUsername: input,
        password: password,
      );

      if (userCredential != null) {
        if (!mounted) return;
        final userRole = await authService.getUserRole(userCredential.user!.uid);
        if (!mounted) return;

        if (userRole == 'Parent') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ParentDashboard()),
          );
        } else if (userRole == 'Therapist') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TherapistDashboard()),
          );
        } else {
          // Default fallback based on initial selection
          final effectiveRole = widget.role ?? 'Parent';
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => effectiveRole == 'Therapist'
                  ? const TherapistDashboard()
                  : const ParentDashboard(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final input = _emailOrUsernameController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your email to reset password'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
      return;
    }

    try {
      final authService = AuthService();
      await authService.resetPassword(input);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset instructions sent to your email!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRole = widget.role ?? 'Parent';
    final isParent = effectiveRole == 'Parent';
    final roleColor = isParent ? AppTheme.primary : const Color(0xFF0D9488);
    final roleBgColor = isParent ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4);
    final roleBorderColor = isParent ? const Color(0xFFBFDBFE) : const Color(0xFFA7F3D0);
    final roleIcon = isParent ? Icons.family_restroom_rounded : Icons.medical_services_rounded;
    final roleTitle = isParent ? "Parent / Caregiver" : "Pediatric Therapist";
    final roleSubtitle = isParent
        ? "Enter your registered credentials to access your child's profile"
        : "Enter your clinical credentials to access your therapist workspace";

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: LightAuraBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Medical App Logo Badge in Role Color
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: roleBgColor,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: roleBorderColor, width: 1.5),
                  ),
                  child: Icon(
                    roleIcon,
                    size: 40,
                    color: roleColor,
                  ),
                ),

                const SizedBox(height: 16),

                // Role Header Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: roleBgColor,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: roleBorderColor, width: 1.2),
                  ),
                  child: Text(
                    "${roleTitle.toUpperCase()} PORTAL",
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: roleColor,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  "$roleTitle Sign In",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  roleSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 28),

                // Login Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: AppTheme.border),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email / Username Field
                        TextFormField(
                          controller: _emailOrUsernameController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            labelText: "Email or Username",
                            hintText: "Enter your email or username",
                            prefixIcon: Icon(Icons.person_outline_rounded, color: roleColor, size: 20),
                            labelStyle: const TextStyle(color: AppTheme.textSecondary),
                            hintStyle: const TextStyle(color: AppTheme.textMuted),
                            filled: true,
                            fillColor: AppTheme.surfaceSubtle,
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(color: AppTheme.border),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(color: AppTheme.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(color: roleColor, width: 1.8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email or username';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            labelText: "Password",
                            hintText: "Enter your password",
                            prefixIcon: Icon(Icons.lock_outline_rounded, color: roleColor, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppTheme.textMuted,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            labelStyle: const TextStyle(color: AppTheme.textSecondary),
                            hintStyle: const TextStyle(color: AppTheme.textMuted),
                            filled: true,
                            fillColor: AppTheme.surfaceSubtle,
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(color: AppTheme.border),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(color: AppTheme.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(color: roleColor, width: 1.8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 8),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetPassword,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Forgot password?",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: roleColor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Sign In Button in Role Color
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: roleColor,
                              disabledBackgroundColor: roleColor.withValues(alpha: 0.6),
                              elevation: 0,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Sign In",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sign Up Link Row directed to the role's signup page
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignupPage(role: effectiveRole),
                          ),
                        );
                      },
                      child: Text(
                        "Sign Up Here",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: roleColor,
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
