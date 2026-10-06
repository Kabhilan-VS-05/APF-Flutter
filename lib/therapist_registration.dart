// FILE: therapist_registration.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'therapist_home_page.dart';

class TherapistRegistrationPage extends StatefulWidget {
  const TherapistRegistrationPage({super.key});

  @override
  State<TherapistRegistrationPage> createState() =>
      _TherapistRegistrationPageState();
}

class _TherapistRegistrationPageState extends State<TherapistRegistrationPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/E1045Y1G.jpg', fit: BoxFit.cover),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Therapist Registration",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  _buildForm(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildTextField("Full Name", _nameController),
          const SizedBox(height: 15),

          _buildTextField("Email", _emailController),
          const SizedBox(height: 15),

          _buildTextField("Phone Number", _phoneController),
          const SizedBox(height: 15),

          _buildTextField("Password", _passwordController, isPassword: true),
          const SizedBox(height: 25),

          _buildButton("Register Therapist"),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        labelStyle: const TextStyle(color: Color(0xFF003366)),
      ),
    );
  }

  Widget _buildButton(String label) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003366),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          // Directly go to home WITHOUT validation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Therapist Registered Successfully")),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const TherapistHomePage()),
          );
        },
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}