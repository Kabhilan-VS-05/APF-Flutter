import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'main.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _panCardController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _workController = TextEditingController();

  Map<String, dynamic>? _userData;
  User? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isResettingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _panCardController.dispose();
    _addressController.dispose();
    _workController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      _currentUser = user;
      if (user != null) {
        final data = await _authService.getUserData(user.uid);
        if (mounted) {
          setState(() {
            _userData = data;
            _usernameController.text = data?['username'] ?? '';
            _phoneController.text = data?['phone'] ?? '';
            _panCardController.text = data?['panCard'] ?? '';
            _addressController.text = data?['address'] ?? '';
            _workController.text = data?['work'] ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load profile details: $e', isError: true);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;

    setState(() => _isSaving = true);

    try {
      final isTherapist = (_userData?['role'] ?? '') == 'Therapist';
      if (isTherapist) {
        String normalize(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
        final targetName = normalize(_usernameController.text);
        final targetAddress = normalize(_addressController.text);

        final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
        for (var doc in usersSnapshot.docs) {
          if (doc.id == _currentUser!.uid) continue;
          final data = doc.data();
          if ((data['role'] ?? '') != 'Therapist') continue;
          final existingName = normalize((data['username'] ?? '').toString());
          final existingAddress = normalize((data['address'] ?? '').toString());

          if (existingName.isNotEmpty &&
              existingAddress.isNotEmpty &&
              existingName == targetName &&
              existingAddress == targetAddress) {
            throw 'Another therapist account already exists with the same Name and Hospital Address.';
          }
        }
      }

      final updatedData = {
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'panCard': _panCardController.text.trim().toUpperCase(),
        'address': isTherapist ? _addressController.text.trim() : '',
        'work': _workController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _authService.updateUserData(_currentUser!.uid, updatedData);

      if (mounted) {
        _showSnackBar('Profile updated successfully!', isError: false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _currentUser?.email;
    if (email == null || email.isEmpty) {
      _showSnackBar('No email associated with this account.', isError: true);
      return;
    }

    setState(() => _isResettingPassword = true);

    try {
      await _authService.resetPassword(email);
      if (mounted) {
        _showSnackBar('Password reset instructions sent to $email', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to send reset link: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isResettingPassword = false);
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text('Confirm Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to sign out from Aura Track?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = _userData?['role'] ?? 'User';
    final isTherapist = role == 'Therapist';
    final accentColor = isTherapist ? AppTheme.secondary : AppTheme.primary;
    final lightColor = isTherapist ? AppTheme.secondaryLight : AppTheme.primaryLight;
    final userName = _usernameController.text.isNotEmpty
        ? _usernameController.text
        : (_userData?['username'] ?? 'User');
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
            tooltip: "Sign out",
            onPressed: _confirmSignOut,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : LightAuraBackground(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: AppTheme.border),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: lightColor,
                                borderRadius: BorderRadius.zero,
                                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                              ),
                              child: Center(
                                child: Text(
                                  userInitial,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: lightColor,
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        child: Text(
                                          isTherapist ? "CERTIFIED THERAPIST" : "PARENT / CAREGIVER",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                            color: accentColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    userName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _currentUser?.email ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section Title
                      const Text(
                        "Personal Information",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Editable Form Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: AppTheme.border),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Full Name / Username
                            TextFormField(
                              controller: _usernameController,
                              style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                              decoration: AppTheme.inputDecoration(
                                labelText: "Full Name / Display Name",
                                hintText: "e.g. John Doe or Dr. Sarah",
                                prefixIcon: Icon(Icons.person_outline_rounded, color: accentColor, size: 20),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Name cannot be empty';
                                }
                                if (val.trim().length < 3) {
                                  return 'Name must be at least 3 characters';
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
                              decoration: AppTheme.inputDecoration(
                                labelText: "Contact Phone Number",
                                hintText: "10-digit mobile number",
                                prefixIcon: Icon(Icons.phone_outlined, color: accentColor, size: 20),
                              ),
                              validator: (val) {
                                if (val != null && val.trim().isNotEmpty) {
                                  if (!RegExp(r'^[0-9]{10}$').hasMatch(val.trim())) {
                                    return 'Please enter a valid 10-digit phone number';
                                  }
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // PAN Card Number
                            TextFormField(
                              controller: _panCardController,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                                letterSpacing: 1.1,
                              ),
                              decoration: AppTheme.inputDecoration(
                                labelText: "PAN Card Number",
                                hintText: "ABCDE1234F",
                                prefixIcon: Icon(Icons.credit_card_rounded, color: accentColor, size: 20),
                              ),
                              validator: (val) {
                                if (val != null && val.trim().isNotEmpty) {
                                  if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$')
                                      .hasMatch(val.trim().toUpperCase())) {
                                    return 'Format: 5 letters + 4 digits + 1 letter';
                                  }
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            if (isTherapist) ...[
                              // Hospital with Address (Mandatory for Therapist only)
                              TextFormField(
                                controller: _addressController,
                                style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                                decoration: AppTheme.inputDecoration(
                                  labelText: "Hospital with Address",
                                  hintText: "e.g. Apollo Hospital, Greams Road, Chennai",
                                  prefixIcon: Icon(Icons.local_hospital_outlined, color: accentColor, size: 20),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Hospital with address is mandatory';
                                  }
                                  if (val.trim().length < 5) {
                                    return 'Please enter complete hospital name & address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Occupation / Clinical Practice
                            TextFormField(
                              controller: _workController,
                              style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                              decoration: AppTheme.inputDecoration(
                                labelText: isTherapist
                                    ? "Clinical Specialization / Hospital"
                                    : "Occupation / Work",
                                hintText: isTherapist
                                    ? "e.g. Speech Therapist, Rainbow Children's Hospital"
                                    : "e.g. Engineer, Educator, Homemaker",
                                prefixIcon: Icon(Icons.work_outline_rounded, color: accentColor, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section Title: Account & Security
                      const Text(
                        "Account & Security",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Account Details Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: AppTheme.border),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          children: [
                            // Email Readonly Tile
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.surfaceSubtle,
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: const Icon(Icons.email_outlined, color: AppTheme.textSecondary, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Registered Email",
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _currentUser?.email ?? 'N/A',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (_currentUser?.emailVerified ?? false)
                                        ? AppTheme.successLight
                                        : AppTheme.accentAmberLight,
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        (_currentUser?.emailVerified ?? false)
                                            ? Icons.check_circle_outline_rounded
                                            : Icons.access_time_rounded,
                                        size: 13,
                                        color: (_currentUser?.emailVerified ?? false)
                                            ? AppTheme.success
                                            : AppTheme.accentAmber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        (_currentUser?.emailVerified ?? false) ? "Verified" : "Pending",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: (_currentUser?.emailVerified ?? false)
                                              ? AppTheme.success
                                              : AppTheme.accentAmber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const Divider(height: 28, color: AppTheme.border),

                            // Send Password Reset Action
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Password & Login",
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Reset your password via verified email",
                                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                                OutlinedButton(
                                  onPressed: _isResettingPassword ? null : _sendPasswordReset,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    side: const BorderSide(color: AppTheme.border),
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                  ),
                                  child: _isResettingPassword
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                                        )
                                      : const Text(
                                          "Send Reset Link",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Action Button: Save Changes
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            elevation: 0,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save_outlined, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Save Profile Changes",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
