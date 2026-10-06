import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'services/child_service.dart';
import 'services/auth_service.dart';

class TherapistProgressPage extends StatefulWidget {
  const TherapistProgressPage({super.key});

  @override
  State<TherapistProgressPage> createState() => _TherapistProgressPageState();
}

class _TherapistProgressPageState extends State<TherapistProgressPage> {
  final ChildService _childService = ChildService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _children = [];
  List<Map<String, dynamic>> _progressData = [];
  bool _isLoading = true;
  String? _selectedChildId;
  Map<String, dynamic>? _userData;

  // Standard assessment questions with answer options
  final List<Map<String, dynamic>> _assessmentQuestions = [
    {
      'id': 'respond_name',
      'question': 'Does the child respond to their name?',
      'positiveAnswer': 'Yes',
      'negativeAnswer': 'No',
    },
    {
      'id': 'eye_contact',
      'question': 'Does the child make eye contact?',
      'positiveAnswer': 'Yes',
      'negativeAnswer': 'No',
    },
    {
      'id': 'communicate_needs',
      'question': 'Does the child communicate their needs?',
      'positiveAnswer': 'Yes',
      'negativeAnswer': 'No',
    },
    {
      'id': 'follow_instructions',
      'question': 'Does the child follow simple instructions?',
      'positiveAnswer': 'Yes',
      'negativeAnswer': 'No',
    },
    {
      'id': 'engage_others',
      'question': 'Does the child engage with others?',
      'positiveAnswer': 'Yes',
      'negativeAnswer': 'No',
    },
    {
      'id': 'repetitive_behaviors',
      'question': 'Does the child show repetitive behaviors?',
      'positiveAnswer': 'No', // Reversed - No is positive
      'negativeAnswer': 'Yes', // Reversed - Yes is negative
    },
    {
      'id': 'routine_change',
      'question': 'Does the child get upset with routine change?',
      'positiveAnswer': 'No', // Reversed - No is positive
      'negativeAnswer': 'Yes', // Reversed - Yes is negative
    },
    {
      'id': 'sensitive_sensory',
      'question': 'Is the child sensitive to sound or texture?',
      'positiveAnswer': 'No', // Reversed - No is positive
      'negativeAnswer': 'Yes', // Reversed - Yes is negative
    },
    {
      'id': 'handle_frustration',
      'question': 'Does the child handle frustration well?',
      'positiveAnswer': 'Yes',
      'negativeAnswer': 'No',
    },
    {
      'id': 'sleep_well',
      'question': 'Does the child sleep well?',
      'positiveAnswer': 'Yes',
      'negativeAnswer': 'No',
    },
  ];

  // Store current answers
  Map<String, String> _currentAnswers = {};
  bool _showQuestions = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final children = await _childService.getChildren();
      final userData = await _authService.getUserData(_authService.currentUser!.uid);
      setState(() {
        _children = children;
        _userData = userData;
        if (children.isNotEmpty) {
          _selectedChildId = children.first['id'];
        }
        _isLoading = false;
      });
      
      if (_selectedChildId != null) {
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
    if (_selectedChildId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Only load current progress for the child (no historical data)
      QuerySnapshot progressSnapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('childId', isEqualTo: _selectedChildId)
          .where('therapistId', isEqualTo: _authService.currentUser!.uid)
          .where('type', isEqualTo: 'current_progress')
          .limit(1)
          .get();

      List<Map<String, dynamic>> progressEntries = [];
      
      // Process current progress (only one entry per child)
      for (var doc in progressSnapshot.docs) {
        Map<String, dynamic> progress = doc.data() as Map<String, dynamic>;
        progress['id'] = doc.id;
        progress['type'] = 'current_progress';
        progressEntries.add(progress);
      }

      setState(() {
        _progressData = progressEntries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading progress data: $e')),
      );
    }
  }

  Map<String, dynamic> _calculateProgress() {
    // If we have current answers, use those instead of saved data
    if (_currentAnswers.isNotEmpty) {
      return _calculateProgressFromCurrentAnswers();
    }
    
    // Otherwise, use saved current progress (no historical data)
    if (_progressData.isEmpty) {
      return {
        'score': 0,
        'totalQuestions': 0,
        'positiveResponses': 0,
        'category': 'No Data',
        'color': Colors.grey,
        'message': 'No current progress data. Answer the questions below to assess current stage.',
      };
    }

    // Use the current progress data
    Map<String, dynamic> currentProgress = _progressData.first;
    return {
      'score': currentProgress['score'] ?? 0,
      'totalQuestions': currentProgress['totalQuestions'] ?? _assessmentQuestions.length,
      'positiveResponses': currentProgress['positiveResponses'] ?? 0,
      'category': currentProgress['category'] ?? 'No Data',
      'color': _getColorForCategory(currentProgress['category'] ?? 'No Data'),
      'message': 'Current developmental stage. Last updated: ${_formatDate(currentProgress['updatedAt'])}',
    };
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'unknown time';
    DateTime date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
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

  Map<String, dynamic> _calculateProgressFromCurrentAnswers() {
    int positiveCount = 0;
    int totalQuestions = _assessmentQuestions.length;
    
    for (Map<String, dynamic> question in _assessmentQuestions) {
      String questionId = question['id'] as String;
      String answer = _currentAnswers[questionId] ?? '';
      
      if (answer.isNotEmpty) {
        String positiveAnswer = question['positiveAnswer'] as String;
        if (answer == positiveAnswer) {
          positiveCount++;
        }
      }
    }
    
    if (_currentAnswers.length < _assessmentQuestions.length) {
      return {
        'score': 0,
        'totalQuestions': _currentAnswers.length,
        'positiveResponses': positiveCount,
        'category': 'In Progress',
        'color': Colors.orange,
        'message': 'Please answer all questions to calculate progress. (${_currentAnswers.length}/${_assessmentQuestions.length} completed)',
      };
    }
    
    double score = (positiveCount / totalQuestions) * 100;
    return _getProgressCategory(score, totalQuestions, positiveCount);
  }

  Map<String, dynamic> _getProgressCategory(double score, int totalQuestions, int positiveCount) {
    String category;
    Color color;
    String message;
    
    if (score >= 90) {
      category = 'Excellent Progress';
      color = Colors.green;
      message = 'Child is showing excellent development! Keep up the great work!';
    } else if (score >= 75) {
      category = 'Good Progress';
      color = Colors.lightGreen;
      message = 'Child is developing well with positive progress!';
    } else if (score >= 50) {
      category = 'Making Progress';
      color = Colors.orange;
      message = 'Child is making steady progress. Continue supportive activities!';
    } else if (score >= 25) {
      category = 'Needs Support';
      color = Colors.deepOrange;
      message = 'Child would benefit from additional support and guidance.';
    } else {
      category = 'Requires Focus';
      color = Colors.red;
      message = 'Child needs focused attention and specialized support strategies.';
    }

    return {
      'score': score.round(),
      'totalQuestions': totalQuestions,
      'positiveResponses': positiveCount,
      'category': category,
      'color': color,
      'message': message,
    };
  }

  bool _isPositiveResponse(String question, String answer) {
    // Most questions: "Yes" is positive
    // Some questions might need reversed logic based on clinical assessment
    List<String> negativeIndicators = ['Does the child show repetitive behaviors?', 
                                     'Does the child get upset with routine change?',
                                     'Is the child sensitive to sound or texture?'];
    
    bool isNegativeQuestion = negativeIndicators.any((neg) => 
        question.toLowerCase().contains(neg.toLowerCase().substring(0, 10)));
    
    if (isNegativeQuestion) {
      // For negative indicators, "No" is positive
      return answer.toLowerCase().contains('no');
    } else {
      // For positive indicators, "Yes" is positive
      return answer.toLowerCase().contains('yes');
    }
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
                // Filters Section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      // Child Selection Only
                      DropdownButtonFormField<String>(
                        value: _selectedChildId,
                        decoration: const InputDecoration(
                          labelText: 'Select Child',
                          border: OutlineInputBorder(),
                        ),
                        items: _children.map((child) {
                          return DropdownMenuItem<String>(
                            value: child['id'],
                            child: Text(child['name']),
                          );
                        }).toList(),
                        onChanged: (childId) {
                          setState(() {
                            _selectedChildId = childId;
                          });
                          _loadProgressData();
                        },
                      ),
                    ],
                  ),
                ),

                // Progress Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Progress Chart Card
                        _buildProgressCard(),
                        
                        const SizedBox(height: 16),
                        
                        // Questions Section
                        _buildQuestionsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressCard() {
    Map<String, dynamic> progress = _calculateProgress();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Development Progress',
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
                      progress: progress['score'].toDouble(),
                      progressColor: progress['color'],
                      backgroundColor: Colors.grey[300]!,
                    ),
                    child: Container(),
                  ),
                  Center(
                    child: Text(
                      "${progress['score']}%",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: progress['color'],
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
                color: progress['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: progress['color'].withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    progress['category'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: progress['color'],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progress['message'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Assessment Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showQuestions = !_showQuestions;
                      if (!_showQuestions) {
                        _currentAnswers.clear(); // Clear answers when hiding
                      }
                    });
                  },
                  icon: Icon(_showQuestions ? Icons.expand_less : Icons.expand_more),
                  label: Text(_showQuestions ? 'Hide' : 'Show'),
                ),
              ],
            ),
            
            if (_showQuestions) ...[
              const SizedBox(height: 16),
              
              // Progress indicator
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(
                  value: _currentAnswers.length / _assessmentQuestions.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              
              Text(
                'Answered: ${_currentAnswers.length}/${_assessmentQuestions.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Questions list
              ..._assessmentQuestions.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> question = entry.value;
                return _buildQuestionItem(index + 1, question);
              }).toList(),
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentAnswers.length == _assessmentQuestions.length
                          ? _saveAssessment
                          : null,
                      child: const Text('Save Assessment'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearAnswers,
                      child: const Text('Clear Answers'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionItem(int questionNumber, Map<String, dynamic> question) {
    String questionId = question['id'] as String;
    String questionText = question['question'] as String;
    String positiveAnswer = question['positiveAnswer'] as String;
    String negativeAnswer = question['negativeAnswer'] as String;
    String? selectedAnswer = _currentAnswers[questionId];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: selectedAnswer != null ? Colors.blue[50] : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$questionNumber. $questionText',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          
          // Answer options
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectAnswer(questionId, positiveAnswer),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedAnswer == positiveAnswer ? Colors.green : Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selectedAnswer == positiveAnswer ? Colors.green : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      positiveAnswer,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selectedAnswer == positiveAnswer ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _selectAnswer(questionId, negativeAnswer),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedAnswer == negativeAnswer ? Colors.red : Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selectedAnswer == negativeAnswer ? Colors.red : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      negativeAnswer,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selectedAnswer == negativeAnswer ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectAnswer(String questionId, String answer) {
    setState(() {
      _currentAnswers[questionId] = answer;
    });
  }

  void _clearAnswers() {
    setState(() {
      _currentAnswers.clear();
    });
  }

  Future<void> _saveAssessment() async {
    if (_selectedChildId == null || _currentAnswers.length != _assessmentQuestions.length) {
      return;
    }

    try {
      // Create assessment document using reports collection
      Map<String, dynamic> assessment = {
        'childId': _selectedChildId,
        'childName': _children.firstWhere((child) => child['id'] == _selectedChildId, orElse: () => {'name': 'Unknown'})['name'],
        'therapistId': _authService.currentUser!.uid,
        'therapistName': _userData?['username'] ?? 'Unknown Therapist',
        'type': 'current_progress',
        'title': 'Current Development Stage',
        'answers': _currentAnswers,
        'score': _calculateProgress()['score'],
        'category': _calculateProgress()['category'],
        'updatedAt': Timestamp.now(),
        'status': 'current',
        'assessmentType': 'standard_progress',
        'totalQuestions': _assessmentQuestions.length,
        'positiveResponses': _currentAnswers.values.where((answer) {
          // Count positive responses
          for (Map<String, dynamic> question in _assessmentQuestions) {
            if (question['positiveAnswer'] == answer) return true;
          }
          return false;
        }).length,
        'notes': 'Current developmental stage assessment',
      };

      // Check if existing progress exists for this child
      QuerySnapshot existingProgress = await FirebaseFirestore.instance
          .collection('reports')
          .where('childId', isEqualTo: _selectedChildId)
          .where('therapistId', isEqualTo: _authService.currentUser!.uid)
          .where('type', isEqualTo: 'current_progress')
          .limit(1)
          .get();

      if (existingProgress.docs.isNotEmpty) {
        // Update existing progress document
        String docId = existingProgress.docs.first.id;
        await FirebaseFirestore.instance
            .collection('reports')
            .doc(docId)
            .update(assessment);
      } else {
        // Create new progress document
        await FirebaseFirestore.instance
            .collection('reports')
            .add(assessment);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current progress updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear answers after saving and refresh data
      setState(() {
        _currentAnswers.clear();
        _showQuestions = false;
      });
      
      // Reload progress data to show the updated assessment
      _loadProgressData();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving progress: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Custom Donut Chart Painter
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
