//for child registeration details
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';
import 'services/auth_service.dart';

// =============================================================
// ✔ DATA MODEL — stores all child information
// =============================================================
class BasicChildInfo {
  String name;
  String age;
  String diagnosis;
  String gender;
  String address;
  String parentName;
  String parentProfession;
  String contactDetails;
  String therapistName;

  BasicChildInfo({
    required this.name,
    required this.age,
    required this.diagnosis,
    required this.gender,
    required this.address,
    required this.parentName,
    required this.parentProfession,
    required this.contactDetails,
    required this.therapistName,
  });
}

// =============================================================
// ✔ GLOBAL STORAGE
// =============================================================
Map<String, BasicChildInfo> globalChildrenData = {};

// =============================================================
// ✔ REGISTER PAGE
// =============================================================
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final parentNameController = TextEditingController();
  final contactController = TextEditingController();
  final parentWorkController = TextEditingController();
  final genderController = TextEditingController();
  final problemController = TextEditingController();
  String? selectedTherapist;
  final ChildService _childService = ChildService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _therapists = [];

  @override
  void initState() {
    super.initState();
    _loadTherapists();
  }

  Future<void> _loadTherapists() async {
    try {
      print('Starting to load therapists...');
      
      // First, let's try to get all users to see what we have
      QuerySnapshot allUsersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      print('Total users in collection: ${allUsersSnapshot.docs.length}');
      
      // Log all users to debug
      for (var doc in allUsersSnapshot.docs) {
        Map<String, dynamic> user = doc.data() as Map<String, dynamic>;
        print('User: ${user['username'] ?? user['email'] ?? 'No name'}, Role: ${user['role']}, ID: ${doc.id}');
      }
      
      // Now get therapists specifically
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Therapist')
          .get();
      
      print('Found ${snapshot.docs.length} therapists with role "Therapist"');
      
      setState(() {
        _therapists = snapshot.docs.map((doc) {
          Map<String, dynamic> therapist = doc.data() as Map<String, dynamic>;
          therapist['id'] = doc.id;
          print('Therapist mapped: ${therapist['username'] ?? therapist['email'] ?? therapist['name'] ?? 'No name'}');
          print('Role: ${therapist['role']}');
          print('Email: ${therapist['email']}');
          return therapist;
        }).toList();
      });
      print('Total therapists loaded: ${_therapists.length}');
      
      // If no therapists found with 'Therapist', try 'therapist'
      if (_therapists.isEmpty) {
        print('Trying lowercase "therapist"...');
        QuerySnapshot snapshot2 = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'therapist')
            .get();
        
        print('Found ${snapshot2.docs.length} therapists with role "therapist"');
        
        setState(() {
          _therapists = snapshot2.docs.map((doc) {
            Map<String, dynamic> therapist = doc.data() as Map<String, dynamic>;
            therapist['id'] = doc.id;
            print('Therapist found (lowercase): ${therapist['username'] ?? therapist['email'] ?? therapist['name'] ?? 'No name'}');
            print('Role: ${therapist['role']}');
            return therapist;
          }).toList();
        });
        print('Total therapists loaded (lowercase): ${_therapists.length}');
      }
    } catch (e) {
      print('Error loading therapists: $e');
      print('Error details: ${e.toString()}');
      setState(() {
        _therapists = [];
      });
    }
  }

  Future<void> registerChild() async {
    if (nameController.text.isEmpty || 
        parentNameController.text.isEmpty || 
        contactController.text.isEmpty ||
        selectedTherapist == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name, Parent Name, Contact, and Therapist are required!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _childService.registerChild(
        name: nameController.text.trim(),
        age: ageController.text.trim(),
        gender: genderController.text.trim(),
        diagnosis: problemController.text.trim(),
        additionalInfo: "Parent Name: ${parentNameController.text.trim()}, Contact: ${contactController.text.trim()}, Parent Work: ${parentWorkController.text.trim()}, Therapist: $selectedTherapist",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Child Registered Successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image + Blur
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/E1045Y1G.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),

          // MAIN CONTENT
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 30),

              /// PAGE TITLE
              const Center(
                child: Text(
                  "REGISTER CHILD",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// WHITE BOX CONTAINER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    field("Child Name", nameController),
                    field("Age", ageController),
                    field("Parent Name", parentNameController),
                    field("Contact Number", contactController),
                    field("Parent Working On", parentWorkController),
                    _genderDropdown(),
                    field("Problem Details", problemController),
                    _therapistDropdown(),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _isLoading ? null : registerChild,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366), // Dark Blue
                        padding: const EdgeInsets.all(15),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Register",
                              style: TextStyle(color: Colors.white),
                            ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF003366)), // Dark Blue
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _genderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: genderController.text.isEmpty ? null : genderController.text,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: "Select Gender",
          labelStyle: const TextStyle(color: Color(0xFF003366)),
          border: const OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: "Male", child: Text("Male")),
          DropdownMenuItem(value: "Female", child: Text("Female")),
          DropdownMenuItem(value: "Other", child: Text("Other")),
        ],
        onChanged: (value) {
          setState(() {
            genderController.text = value ?? "";
          });
        },
      ),
    );
  }

  Widget _therapistDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selectedTherapist,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: "Select Therapist",
          labelStyle: const TextStyle(color: Color(0xFF003366)),
          border: const OutlineInputBorder(),
          helperText: _therapists.isEmpty ? "No therapists available" : null,
          helperStyle: const TextStyle(color: Colors.red),
        ),
        items: _therapists.map((therapist) {
          String displayName = therapist['username'] ?? 
                              therapist['email'] ?? 
                              therapist['name'] ?? 
                              'Unknown Therapist';
          return DropdownMenuItem<String>(
            value: displayName,
            child: Text(displayName),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedTherapist = value;
          });
        },
      ),
    );
  }
}

// =============================================================
// ✔ EDIT INFORMATION PAGE
// =============================================================
class EditInformationPage extends StatefulWidget {
  final BasicChildInfo child;

  const EditInformationPage({super.key, required this.child});

  @override
  State<EditInformationPage> createState() => _EditInformationPageState();
}

class _EditInformationPageState extends State<EditInformationPage> {
  late TextEditingController name;
  late TextEditingController age;
  late TextEditingController address;
  late TextEditingController parentName;
  late TextEditingController parentProfession;
  late TextEditingController contact;
  late TextEditingController therapist;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.child.name);
    age = TextEditingController(text: widget.child.age);
    address = TextEditingController(text: widget.child.address);
    parentName = TextEditingController(text: widget.child.parentName);
    parentProfession = TextEditingController(text: widget.child.parentProfession);
    contact = TextEditingController(text: widget.child.contactDetails);
    therapist = TextEditingController(text: widget.child.therapistName);
  }

  void saveChanges() {
    widget.child.name = name.text;
    widget.child.age = age.text;
    widget.child.address = address.text;
    widget.child.parentName = parentName.text;
    widget.child.parentProfession = parentProfession.text;
    widget.child.contactDetails = contact.text;
    widget.child.therapistName = therapist.text;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Information Updated")),
    );

    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Blurred Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/E1045Y1G.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 30),

              /// Title
              const Center(
                child: Text(
                  "EDIT INFORMATION",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    buildField("Name", name),
                    buildField("Age", age),
                    buildField("Address", address),
                    buildField("Parent Name", parentName),
                    buildField("Profession", parentProfession),
                    buildField("Contact", contact),
                    buildField("Therapist", therapist),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366), // Dark Blue
                        padding: const EdgeInsets.all(15),
                      ),
                      child: const Text("Save",
                          style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF003366)), // Dark Blue
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}