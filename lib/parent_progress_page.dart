import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'services/child_service.dart';
import 'services/auth_service.dart';

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
        return Colors.green;
      case 'Good Progress':
        return Colors.lightGreen;
      case 'Making Progress':
        return Colors.orange;
      case 'Needs Support':
        return Colors.deepOrange;
      case 'Requires Focus':
        return Colors.red;
      default:
        return Colors.grey;
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
      appBar: AppBar(
        title: const Text('Child Progress'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Child Selection
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedChild,
                    decoration: const InputDecoration(
                      labelText: 'Select Child',
                      border: OutlineInputBorder(),
                    ),
                    items: _children.map((child) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: child,
                        child: Text(child['name']),
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

                // Progress Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildProgressContent(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressContent() {
    if (_progressData == null) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Progress Data Available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The therapist hasn\'t assessed ${_selectedChild?['name'] ?? 'your child\'s'} progress yet. Please check back later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
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
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  '${_selectedChild!['name']}\'s Development Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Donut Chart
                Container(
                  height: 200,
                  width: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        painter: DonutChartPainter(
                          progress: score.toDouble(),
                          progressColor: color,
                          backgroundColor: Colors.grey[300]!,
                        ),
                        child: Container(),
                      ),
                      Center(
                        child: Text(
                          "$score%",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Category and Message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last updated: ${_formatDate(progress['updatedAt'])}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Detailed Assessment Card
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assessment Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailItem('Total Questions', '${progress['totalQuestions'] ?? 10}', Colors.blue),
                    _buildDetailItem('Positive Responses', '${progress['positiveResponses'] ?? 0}', Colors.green),
                    _buildDetailItem('Progress Score', '$score%', color),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Therapist Information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assessed by: ${progress['therapistName'] ?? 'Therapist'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Notes: ${progress['notes'] ?? 'Developmental assessment completed'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
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
