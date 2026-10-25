import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Clinical Domain Assessment',
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
      body: Column(
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
                    color: AppTheme.secondaryLight,
                    border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.person_pin_rounded, color: AppTheme.secondary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedChild,
                      decoration: InputDecoration(
                        labelText: 'Active Patient Profile',
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
                          borderSide: BorderSide(color: AppTheme.secondary, width: 1.5),
                        ),
                      ),
                      items: widget.children.map((child) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: child,
                          child: Text(
                            '${child['name']} (Age: ${child['age']})',
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
                          selectedChild = child!;
                          answers.clear();
                          _resetControllers();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Questions Form
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.secondary))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Standardized Evaluation Criteria',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_questions.length} domains',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        ..._questions.map((question) => _buildQuestion(question)),
                        
                        const SizedBox(height: 20),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isGenerating ? null : _generateReport,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.secondary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
                                          Text('Publishing Findings...', style: TextStyle(fontWeight: FontWeight.w700)),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.assignment_turned_in_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Publish Assessment', style: TextStyle(fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  foregroundColor: AppTheme.textPrimary,
                                  side: const BorderSide(color: AppTheme.border),
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    questionText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (isRequired)
                  const Text(
                    ' *',
                    style: TextStyle(
                      color: AppTheme.accentRose,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            
            if (questionType == 'choice')
              _buildChoiceQuestion(question)
            else if (questionType == 'text')
              _buildTextQuestion(question),
          ],
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
        final isSelected = selectedOption == option;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.secondaryLight.withValues(alpha: 0.35) : AppTheme.surfaceSubtle,
            border: Border.all(
              color: isSelected ? AppTheme.secondary : AppTheme.border,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.zero,
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                answers[questionId] = option;
              });
            },
            borderRadius: BorderRadius.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.secondary : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppTheme.secondary : AppTheme.border,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextQuestion(Map<String, dynamic> question) {
    final questionId = question['id'] as String;
    final placeholder = question['placeholder'] as String? ?? '';
    
    if (!_controllers.containsKey(questionId)) {
      _controllers[questionId] = TextEditingController();
    }
    final controller = _controllers[questionId]!;

    return TextField(
      controller: controller,
      maxLines: 3,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 13,
        ),
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
          borderSide: BorderSide(color: AppTheme.secondary, width: 1.5),
        ),
        filled: true,
        fillColor: AppTheme.surfaceSubtle,
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
