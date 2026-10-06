import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/child_service.dart';
import 'therapist_children_page.dart';
import 'therapist_hierarchical_question_page.dart';
import 'therapist_question_responses_page.dart';
import 'therapist_reports_page.dart';
import 'therapist_progress_page.dart';
import 'main.dart';
import 'therapist_assessment_page.dart';
import 'add_child_page.dart';
import 'therapist_feedback_page.dart';

class TherapistDashboard extends StatefulWidget {
  const TherapistDashboard({super.key});

  @override
  State<TherapistDashboard> createState() => _TherapistDashboardState();
}

class _TherapistDashboardState extends State<TherapistDashboard> {
  final AuthService _authService = AuthService();
  final ChildService _childService = ChildService();
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _authService.currentUser;
      if (user != null) {
        Map<String, dynamic>? data = await _authService.getUserData(user.uid);
        List<Map<String, dynamic>> children = await _childService.getChildren();
        setState(() {
          _userData = data;
          _children = children;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Therapist Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003366),
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/E1045Y1G.jpg',
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Welcome Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Welcome, Therapist!",
                              style: TextStyle(
                                color: Color(0xFF003366),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_userData != null) ...[
                              Text(
                                "Name: ${_userData!['username'] ?? 'N/A'}",
                                style: const TextStyle(
                                  color: Color(0xFF003366),
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "Email: ${_userData!['email'] ?? 'N/A'}",
                                style: const TextStyle(
                                  color: Color(0xFF003366),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Assigned Children: ${_children.length}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Action Buttons Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 1.2,
                        children: [
                          _DashboardCard(
                            title: "View My Children",
                            icon: Icons.people,
                            onTap: () {
                              if (_children.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No children assigned to you yet.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TherapistChildrenPage(children: _children),
                                ),
                              ).then((_) => _loadUserData()); // Refresh after returning
                            },
                          ),
                          _DashboardCard(
                            title: "Add Child",
                            icon: Icons.person_add,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddChildPage(),
                                ),
                              ).then((_) => _loadUserData()); // Refresh after returning
                            },
                          ),
                          _DashboardCard(
                            title: "Feedback",
                            icon: Icons.feedback,
                            onTap: () {
                              if (_children.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No children assigned to you yet.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TherapistFeedbackPage(),
                                ),
                              );
                            },
                          ),
                          _DashboardCard(
                            title: "Child Assessment",
                            icon: Icons.assignment,
                            onTap: () {
                              if (_children.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No children assigned to you yet.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TherapistAssessmentPage(
                                    child: _children.first,
                                    children: _children,
                                  ),
                                ),
                              );
                            },
                          ),
                          _DashboardCard(
                            title: "Ask Questions",
                            icon: Icons.question_answer,
                            onTap: () {
                              if (_children.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No children assigned to you yet.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TherapistHierarchicalQuestionPage(
                                    child: _children.first,
                                    children: _children,
                                  ),
                                ),
                              );
                            },
                          ),
                          _DashboardCard(
                            title: "View Responses",
                            icon: Icons.question_answer,
                            onTap: () {
                              if (_children.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No children assigned to you yet.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TherapistQuestionResponsesPage(),
                                ),
                              );
                            },
                          ),
                          _DashboardCard(
                            title: "Child Progress",
                            icon: Icons.trending_up,
                            onTap: () {
                              if (_children.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No children assigned to you yet.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TherapistProgressPage(),
                                ),
                              );
                            },
                          ),
                          _DashboardCard(
                            title: "View Reports",
                            icon: Icons.assessment,
                            onTap: () {
                              if (_children.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No children assigned to you yet.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TherapistReportsPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    // Proceed with logout only if user confirmed
    if (confirmLogout == true) {
      try {
        await _authService.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: const Color(0xFF003366),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF003366),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
