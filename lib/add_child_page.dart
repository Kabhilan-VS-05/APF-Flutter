import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/child_service.dart';

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
      String parentWork = selectedParent['work'] ?? 'Not provided';
      
      String additionalInfo = "Parent Name: $parentName, Contact: $parentContact, Parent Work: $parentWork, Therapist: ${currentUser.uid}";

      // Add child using child service
      await _addChildForTherapist(
        name: _nameController.text.trim(),
        age: _ageController.text.trim(),
        gender: _selectedGender!,
        diagnosis: _diagnosisController.text.trim(),
        additionalInfo: additionalInfo,
        parentId: _selectedParentId!,
        therapistId: currentUser.uid,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Child added successfully!'),
          backgroundColor: Colors.green,
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
    try {
      // Check if parent has already registered 3 children
      QuerySnapshot existingChildren = await FirebaseFirestore.instance
          .collection('children')
          .where('parentId', isEqualTo: parentId)
          .where('isActive', isEqualTo: true)
          .get();

      if (existingChildren.docs.length >= 3) {
        throw 'Maximum limit reached: This parent already has 3 children';
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
    } catch (e) {
      throw e.toString();
    }
  }

  Widget _buildSelectedParentDetails() {
    if (_selectedParentId == null) return const SizedBox.shrink();
    
    Map<String, dynamic>? selectedParent = _parents.firstWhere(
      (parent) => parent['id'] == _selectedParentId,
      orElse: () => {},
    );
    
    if (selectedParent.isEmpty) return const SizedBox.shrink();
    
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected Parent Details:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Name', selectedParent['username']),
            _buildDetailRow('Email', selectedParent['email']),
            _buildDetailRow('Phone', selectedParent['phone']),
            if (selectedParent['work'] != null && selectedParent['work'].toString().isNotEmpty)
              _buildDetailRow('Work', selectedParent['work']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF003366),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                color: Colors.grey[700],
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
      appBar: AppBar(
        title: const Text('Add New Child'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Child Information Section
              _buildSectionHeader('Child Information'),
              const SizedBox(height: 16),
              
              _buildTextField('Child Name', _nameController, validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter child name';
                }
                return null;
              }),
              
              const SizedBox(height: 16),
              
              _buildTextField('Age', _ageController, validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter child age';
                }
                if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return 'Please enter a valid age';
                }
                return null;
              }),
              
              const SizedBox(height: 16),
              
              _buildGenderDropdown(),
              
              const SizedBox(height: 16),
              
              _buildTextField('Diagnosis/Problem Details', _diagnosisController, validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter diagnosis or problem details';
                }
                return null;
              }),
              
              const SizedBox(height: 32),
              
              // Parent Selection Section
              _buildSectionHeader('Parent Assignment'),
              const SizedBox(height: 16),
              
              _isLoadingParents
                  ? const Center(child: CircularProgressIndicator())
                  : _parents.isEmpty
                      ? const Center(
                          child: Text(
                            'No parent accounts available. Parents need to create accounts first.',
                            style: TextStyle(color: Colors.orange),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Column(
                          children: [
                            _buildParentDropdown(),
                            if (_selectedParentId != null) ...[
                              const SizedBox(height: 16),
                              _buildSelectedParentDetails(),
                            ],
                          ],
                        ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addChild,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Child'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF003366),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: const InputDecoration(
        labelText: 'Select Gender',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
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
        labelText: 'Select Parent',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(Icons.person, color: Color(0xFF003366)),
      ),
      items: _parents.map((parent) {
        String displayName = '${parent['username'] ?? 'Unknown'} (${parent['email'] ?? 'No email'})';
        return DropdownMenuItem<String>(
          value: parent['id'],
          child: Container(
            constraints: const BoxConstraints(maxHeight: 100),
            child: Text(
              displayName,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
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
