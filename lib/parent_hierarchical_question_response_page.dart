import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

class ParentHierarchicalQuestionResponsePage extends StatefulWidget {
  const ParentHierarchicalQuestionResponsePage({super.key});

  @override
  State<ParentHierarchicalQuestionResponsePage> createState() => _ParentHierarchicalQuestionResponsePageState();
}

class _ParentHierarchicalQuestionResponsePageState extends State<ParentHierarchicalQuestionResponsePage> {
  final ChildService _childService = ChildService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _children = [];
  List<Map<String, dynamic>> _questionSets = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _selectedChildId;

  // Current question tracking
  Map<String, dynamic>? _currentQuestionSet;
  int _currentMainQuestionIndex = 0;
  int _currentSubQuestionIndex = 0;
  bool _isAnsweringSubQuestions = false;
  List<Map<String, dynamic>> _responses = [];
  String? _currentMainQuestionAnswer;

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
          _selectedChildId = children.first['id'];
        }
        _isLoading = false;
      });
      
      if (_selectedChildId != null) {
        _loadQuestionSets();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _loadQuestionSets() async {
    if (_selectedChildId == null) return;
    
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('parent_questions')
          .where('childId', isEqualTo: _selectedChildId)
          .where('status', whereIn: ['pending'])
          .where('type', isEqualTo: 'hierarchical') // Only load hierarchical questions
          .orderBy('sentAt', descending: true)
          .get();

      List<Map<String, dynamic>> questionSets = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> questionSet = doc.data() as Map<String, dynamic>;
        questionSet['id'] = doc.id;
        questionSets.add(questionSet);
      }

      setState(() {
        _questionSets = questionSets;
      });
    } catch (e) {
      // Fallback query
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('parent_questions')
            .where('childId', isEqualTo: _selectedChildId)
            .where('status', whereIn: ['pending'])
            .get();

        List<Map<String, dynamic>> questionSets = [];
        for (var doc in snapshot.docs) {
          Map<String, dynamic> questionSet = doc.data() as Map<String, dynamic>;
          if (questionSet['type'] == 'hierarchical') {
            questionSet['id'] = doc.id;
            questionSets.add(questionSet);
          }
        }

        questionSets.sort((a, b) {
          Timestamp aTime = a['sentAt'] as Timestamp;
          Timestamp bTime = b['sentAt'] as Timestamp;
          return bTime.compareTo(aTime);
        });

        setState(() {
          _questionSets = questionSets;
        });
      } catch (fallbackError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading question sets: $fallbackError')),
        );
      }
    }
  }

  void _startQuestionAnswering(Map<String, dynamic> questionSet) {
    setState(() {
      _currentQuestionSet = questionSet;
      _currentMainQuestionIndex = 0;
      _currentSubQuestionIndex = 0;
      _isAnsweringSubQuestions = false;
      _responses = [];
      _currentMainQuestionAnswer = null;
    });
  }

  void _answerMainQuestion(String answer) {
    setState(() {
      _currentMainQuestionAnswer = answer;
      
      // Record the main question response
      final mainQuestion = _currentQuestionSet!['questions'][_currentMainQuestionIndex];
      _responses.add({
        'questionId': mainQuestion['id'],
        'questionText': mainQuestion['text'],
        'answer': answer,
        'isMainQuestion': true,
        'answeredAt': Timestamp.now(),
      });

      // If answer is "Yes" and there are subquestions, go to subquestions
      if (answer.toLowerCase() == 'yes' && 
          mainQuestion['subQuestions'] != null && 
          mainQuestion['subQuestions'].isNotEmpty) {
        _isAnsweringSubQuestions = true;
        _currentSubQuestionIndex = 0;
      } else {
        // Skip to next main question
        _nextMainQuestion();
      }
    });
  }

  void _answerSubQuestion(String answer) {
    setState(() {
      final mainQuestion = _currentQuestionSet!['questions'][_currentMainQuestionIndex];
      final subQuestion = mainQuestion['subQuestions'][_currentSubQuestionIndex];
      
      _responses.add({
        'questionId': subQuestion['id'],
        'questionText': subQuestion['text'],
        'answer': answer,
        'isMainQuestion': false,
        'parentQuestionId': mainQuestion['id'],
        'answeredAt': Timestamp.now(),
      });

      _currentSubQuestionIndex++;
      
      // Check if all subquestions are answered
      if (_currentSubQuestionIndex >= mainQuestion['subQuestions'].length) {
        _nextMainQuestion();
      }
    });
  }

  void _nextMainQuestion() {
    setState(() {
      _currentMainQuestionIndex++;
      _currentSubQuestionIndex = 0;
      _isAnsweringSubQuestions = false;
      _currentMainQuestionAnswer = null;
    });
  }

  void _skipToNextMainQuestion() {
    setState(() {
      _responses.add({
        'questionId': _currentQuestionSet!['questions'][_currentMainQuestionIndex]['id'],
        'questionText': _currentQuestionSet!['questions'][_currentMainQuestionIndex]['text'],
        'answer': 'Skipped',
        'isMainQuestion': true,
        'answeredAt': Timestamp.now(),
      });
      _nextMainQuestion();
    });
  }

  Future<void> _submitResponses() async {
    if (_currentQuestionSet == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Update the question set with responses
      await FirebaseFirestore.instance
          .collection('parent_questions')
          .doc(_currentQuestionSet!['id'])
          .update({
        'status': 'completed',
        'responses': _responses,
        'completedAt': Timestamp.now(),
      });

      // Send notification to therapist
      await _sendNotificationToTherapist(_currentQuestionSet!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Responses submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _currentQuestionSet = null;
        _responses = [];
      });

      // Refresh question sets
      _loadQuestionSets();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting responses: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendNotificationToTherapist(Map<String, dynamic> questionSet) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': questionSet['therapistId'],
      'type': 'questions_answered',
      'title': 'Parent Answered Questions',
      'message': 'Parent has answered questions about ${questionSet['childName']}',
      'data': {
        'questionSetId': questionSet['id'],
        'childId': questionSet['childId'],
        'childName': questionSet['childName'],
      },
      'createdAt': Timestamp.now(),
      'read': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Answer Questions',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _currentQuestionSet != null
              ? _buildQuestionAnsweringView()
              : _buildQuestionSetsList(),
    );
  }

  Widget _buildQuestionSetsList() {
    return Column(
      children: [
        // Child Selection Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SELECT PATIENT CHILD',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedChildId,
                style: const TextStyle(fontSize: 14.5, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: AppTheme.surfaceSubtle,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.primary, width: 1.5)),
                ),
                items: _children.map((child) {
                  return DropdownMenuItem<String>(
                    value: child['id'],
                    child: Text('${child['name']} (Age: ${child['age']})'),
                  );
                }).toList(),
                onChanged: (childId) {
                  setState(() {
                    _selectedChildId = childId;
                  });
                  _loadQuestionSets();
                },
              ),
            ],
          ),
        ),
        
        // Question Sets List
        Expanded(
          child: _questionSets.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 1.2),
                          ),
                          child: const Icon(
                            Icons.assignment_turned_in_outlined,
                            size: 36,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'No Pending Questions',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Check back later for new questionnaires from your therapist.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _questionSets.length,
                  itemBuilder: (context, index) {
                    final questionSet = _questionSets[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: AppTheme.border),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.zero,
                                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    questionSet['childName']?.toString().substring(0, 1).toUpperCase() ?? 'C',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Questions for ${questionSet['childName']}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'From: ${questionSet['therapistName'] ?? 'Therapist'}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        'Sent: ${_formatDate(questionSet['sentAt'])}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '${(questionSet['questions'] as List).length} main questions',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () => _startQuestionAnswering(questionSet),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                                child: const Text(
                                  'Start Answering',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQuestionAnsweringView() {
    if (_currentMainQuestionIndex >= _currentQuestionSet!['questions'].length) {
      // All questions answered - show completion screen
      return _buildCompletionScreen();
    }

    final currentMainQuestion = _currentQuestionSet!['questions'][_currentMainQuestionIndex];
    
    if (_isAnsweringSubQuestions) {
      final subQuestions = currentMainQuestion['subQuestions'] as List;
      if (_currentSubQuestionIndex >= subQuestions.length) {
        // Should not happen, but safety check
        _nextMainQuestion();
        return Container(); // Will rebuild
      }
      
      final currentSubQuestion = subQuestions[_currentSubQuestionIndex];
      return _buildSubQuestionView(currentSubQuestion, currentMainQuestion);
    } else {
      return _buildMainQuestionView(currentMainQuestion);
    }
  }

  Widget _buildMainQuestionView(Map<String, dynamic> mainQuestion) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentMainQuestionIndex + 1) / _currentQuestionSet!['questions'].length,
            backgroundColor: AppTheme.surfaceSubtle,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Question ${_currentMainQuestionIndex + 1} of ${_currentQuestionSet!['questions'].length}',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Question Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.zero,
              border: const Border(
                top: BorderSide(color: AppTheme.primary, width: 3),
                left: BorderSide(color: AppTheme.border),
                right: BorderSide(color: AppTheme.border),
                bottom: BorderSide(color: AppTheme.border),
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Text(
                    'MAIN QUESTION',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  mainQuestion['text'] ?? '',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 28),
          
          // Answer options
          const Text(
            'Your Answer:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _answerMainQuestion('Yes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text(
                'Yes',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => _answerMainQuestion('No'),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppTheme.surface,
                side: const BorderSide(color: AppTheme.border, width: 1.2),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text(
                'No',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _skipToNextMainQuestion,
              child: const Text(
                'Skip this question',
                style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubQuestionView(Map<String, dynamic> subQuestion, Map<String, dynamic> mainQuestion) {
    final totalSubQuestions = (mainQuestion['subQuestions'] as List).length;
    final TextEditingController _textController = TextEditingController();
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator for subquestions
          LinearProgressIndicator(
            value: (_currentSubQuestionIndex + 1) / totalSubQuestions,
            backgroundColor: AppTheme.surfaceSubtle,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Subquestion ${_currentSubQuestionIndex + 1} of $totalSubQuestions',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Question Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.zero,
              border: const Border(
                top: BorderSide(color: AppTheme.primary, width: 3),
                left: BorderSide(color: AppTheme.border),
                right: BorderSide(color: AppTheme.border),
                bottom: BorderSide(color: AppTheme.border),
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Text(
                    'SUBQUESTION',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  subQuestion['text'] ?? '',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 28),
          
          // Answer options
          const Text(
            'Your Answer:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          // Text field for detailed answer
          TextField(
            controller: _textController,
            maxLines: 4,
            style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Enter your detailed answer here...',
              border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.primary, width: 1.5)),
              filled: true,
              fillColor: AppTheme.surface,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final answer = _textController.text.trim();
                      if (answer.isNotEmpty) {
                        _answerSubQuestion(answer);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter an answer'),
                            backgroundColor: AppTheme.warning,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: Text(
                      _currentSubQuestionIndex < totalSubQuestions - 1 
                          ? 'Next Question' 
                          : 'Finish Subquestions',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    _answerSubQuestion('Skipped');
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    side: const BorderSide(color: AppTheme.border, width: 1.2),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.successLight,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppTheme.success.withValues(alpha: 0.3), width: 1.5),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 40,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'All Questions Answered!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ve answered ${_responses.length} questions for ${_currentQuestionSet!['childName']}',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitResponses,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: _isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Submitting...'),
                      ],
                    )
                  : const Text(
                      'Submit Responses',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentQuestionSet = null;
                  _responses = [];
                });
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: AppTheme.surface,
                side: const BorderSide(color: AppTheme.border, width: 1.2),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown date';
    
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime questionDate = DateTime(date.year, date.month, date.day);
    
    if (questionDate == today) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (questionDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
