//for searching the child using unique ID
import 'dart:ui';
import 'package:flutter/material.dart';

class ViewEditInformationPage extends StatefulWidget {
  const ViewEditInformationPage({super.key});

  @override
  State<ViewEditInformationPage> createState() =>
      _ViewEditInformationPageState();
}

class _ViewEditInformationPageState extends State<ViewEditInformationPage> {
  final TextEditingController uniqueIdController = TextEditingController();

  // Controllers for child details
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController diagnosisController = TextEditingController();
  final TextEditingController parentController = TextEditingController();

  bool dataLoaded = false; // after clicking view information
  bool isEditing = false; // after clicking edit

  // Temporary dummy data fetch
  void loadDummyData() {
    // You can replace this with Firestore later.
    nameController.text = "John Doe";
    ageController.text = "6";
    diagnosisController.text = "Autism Spectrum Disorder";
    parentController.text = "Mr. David";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            'assets/E1045Y1G.jpg',
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withOpacity(0.25)),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Arrow
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),

                const SizedBox(height: 10),

                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "2. View/Edit Information",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ===== INPUT BOX =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: uniqueIdController,
                          decoration: InputDecoration(
                            labelText: "Enter Child Unique ID",
                            prefixIcon: const Icon(Icons.badge),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // View Information Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (uniqueIdController.text.isNotEmpty) {
                                loadDummyData();
                                setState(() {
                                  dataLoaded = true;
                                  isEditing = false;
                                });
                              }
                            },
                            icon: const Icon(Icons.search),
                            label: const Text("View Information",
                                style: TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 32, 65, 166),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ===== SHOW CHILD INFORMATION =====
                if (dataLoaded)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // NAME
                              _infoField(
                                label: "Child Name",
                                controller: nameController,
                                editable: isEditing,
                              ),

                              const SizedBox(height: 15),

                              // AGE
                              _infoField(
                                label: "Age",
                                controller: ageController,
                                editable: isEditing,
                              ),

                              const SizedBox(height: 15),

                              // DIAGNOSIS
                              _infoField(
                                label: "Diagnosis",
                                controller: diagnosisController,
                                editable: isEditing,
                              ),

                              const SizedBox(height: 15),

                              // PARENT NAME
                              _infoField(
                                label: "Parent Name",
                                controller: parentController,
                                editable: isEditing,
                              ),

                              const SizedBox(height: 25),

                              // ===== EDIT & SAVE BUTTONS =====
                              if (!isEditing)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        isEditing = true;
                                      });
                                    },
                                    icon: const Icon(Icons.edit),
                                    label: const Text("Edit Information"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade700,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        isEditing = false;
                                      });

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "Information Updated Successfully"),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.save),
                                    label: const Text("Save Information"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Reusable text field viewer / editor
  Widget _infoField({
    required String label,
    required TextEditingController controller,
    required bool editable,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          enabled: editable,
          decoration: InputDecoration(
            filled: true,
            fillColor: editable ? Colors.white : Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}