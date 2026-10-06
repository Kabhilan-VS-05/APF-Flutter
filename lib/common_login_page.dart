import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'parent_dashboard.dart';
import 'therapist_dashboard.dart';
import 'signup_page.dart';

class CommonLoginPage extends StatefulWidget {
  const CommonLoginPage({super.key});

  @override
  State<CommonLoginPage> createState() => _CommonLoginPageState();
}

class _CommonLoginPageState extends State<CommonLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that user provides either email OR username, not both
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    
    if (email.isEmpty && username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter either email or username'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (email.isNotEmpty && username.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please use either email OR username, not both'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      AuthService authService = AuthService();
      UserCredential? userCredential = await authService.signIn(
        emailOrUsername: username.isNotEmpty ? username : email,
        password: _passwordController.text,
      );

      if (userCredential != null) {
        // Get user role from Firestore automatically
        String? userRole = await authService.getUserRole(userCredential.user!.uid);
        
        if (userRole != null) {
          // Navigate based on the user's actual role from database
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
          }
        } else {
          // If role not found, show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User role not found. Please contact support.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF003366),
              Color(0xFF004080),
              Color(0xFF0052CC),
            ],
          ),
        ),
        child: Center(
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      const Text(
                        "Login",
                        style: TextStyle(
                          color: Color(0xFF003366),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SizedBox(height: 30),
                      
                      // Login Options Box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F8),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFF003366), width: 1),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Choose Login Method",
                              style: TextStyle(
                                color: Color(0xFF003366),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: "Email",
                                prefixIcon: Icon(Icons.email, color: Color(0xFF003366)),
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            
                            // OR Divider
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(
                                    color: Color(0xFF003366),
                                    thickness: 1,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    "OR",
                                    style: TextStyle(
                                      color: Color(0xFF003366),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(
                                    color: Color(0xFF003366),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            
                            // Username Field
                            TextFormField(
                              controller: _usernameController,
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                labelText: "Username",
                                prefixIcon: Icon(Icons.person, color: Color(0xFF003366)),
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (value.length < 3) {
                                    return 'Username must be at least 3 characters';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // Password Field (Outside Box)
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock, color: Color(0xFF003366)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: const Color(0xFF003366),
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      
                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resetPassword,
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(color: Color(0xFF003366)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Login Button
                      _isLoading
                          ? const CircularProgressIndicator(color: Color(0xFF003366))
                          : ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003366),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 15,
                                ),
                              ),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                      const SizedBox(height: 20),
                      
                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignupPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Color(0xFF003366),
                                fontWeight: FontWeight.bold,
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
          ),
        ),
      );
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    
    if (email.isEmpty && username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter either email or username'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (email.isNotEmpty && username.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please use either email OR username, not both'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      AuthService authService = AuthService();
      await authService.resetPassword(username.isNotEmpty ? username : email);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
