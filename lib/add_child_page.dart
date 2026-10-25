import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/child_service.dart';
import 'theme/app_theme.dart';

class AddChildPage extends StatefulWidget {
  const AddChildPage({super.key});

  @override
  State<AddChildPage> createState() => _AddChildPageState();
}

class _AddChildPageState extends State<AddChildPage> {
  final _formKey = GlobalKey<FormState>();
  final ChildService _childService = ChildService();
  final AuthService _authService = AuthService();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _diagnosisController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedParentId;
  List<Map<String, dynamic>> _parents = [];
  bool _isLoading = false;
  bool _isLoadingParents = true;

  @override
  void initState() {
    super.initState();
    _loadParents();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _diagnosisController.dispose();
    super.dispose();
  }

  Future<void> _loadParents() async {
    try {
      setState(() => _isLoadingParents = true);
      
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Parent')
          .where('isActive', isEqualTo: true)
          .get();
      
      setState(() {
        _parents = snapshot.docs.map((doc) {
          Map<String, dynamic> parent = doc.data() as Map<String, dynamic>;
          parent['id'] = doc.id;
          return parent;
        }).toList();
        _isLoadingParents = false;
      });
    } catch (e) {
      setState(() => _isLoadingParents = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading parents: $e')),
      );
    }
  }

  Future<void> _addChild() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedParentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a parent')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Get selected parent details
      Map<String, dynamic>? selectedParent = _parents.firstWhere(
        (parent) => parent['id'] == _selectedParentId,
        orElse: () => {},
      );

      if (selectedParent.isEmpty) {
        throw 'Selected parent not found';
      }

      // Create additional info with parent details (handle missing fields)
      String parentName = selectedParent['username'] ?? 'Unknown';
      String parentContact = selectedParent['phone'] ?? 'Not provided';
      String additionalInfo = 'Parent: $parentName, Contact: $parentContact';
      
      // Add child directly for therapist
      await _addChildForTherapist(
        name: _nameController.text.trim(),
        age: _ageController.text.trim(),
        gender: _selectedGender!,
        diagnosis: _diagnosisController.text.trim(),
        additionalInfo: additionalInfo,
        parentId: _selectedParentId!,
        therapistId: currentUser.uid,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Child registered and linked successfully!'),
          backgroundColor: AppTheme.secondary,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding child: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Method to add child for therapist (bypassing parent-only restriction)
  Future<void> _addChildForTherapist({
    required String name,
    required String age,
    required String gender,
    required String diagnosis,
    required String additionalInfo,
    required String parentId,
    required String therapistId,
  }) async {
    // Check if parent has already registered 3 children
    QuerySnapshot existingChildren = await FirebaseFirestore.instance
        .collection('children')
        .where('parentId', isEqualTo: parentId)
        .where('isActive', isEqualTo: true)
        .get();

    if (existingChildren.docs.length >= 3) {
      throw 'Maximum limit reached: This parent already has 3 children registered';
    }

    // Create the child document
    await FirebaseFirestore.instance.collection('children').add({
      'name': name,
      'age': age,
      'gender': gender,
      'diagnosis': diagnosis,
      'additionalInfo': additionalInfo,
      'parentId': parentId,
      'therapistId': therapistId,
      'createdAt': Timestamp.now(),
      'isActive': true,
    });
  }

  Widget _buildSelectedParentDetails() {
    if (_selectedParentId == null) return const SizedBox.shrink();
    
    Map<String, dynamic>? selectedParent = _parents.firstWhere(
      (parent) => parent['id'] == _selectedParentId,
      orElse: () => {},
    );
    
    if (selectedParent.isEmpty) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 16, color: AppTheme.secondary),
              SizedBox(width: 8),
              Text(
                'Selected Parent Information',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Name', selectedParent['username']),
          _buildDetailRow('Email', selectedParent['email']),
          _buildDetailRow('Phone', selectedParent['phone']),
          if (selectedParent['work'] != null && selectedParent['work'].toString().isNotEmpty)
            _buildDetailRow('Work', selectedParent['work']),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Register Child Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Child Information Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Child Clinical Information', Icons.child_care_rounded),
                    const SizedBox(height: 18),
                    
                    _buildTextField('Child Full Name', _nameController, hint: 'e.g., Alex Johnson', validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter child name';
                      }
                      return null;
                    }),
                    
                    const SizedBox(height: 14),
                    
                    _buildTextField('Age (in years)', _ageController, hint: 'e.g., 5', keyboardType: TextInputType.number, validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter child age';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return 'Please enter a valid age number';
                      }
                      return null;
                    }),
                    
                    const SizedBox(height: 14),
                    
                    _buildGenderDropdown(),
                    
                    const SizedBox(height: 14),
                    
                    _buildTextField('Diagnosis / Clinical Focus', _diagnosisController, hint: 'e.g., ASD Level 1, Speech Delay', maxLines: 2, validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter diagnosis or focus areas';
                      }
                      return null;
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Parent Selection Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Parent Account Assignment', Icons.supervisor_account_rounded),
                    const SizedBox(height: 18),
                    
                    _isLoadingParents
                        ? const Center(child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(color: AppTheme.secondary),
                          ))
                        : _parents.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentAmberLight,
                                  border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline, color: AppTheme.accentAmber),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'No parent accounts found. Parents must register an account before child linkage.',
                                        style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  _buildParentDropdown(),
                                  if (_selectedParentId != null) ...[
                                    const SizedBox(height: 14),
                                    _buildSelectedParentDetails(),
                                  ],
                                ],
                              ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addChild,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Register Patient Profile',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.secondaryLight,
            border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: 18, color: AppTheme.secondary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
        labelStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.secondary, width: 1.5),
        ),
        filled: true,
        fillColor: AppTheme.surfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: validator,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: const InputDecoration(
        labelText: 'Select Gender',
        labelStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.zero),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.secondary, width: 1.5),
        ),
        filled: true,
        fillColor: AppTheme.surfaceSubtle,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Female', child: Text('Female')),
        DropdownMenuItem(value: 'Other', child: Text('Other')),
      ],
      validator: (value) {
        if (value == null) {
          return 'Please select gender';
        }
        return null;
      },
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
        });
      },
    );
  }

  Widget _buildParentDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedParentId,
      decoration: const InputDecoration(
        labelText: 'Select Linked Parent Account',
        labelStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.zero),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.secondary, width: 1.5),
        ),
        filled: true,
        fillColor: AppTheme.surfaceSubtle,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: _parents.map((parent) {
        String displayName = '${parent['username'] ?? 'Unknown'} • ${parent['email'] ?? 'No email'}';
        return DropdownMenuItem<String>(
          value: parent['id'],
          child: Text(
            displayName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      validator: (value) {
        if (value == null) {
          return 'Please select a parent';
        }
        return null;
      },
      onChanged: (value) {
        setState(() {
          _selectedParentId = value;
        });
      },
    );
  }
}
