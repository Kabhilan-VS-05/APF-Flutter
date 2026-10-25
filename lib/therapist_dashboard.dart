import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/child_service.dart';
import 'therapist_children_page.dart';
import 'therapist_hierarchical_question_page.dart';
import 'therapist_question_responses_page.dart';
import 'therapist_reports_page.dart';
import 'therapist_progress_page.dart';
import 'therapist_assessment_page.dart';
import 'add_child_page.dart';
import 'therapist_feedback_page.dart';
import 'main.dart';
import 'edit_profile_page.dart';
import 'theme/app_theme.dart';

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
      final user = _authService.currentUser;
      if (user != null) {
        final data = await _authService.getUserData(user.uid);
        final children = await _childService.getChildren();
        if (mounted) {
          setState(() {
            _userData = data;
            _children = children;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading clinical workspace: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text('Confirm Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to sign out of the clinical portal?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout failed: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicianName = _userData?['username'] ?? 'Therapist';
    final userInitial = clinicianName.isNotEmpty ? clinicianName[0].toUpperCase() : 'T';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        automaticallyImplyLeading: false,
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfilePage()),
            ).then((res) {
              if (res == true) _loadUserData();
            });
          },
          borderRadius: BorderRadius.zero,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.secondaryLight,
                child: Text(
                  userInitial,
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      clinicianName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Text(
                      "Clinician Portal",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined, color: AppTheme.secondary),
            tooltip: "Edit Profile",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfilePage()),
              ).then((res) {
                if (res == true) _loadUserData();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.secondary),
            tooltip: "Add Child",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddChildPage()),
              ).then((_) => _loadUserData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            tooltip: "Refresh roster",
            onPressed: () {
              setState(() => _isLoading = true);
              _loadUserData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
            tooltip: "Sign out",
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.secondary))
          : RefreshIndicator(
              color: AppTheme.secondary,
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clinical Hero Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.zero,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      "Clinical Portal",
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _userData?['email'] ?? '',
                                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Therapist Diagnostic Hub",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Conduct motor, speech & behavioral evaluations, score parent responses, and publish diagnostic PDF reports.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.people_alt_rounded, size: 16, color: AppTheme.secondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${_children.length} Active Patients",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AddChildPage()),
                                  ).then((_) => _loadUserData());
                                },
                                borderRadius: BorderRadius.zero,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.zero,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add, size: 16, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        "Register Child",
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section Title
                    const Text(
                      "Clinical Operations",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Clinical Operations Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.15,
                      children: [
                        _TherapistActionCard(
                          title: "Patient Roster",
                          subtitle: "${_children.length} assigned profiles",
                          icon: Icons.people_outline_rounded,
                          accentColor: AppTheme.secondary,
                          lightColor: AppTheme.secondaryLight,
                          onTap: () {
                            if (_children.isEmpty) {
                              _showNoChildrenAlert(context);
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TherapistChildrenPage(children: _children),
                              ),
                            ).then((_) => _loadUserData());
                          },
                        ),
                        _TherapistActionCard(
                          title: "Register Child",
                          subtitle: "Assign to parents",
                          icon: Icons.person_add_outlined,
                          accentColor: AppTheme.primary,
                          lightColor: AppTheme.primaryLight,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddChildPage()),
                            ).then((_) => _loadUserData());
                          },
                        ),
                        _TherapistActionCard(
                          title: "Domain Assessment",
                          subtitle: "Standardized scoring",
                          icon: Icons.assignment_outlined,
                          accentColor: AppTheme.accentPurple,
                          lightColor: AppTheme.accentPurpleLight,
                          onTap: () {
                            if (_children.isEmpty) {
                              _showNoChildrenAlert(context);
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
                        _TherapistActionCard(
                          title: "Questionnaires",
                          subtitle: "Hierarchical categories",
                          icon: Icons.quiz_outlined,
                          accentColor: AppTheme.accentAmber,
                          lightColor: AppTheme.accentAmberLight,
                          onTap: () {
                            if (_children.isEmpty) {
                              _showNoChildrenAlert(context);
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
                        _TherapistActionCard(
                          title: "Review Responses",
                          subtitle: "Parent submissions",
                          icon: Icons.rate_review_outlined,
                          accentColor: AppTheme.primary,
                          lightColor: AppTheme.primaryLight,
                          onTap: () {
                            if (_children.isEmpty) {
                              _showNoChildrenAlert(context);
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
                        _TherapistActionCard(
                          title: "Child Progress",
                          subtitle: "Development trends",
                          icon: Icons.trending_up_rounded,
                          accentColor: AppTheme.secondary,
                          lightColor: AppTheme.secondaryLight,
                          onTap: () {
                            if (_children.isEmpty) {
                              _showNoChildrenAlert(context);
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
                        _TherapistActionCard(
                          title: "Session Feedback",
                          subtitle: "Clinical remarks & plans",
                          icon: Icons.comment_outlined,
                          accentColor: AppTheme.accentAmber,
                          lightColor: AppTheme.accentAmberLight,
                          onTap: () {
                            if (_children.isEmpty) {
                              _showNoChildrenAlert(context);
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
                        _TherapistActionCard(
                          title: "Publish Reports",
                          subtitle: "Downloadable PDF summaries",
                          icon: Icons.picture_as_pdf_outlined,
                          accentColor: AppTheme.accentRose,
                          lightColor: AppTheme.accentRoseLight,
                          onTap: () {
                            if (_children.isEmpty) {
                              _showNoChildrenAlert(context);
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

                    const SizedBox(height: 28),

                    // Patient Roster Quick List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Patient Roster",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (_children.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TherapistChildrenPage(children: _children),
                                ),
                              ).then((_) => _loadUserData());
                            },
                            child: const Text("View All", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (_children.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppTheme.secondaryLight,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: const Icon(Icons.people_outline_rounded, size: 36, color: AppTheme.secondary),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              "No Patients Assigned",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Tap 'Register Child' above to enroll a child for one of your registered parents.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _children.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final child = _children[index];
                          final childName = child['name'] ?? 'Child';
                          final childAge = child['age'] ?? 'N/A';
                          final childGender = child['gender'] ?? 'N/A';
                          final childDiagnosis = child['diagnosis'] ?? 'Under Observation';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.zero,
                              border: Border.all(color: AppTheme.border),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: childGender == 'Female'
                                      ? AppTheme.accentRoseLight
                                      : AppTheme.secondaryLight,
                                  child: Icon(
                                    Icons.face_rounded,
                                    color: childGender == 'Female' ? AppTheme.accentRose : AppTheme.secondary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        childName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        "Age: $childAge yrs • Gender: $childGender",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.surfaceSubtle,
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        child: Text(
                                          "Diagnosis: $childDiagnosis",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.secondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textMuted),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  void _showNoChildrenAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('No children registered yet. Tap "Register Child" to add a patient.'),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}

class _TherapistActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color lightColor;
  final VoidCallback onTap;

  const _TherapistActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.lightColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.zero,
            border: Border(
              top: BorderSide(color: accentColor, width: 3),
              left: const BorderSide(color: AppTheme.border),
              right: const BorderSide(color: AppTheme.border),
              bottom: const BorderSide(color: AppTheme.border),
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: lightColor,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1.2),
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: AppTheme.textMuted.withValues(alpha: 0.8),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
