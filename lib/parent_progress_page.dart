import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'services/child_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

class ParentProgressPage extends StatefulWidget {
  const ParentProgressPage({super.key});

  @override
  State<ParentProgressPage> createState() => _ParentProgressPageState();
}

class _ParentProgressPageState extends State<ParentProgressPage> {
  final ChildService _childService = ChildService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _children = [];
  Map<String, dynamic>? _selectedChild;
  Map<String, dynamic>? _progressData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final children = await _childService.getChildren();
      setState(() {
        _children = children;
        if (children.isNotEmpty) {
          _selectedChild = children.first;
        }
        _isLoading = false;
      });
      
      if (_selectedChild != null) {
        _loadProgressData();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _loadProgressData() async {
    if (_selectedChild == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Load current progress for the selected child
      QuerySnapshot progressSnapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('childId', isEqualTo: _selectedChild!['id'])
          .where('type', isEqualTo: 'current_progress')
          .limit(1)
          .get();

      if (progressSnapshot.docs.isNotEmpty) {
        Map<String, dynamic> progress = progressSnapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          _progressData = progress;
          _isLoading = false;
        });
      } else {
        setState(() {
          _progressData = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading progress data: $e')),
      );
    }
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Excellent Progress':
        return AppTheme.secondary;
      case 'Good Progress':
        return AppTheme.primary;
      case 'Making Progress':
        return AppTheme.accentAmber;
      case 'Needs Support':
        return Colors.deepOrange;
      case 'Requires Focus':
        return AppTheme.accentRose;
      default:
        return AppTheme.textMuted;
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'unknown time';
    DateTime date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Child Progress',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                // Child Selection Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(bottom: BorderSide(color: AppTheme.border)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.child_care_rounded, color: AppTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedChild,
                            decoration: InputDecoration(
                              labelText: 'Active Child Profile',
                              labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              filled: true,
                              fillColor: AppTheme.surfaceSubtle,
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: AppTheme.border),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: AppTheme.border),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
                              ),
                            ),
                            items: _children.map((child) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: child,
                                child: Text(
                                  child['name'] ?? 'Unnamed Child',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (child) {
                              setState(() {
                                _selectedChild = child;
                              });
                              _loadProgressData();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildProgressContent(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressContent() {
    if (_progressData == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 36,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Progress Data Logged',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The therapist has not published milestone records for ${_selectedChild?['name'] ?? 'your child'} yet. Please check back after next clinical session.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    Map<String, dynamic> progress = _progressData!;
    int score = progress['score'] ?? 0;
    String category = progress['category'] ?? 'No Data';
    Color color = _getColorForCategory(category);

    return Column(
      children: [
        // Progress Chart Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            children: [
              Text(
                '${_selectedChild!['name']}\'s Development Progress',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              
              // Donut Chart
              SizedBox(
                height: 180,
                width: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      painter: DonutChartPainter(
                        progress: score.toDouble(),
                        progressColor: color,
                        backgroundColor: AppTheme.surfaceSubtle,
                      ),
                      child: Container(),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$score%",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            color: color,
                          ),
                        ),
                        const Text(
                          "Overall Index",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Category and Message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Last updated: ${_formatDate(progress['updatedAt'])}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Detailed Assessment Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Clinical Metrics Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailItem('Total Questions', '${progress['totalQuestions'] ?? 10}', AppTheme.primary),
                  _buildDetailItem('Positive Responses', '${progress['positiveResponses'] ?? 0}', AppTheme.secondary),
                  _buildDetailItem('Progress Score', '$score%', color),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Therapist Information
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Assessed by: ${progress['therapistName'] ?? 'Assigned Therapist'}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Clinical Note: ${progress['notes'] ?? 'Developmental assessment completed.'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.zero,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Custom Donut Chart Painter (same as therapist page)
class DonutChartPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  DonutChartPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 - 10;
    final innerRadius = outerRadius - 30;
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerRadius - innerRadius
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, (outerRadius + innerRadius) / 2, backgroundPaint);
    
    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerRadius - innerRadius
        ..strokeCap = StrokeCap.round;
      
      final sweepAngle = (progress / 100) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (outerRadius + innerRadius) / 2),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
