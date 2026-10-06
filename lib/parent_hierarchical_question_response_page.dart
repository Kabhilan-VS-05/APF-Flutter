import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';
import 'services/auth_service.dart';

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
      appBar: AppBar(
        title: const Text('Answer Questions'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Child:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedChildId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No pending questions',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Check back later for new questions from your therapist',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _questionSets.length,
                  itemBuilder: (context, index) {
                    final questionSet = _questionSets[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFF003366),
                                  child: Text(
                                    questionSet['childName']?.toString().substring(0, 1).toUpperCase() ?? 'C',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Questions for ${questionSet['childName']}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF003366),
                                        ),
                                      ),
                                      Text(
                                        'From: ${questionSet['therapistName'] ?? 'Therapist'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        'Sent: ${_formatDate(questionSet['sentAt'])}',
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
                            const SizedBox(height: 12),
                            Text(
                              '${(questionSet['questions'] as List).length} main questions',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _startQuestionAnswering(questionSet),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF003366),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Start Answering'),
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
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF003366)),
          ),
          const SizedBox(height: 8),
          Text(
            'Question ${_currentMainQuestionIndex + 1} of ${_currentQuestionSet!['questions'].length}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF003366),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'MAIN QUESTION',
                    style: TextStyle(
                      color: Color(0xFF003366),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  mainQuestion['text'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Answer options
          const Text(
            'Your Answer:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _answerMainQuestion('Yes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Yes',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _answerMainQuestion('No'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'No',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _skipToNextMainQuestion,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Skip this question',
                style: TextStyle(fontSize: 14),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator for subquestions
          LinearProgressIndicator(
            value: (_currentSubQuestionIndex + 1) / totalSubQuestions,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            'Subquestion ${_currentSubQuestionIndex + 1} of $totalSubQuestions',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blue,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SUBQUESTION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subQuestion['text'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF003366),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Answer options
          const Text(
            'Your Answer:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
          const SizedBox(height: 16),
          
          // Text field for detailed answer
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Enter your detailed answer here...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(fontSize: 16),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final answer = _textController.text.trim();
                    if (answer.isNotEmpty) {
                      _answerSubQuestion(answer);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter an answer'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Text(
                    _currentSubQuestionIndex < totalSubQuestions - 1 
                        ? 'Next Question' 
                        : 'Finish Subquestions',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  _answerSubQuestion('Skipped');
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(fontSize: 16),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          const Text(
            'All Questions Answered!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You\'ve answered ${_responses.length} questions for ${_currentQuestionSet!['childName']}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitResponses,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: _isSubmitting
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
                        Text('Submitting...'),
                      ],
                    )
                  : const Text(
                      'Submit Responses',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentQuestionSet = null;
                  _responses = [];
                });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16),
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
