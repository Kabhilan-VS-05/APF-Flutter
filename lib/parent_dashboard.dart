import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/child_service.dart';
import 'parent_children_page.dart';
import 'parent_hierarchical_question_response_page.dart';
import 'parent_progress_page.dart';
import 'parent_feedback_page.dart';
import 'parent_reports_page.dart';
import 'main.dart';
import 'edit_profile_page.dart';
import 'theme/app_theme.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
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
            content: Text('Error loading profile: $e'),
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
          content: const Text('Are you sure you want to sign out of your account?'),
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
    final userName = _userData?['username'] ?? 'Parent';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'P';

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
                backgroundColor: AppTheme.primaryLight,
                child: Text(
                  userInitial,
                  style: const TextStyle(
                    color: AppTheme.primary,
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
                      "Hello, $userName 👋",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Text(
                      "Parent Portal",
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
            icon: const Icon(Icons.manage_accounts_outlined, color: AppTheme.primary),
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
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            tooltip: "Refresh data",
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
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Welcome Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.zero,
                        boxShadow: AppTheme.softShadow,
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
                                    Icon(Icons.shield_outlined, size: 14, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      "Active Care Plan",
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _userData?['email'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Child Milestone Hub",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Track therapy progress, answer developmental checklists, and view certified clinical recommendations.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.child_care_rounded, size: 16, color: AppTheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  "${_children.length} Registered ${_children.length == 1 ? 'Child' : 'Children'}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section: Quick Portals
                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Modern 2-column Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.15,
                      children: [
                        _ModernDashboardCard(
                          title: "My Children",
                          subtitle: "${_children.length} profiles registered",
                          icon: Icons.child_care_rounded,
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
                                builder: (context) => ParentChildrenPage(children: _children),
                              ),
                            ).then((_) => _loadUserData());
                          },
                        ),
                        _ModernDashboardCard(
                          title: "Assessments",
                          subtitle: "Category questions",
                          icon: Icons.quiz_outlined,
                          accentColor: AppTheme.accentPurple,
                          lightColor: AppTheme.accentPurpleLight,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ParentHierarchicalQuestionResponsePage(),
                              ),
                            );
                          },
                        ),
                        _ModernDashboardCard(
                          title: "Child Progress",
                          subtitle: "Milestone charts",
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
                                builder: (context) => const ParentProgressPage(),
                              ),
                            );
                          },
                        ),
                        _ModernDashboardCard(
                          title: "Therapist Notes",
                          subtitle: "Clinical remarks & plans",
                          icon: Icons.mark_chat_unread_outlined,
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
                                builder: (context) => const ParentFeedbackPage(),
                              ),
                            );
                          },
                        ),
                        _ModernDashboardCard(
                          title: "Reports & PDF",
                          subtitle: "Download summaries",
                          icon: Icons.description_outlined,
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
                                builder: (context) => const ParentReportsPage(),
                              ),
                            );
                          },
                        ),
                        _ModernDashboardCard(
                          title: "Edit Profile",
                          subtitle: "Account & credentials",
                          icon: Icons.manage_accounts_outlined,
                          accentColor: AppTheme.primary,
                          lightColor: AppTheme.primaryLight,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage(),
                              ),
                            ).then((res) {
                              if (res == true) _loadUserData();
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Registered Children Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Registered Children",
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
                                  builder: (context) => ParentChildrenPage(children: _children),
                                ),
                              ).then((_) => _loadUserData());
                            },
                            child: const Text("View All", style: TextStyle(fontWeight: FontWeight.bold)),
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
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: const Icon(Icons.child_care_rounded, size: 36, color: AppTheme.primary),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              "No Children Registered Yet",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Your child profiles will appear here once registered by your clinic or therapist.",
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
                                      : AppTheme.primaryLight,
                                  child: Icon(
                                    Icons.face_rounded,
                                    color: childGender == 'Female' ? AppTheme.accentRose : AppTheme.primary,
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
                                            color: AppTheme.primary,
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
        content: const Text('No children registered yet in your account.'),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}

class _ModernDashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color lightColor;
  final VoidCallback onTap;

  const _ModernDashboardCard({
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
