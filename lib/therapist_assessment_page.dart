import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';
import 'services/auth_service.dart';

class TherapistAssessmentPage extends StatefulWidget {
  final Map<String, dynamic> child;
  final List<Map<String, dynamic>> children;

  const TherapistAssessmentPage({
    super.key,
    required this.child,
    required this.children,
  });

  @override
  State<TherapistAssessmentPage> createState() => _TherapistAssessmentPageState();
}

class _TherapistAssessmentPageState extends State<TherapistAssessmentPage> {
  final ChildService _childService = ChildService();
  final AuthService _authService = AuthService();
  Map<String, dynamic> selectedChild = {};
  Map<String, dynamic> answers = {};
  Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  bool _isGenerating = false;

  // Default assessment questions
  final List<Map<String, dynamic>> _questions = [
    {
      'id': 'overall_improvement',
      'type': 'choice',
      'question': 'Overall improvement since last session',
      'options': ['Significant Improvement', 'Moderate Improvement', 'No Change', 'Slight Decline', 'Significant Decline'],
      'required': true,
    },
    {
      'id': 'communication_skills',
      'type': 'choice',
      'question': 'Communication and language skills',
      'options': ['Excellent', 'Good', 'Average', 'Needs Improvement', 'Poor'],
      'required': true,
    },
    {
      'id': 'social_interaction',
      'type': 'choice',
      'question': 'Social interaction with peers',
      'options': ['Very Comfortable', 'Comfortable', 'Somewhat Comfortable', 'Uncomfortable', 'Very Uncomfortable'],
      'required': true,
    },
    {
      'id': 'behavior_pattern',
      'type': 'choice',
      'question': 'Behavior pattern during session',
      'options': ['Very Cooperative', 'Cooperative', 'Neutral', 'Slightly Difficult', 'Very Difficult'],
      'required': true,
    },
    {
      'id': 'attention_span',
      'type': 'choice',
      'question': 'Attention and focus duration',
      'options': ['Excellent (>15 min)', 'Good (10-15 min)', 'Average (5-10 min)', 'Poor (2-5 min)', 'Very Poor (<2 min)'],
      'required': true,
    },
    {
      'id': 'strengths',
      'type': 'text',
      'question': 'Child\'s strengths observed during session',
      'placeholder': 'Describe what the child did well...',
      'required': true,
    },
    {
      'id': 'areas_for_improvement',
      'type': 'text',
      'question': 'Areas needing improvement',
      'placeholder': 'Describe areas where the child needs more work...',
      'required': true,
    },
    {
      'id': 'activities_completed',
      'type': 'text',
      'question': 'Activities completed during session',
      'placeholder': 'List activities and child\'s response...',
      'required': false,
    },
    {
      'id': 'parent_recommendations',
      'type': 'text',
      'question': 'Recommendations for parents to practice at home',
      'placeholder': 'Provide specific activities or exercises...',
      'required': true,
    },
    {
      'id': 'next_session_focus',
      'type': 'text',
      'question': 'Focus areas for next session',
      'placeholder': 'What should be prioritized in the next session...',
      'required': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    selectedChild = widget.child;
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final question in _questions) {
      if (question['type'] == 'text') {
        _controllers[question['id']] = TextEditingController();
      }
    }
  }

  void _resetControllers() {
    // Clear existing controllers
    for (final controller in _controllers.values) {
      controller.clear();
    }
    // Reinitialize to ensure all text questions have controllers
    _initializeControllers();
  }

  @override
  void dispose() {
    // Clean up controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Assessment'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Child Selection Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assessment for:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: selectedChild,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: widget.children.map((child) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: child,
                      child: Text('${child['name']} (Age: ${child['age']})'),
                    );
                  }).toList(),
                  onChanged: (child) {
                    setState(() {
                      selectedChild = child!;
                      answers.clear(); // Reset answers when child changes
                      _resetControllers(); // Reset text controllers
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Questions Form
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assessment Questions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        ..._questions.map((question) => _buildQuestion(question)).toList(),
                        
                        const SizedBox(height: 20),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isGenerating ? null : _generateReport,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF003366),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(16),
                                ),
                                child: _isGenerating
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text('Generating...'),
                                        ],
                                      )
                                    : const Text('Generate Report'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ),
        ],
      ),
    );
  }

  Widget _buildQuestion(Map<String, dynamic> question) {
    final questionId = question['id'] as String;
    final questionType = question['type'] as String;
    final questionText = question['question'] as String;
    final isRequired = question['required'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      questionText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isRequired)
                    const Text(
                      '*',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (questionType == 'choice')
                _buildChoiceQuestion(question)
              else if (questionType == 'text')
                _buildTextQuestion(question),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceQuestion(Map<String, dynamic> question) {
    final questionId = question['id'] as String;
    final options = question['options'] as List<String>;
    final selectedOption = answers[questionId] as String?;

    return Column(
      children: options.map((option) {
        return RadioListTile<String>(
          title: Text(option),
          value: option,
          groupValue: selectedOption,
          onChanged: (value) {
            setState(() {
              answers[questionId] = value!;
            });
          },
          contentPadding: const EdgeInsets.all(0),
          dense: true,
        );
      }).toList(),
    );
  }

  Widget _buildTextQuestion(Map<String, dynamic> question) {
    final questionId = question['id'] as String;
    final placeholder = question['placeholder'] as String? ?? '';
    
    // Ensure controller exists
    if (!_controllers.containsKey(questionId)) {
      _controllers[questionId] = TextEditingController();
    }
    final controller = _controllers[questionId]!;

    return TextField(
      controller: controller,
      maxLines: 3,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF003366), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(12),
      ),
      onChanged: (value) {
        setState(() {
          answers[questionId] = value;
        });
      },
    );
  }

  Future<void> _generateReport() async {
    // Validate required questions
    for (final question in _questions) {
      if (question['required'] as bool) {
        final questionId = question['id'] as String;
        if (answers[questionId] == null || answers[questionId].toString().trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please answer: ${question['question']}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    setState(() => _isGenerating = true);

    try {
      // Get therapist info
      final therapist = await _authService.getUserData(_authService.currentUser!.uid);
      
      // Generate report
      final report = _generateReportContent(therapist);
      
      // Set therapist assessment status
      report['status'] = 'therapist_assessment';
      report['assessmentType'] = 'therapist';
      
      // Save report to Firestore
      await _childService.addTherapistReport(
        childId: selectedChild['id'],
        report: report,
        therapistId: _authService.currentUser!.uid,
        therapistName: therapist?['username'] ?? 'Unknown Therapist',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report generated and sent to parent successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Map<String, dynamic> _generateReportContent(Map<String, dynamic>? therapist) {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    
    return {
      'reportId': FirebaseFirestore.instance.collection('reports').doc().id,
      'childId': selectedChild['id'],
      'childName': selectedChild['name'],
      'therapistId': _authService.currentUser!.uid,
      'therapistName': therapist?['username'] ?? 'Unknown Therapist',
      'assessmentDate': dateStr,
      'createdAt': Timestamp.now(),
      'status': 'sent_to_parent',
      'summary': _generateSummary(),
      'detailedAssessment': answers,
      'recommendations': answers['parent_recommendations'] ?? '',
      'nextSessionFocus': answers['next_session_focus'] ?? '',
      'parentViewed': false,
    };
  }

  String _generateSummary() {
    final overallImprovement = answers['overall_improvement'] ?? 'Not assessed';
    final communication = answers['communication_skills'] ?? 'Not assessed';
    final social = answers['social_interaction'] ?? 'Not assessed';
    final behavior = answers['behavior_pattern'] ?? 'Not assessed';
    final strengths = answers['strengths'] ?? 'No strengths noted';
    
    return '''Assessment Summary for ${selectedChild['name']} - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

Overall Progress: $overallImprovement
Communication Skills: $communication
Social Interaction: $social
Behavior Pattern: $behavior

Key Strengths: $strengths

This assessment provides insights into your child's recent progress and areas of focus for continued development.''';
  }
}
