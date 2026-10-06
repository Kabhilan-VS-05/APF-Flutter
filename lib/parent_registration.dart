import 'package:flutter/material.dart';
import 'dart:ui' as ui; // ← needed for ImageFilter
import 'parents_home_page.dart'; // Navigate after registration

class ParentRegistrationPage extends StatefulWidget {
  const ParentRegistrationPage({super.key});

  @override
  State<ParentRegistrationPage> createState() =>
      _ParentRegistrationPageState();
}

class _ParentRegistrationPageState extends State<ParentRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
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
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
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
                    "Parent Registration",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
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
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField("Full Name", _nameController),
            const SizedBox(height: 15),
            _buildEmailField(),
            const SizedBox(height: 15),
            _buildPhoneField(),
            const SizedBox(height: 15),
            _buildPasswordField(),
            const SizedBox(height: 25),
            _buildButton(context, "Register Parent"),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        labelStyle: const TextStyle(color: Color(0xFF003366)),
      ),
      validator: (value) => value!.isEmpty ? 'Enter $label' : null,
    );
  }

  Widget _buildEmailField() => TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(
          labelText: "Email",
          border: OutlineInputBorder(),
          labelStyle: TextStyle(color: Color(0xFF003366)),
        ),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value!.isEmpty) return 'Enter email';
          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Invalid email';
          }
          return null;
        },
      );

  Widget _buildPhoneField() => TextFormField(
        controller: _phoneController,
        decoration: const InputDecoration(
          labelText: "Phone Number",
          border: OutlineInputBorder(),
          labelStyle: TextStyle(color: Color(0xFF003366)),
        ),
        keyboardType: TextInputType.phone,
        validator: (value) =>
            value!.length != 10 ? 'Phone must be 10 digits' : null,
      );

  Widget _buildPasswordField() => TextFormField(
        controller: _passwordController,
        decoration: const InputDecoration(
          labelText: "Password",
          border: OutlineInputBorder(),
          labelStyle: TextStyle(color: Color(0xFF003366)),
        ),
        obscureText: true,
        validator: (value) =>
            value!.length < 6 ? 'Password must be at least 6 chars' : null,
      );

  Widget _buildButton(BuildContext context, String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF003366),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const FeedbackQuestionPage(),
            ),
          );
        }
      },
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}