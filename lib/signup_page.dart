import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'common_login_page.dart';
import 'email_verification_screen.dart';
import 'theme/app_theme.dart';

class SignupPage extends StatefulWidget {
  final String? role;
  const SignupPage({super.key, this.role = 'Parent'});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _panCardController = TextEditingController();
  final _addressController = TextEditingController();
  final _workController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _panCardController.dispose();
    _addressController.dispose();
    _workController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final effectiveRole = widget.role ?? 'Parent';
      final isTherapist = effectiveRole == 'Therapist';
      final userCredential = await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
        phone: _phoneController.text.trim(),
        panCard: _panCardController.text.trim().toUpperCase(),
        address: isTherapist ? _addressController.text.trim() : '',
        role: effectiveRole,
        work: _workController.text.trim(),
      );

      if (userCredential != null) {
        await userCredential.user!.sendEmailVerification();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please check your email inbox to verify.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: _emailController.text.trim(),
              user: userCredential.user!,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        ? "Join Aura Track to start tracking child development and milestones."
        : "Join Aura Track to conduct clinical evaluations and publish reports.";

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LightAuraBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role Header Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: roleBgColor,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: roleBorderColor, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(roleIcon, size: 16, color: roleColor),
                    const SizedBox(width: 8),
                    Text(
                      "${roleTitle.toUpperCase()} REGISTRATION",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: roleColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Create $roleTitle Account",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                roleSubtitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 22),

              // Form Container
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Full Name / Username
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: "Full Name / Username",
                          hintText: isParent ? "e.g. John Doe" : "e.g. Dr. Alex Smith",
                          prefixIcon: Icon(Icons.person_outline_rounded, color: roleColor, size: 20),
                          labelStyle: const TextStyle(color: AppTheme.textSecondary),
                          hintStyle: const TextStyle(color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.surfaceSubtle,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                          enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: roleColor, width: 1.8)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          if (value.trim().length < 3) {
                            return 'Name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Email Address
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: "Email Address",
                          hintText: "e.g. name@example.com",
                          prefixIcon: Icon(Icons.alternate_email_rounded, color: roleColor, size: 20),
                          labelStyle: const TextStyle(color: AppTheme.textSecondary),
                          hintStyle: const TextStyle(color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.surfaceSubtle,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                          enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: roleColor, width: 1.8)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Phone Number
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          hintText: "10-digit mobile number",
                          prefixIcon: Icon(Icons.phone_outlined, color: roleColor, size: 20),
                          labelStyle: const TextStyle(color: AppTheme.textSecondary),
                          hintStyle: const TextStyle(color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.surfaceSubtle,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                          enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: roleColor, width: 1.8)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                            return 'Please enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // PAN Card
                      TextFormField(
                        controller: _panCardController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary, letterSpacing: 1.2),
                        decoration: InputDecoration(
                          labelText: "PAN Card Number",
                          hintText: "ABCDE1234F",
                          prefixIcon: Icon(Icons.credit_card_rounded, color: roleColor, size: 20),
                          labelStyle: const TextStyle(color: AppTheme.textSecondary),
                          hintStyle: const TextStyle(color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.surfaceSubtle,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                          enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: roleColor, width: 1.8)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your PAN card number';
                          }
                          if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value.trim().toUpperCase())) {
                            return 'Format: 5 letters + 4 digits + 1 letter (e.g. ABCDE1234F)';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      if (!isParent) ...[
                        // Hospital with Address (Mandatory for Therapist only)
                        TextFormField(
                          controller: _addressController,
                          style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            labelText: "Hospital with Address",
                            hintText: "e.g. City Pediatric Care, 12 Park Street",
                            prefixIcon: Icon(Icons.local_hospital_outlined, color: roleColor, size: 20),
                            labelStyle: const TextStyle(color: AppTheme.textSecondary),
                            hintStyle: const TextStyle(color: AppTheme.textMuted),
                            filled: true,
                            fillColor: AppTheme.surfaceSubtle,
                            border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                            enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: roleColor, width: 1.8)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter hospital with address';
                            }
                            if (value.trim().length < 5) {
                              return 'Please enter complete hospital name & address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Work / Occupation / Specialization
                      TextFormField(
                        controller: _workController,
                        style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: isParent ? "Occupation / Work" : "Clinic Specialization / Title",
                          hintText: isParent ? "e.g. Engineer, Teacher, Homemaker" : "e.g. Pediatric PT, Occupational Therapist",
                          prefixIcon: Icon(Icons.work_outline_rounded, color: roleColor, size: 20),
                          labelStyle: const TextStyle(color: AppTheme.textSecondary),
                          hintStyle: const TextStyle(color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.surfaceSubtle,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                          enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: roleColor, width: 1.8)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return isParent ? 'Please enter your occupation' : 'Please enter your specialization';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Create Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: "Create Password",
                          hintText: "At least 6 characters",
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
                          border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                          enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: roleColor, width: 1.8)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: "Confirm Password",
                          hintText: "Re-enter your password",
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: roleColor, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppTheme.textMuted,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          labelStyle: const TextStyle(color: AppTheme.textSecondary),
                          hintStyle: const TextStyle(color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.surfaceSubtle,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                          enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: roleColor, width: 1.8)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Submit Button in Role Color
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signup,
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
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(
                                  "Create $roleTitle Account",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Existing Account Link directed to that role's login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? ", style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => CommonLoginPage(role: effectiveRole)),
                      );
                    },
                    child: Text(
                      "Sign In",
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
