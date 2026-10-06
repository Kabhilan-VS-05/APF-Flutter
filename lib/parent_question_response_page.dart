import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';
import 'services/auth_service.dart';

class ParentQuestionResponsePage extends StatefulWidget {
  const ParentQuestionResponsePage({super.key});

  @override
  State<ParentQuestionResponsePage> createState() => _ParentQuestionResponsePageState();
}

class _ParentQuestionResponsePageState extends State<ParentQuestionResponsePage> {
  final ChildService _childService = ChildService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _children = [];
  List<Map<String, dynamic>> _questionSets = [];
  Map<String, TextEditingController> _answerControllers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _selectedChildId;

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
          .where('status', whereIn: ['pending']) // Only show unanswered questions
          .orderBy('sentAt', descending: true)
          .get();

      List<Map<String, dynamic>> questionSets = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> questionSet = doc.data() as Map<String, dynamic>;
        questionSet['id'] = doc.id;
        questionSets.add(questionSet);
      }

      // Sort client-side as fallback
      questionSets.sort((a, b) {
        Timestamp aTime = a['sentAt'] as Timestamp;
        Timestamp bTime = b['sentAt'] as Timestamp;
        return bTime.compareTo(aTime); // Descending order
      });

      setState(() {
        _questionSets = questionSets;
      });
    } catch (e) {
      // Fallback to query without ordering if index not ready
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('parent_questions')
            .where('childId', isEqualTo: _selectedChildId)
            .where('status', whereIn: ['pending']) // Only show unanswered questions
            .get();

        List<Map<String, dynamic>> questionSets = [];
        for (var doc in snapshot.docs) {
          Map<String, dynamic> questionSet = doc.data() as Map<String, dynamic>;
          questionSet['id'] = doc.id;
          questionSets.add(questionSet);
        }

        // Sort client-side
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
          SnackBar(content: Text('Error loading questions: $fallbackError')),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Answer Therapist Questions'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Child Selection
                if (_children.length > 1)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: DropdownButtonFormField<String>(
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
                        _loadQuestionSets();
                      },
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
                                Icons.question_answer,
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
                                'All questions have been answered or no questions have been sent yet',
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
                            return _buildQuestionSetCard(questionSet);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuestionSetCard(Map<String, dynamic> questionSet) {
    final sentAt = questionSet['sentAt'] as Timestamp?;
    final date = sentAt?.toDate() ?? DateTime.now();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Questions from ${questionSet['therapistName'] ?? 'Therapist'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For: ${questionSet['childName']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PENDING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Questions List
              ...questionSet['questions'].map<Widget>((question) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          question,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sent: ${date.day}/${date.month}/${date.year}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showAnswerDialog(questionSet),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Answer Questions'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnswerDialog(Map<String, dynamic> questionSet) {
    final questions = List<String>.from(questionSet['questions']);
    
    // Initialize controllers for this question set
    for (int i = 0; i < questions.length; i++) {
      _answerControllers['${questionSet['id']}_$i'] = TextEditingController();
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Answer Questions',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Question ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003366),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              questions[index],
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _answerControllers['${questionSet['id']}_$index'],
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Enter your answer...',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _submitAnswers(questionSet, questions),
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
                            : const Text('Submit Answers'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAnswersDialog(Map<String, dynamic> questionSet) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your Answers',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: questionSet['questions'].length,
                    itemBuilder: (context, index) {
                      final question = questionSet['questions'][index];
                      final answer = questionSet['responses'][index]['answer'];
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Question ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003366),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                question,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Your Answer:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                answer,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitAnswers(Map<String, dynamic> questionSet, List<String> questions) async {
    final responses = <Map<String, dynamic>>[];
    
    for (int i = 0; i < questions.length; i++) {
      final controller = _answerControllers['${questionSet['id']}_$i'];
      final answer = controller?.text.trim() ?? '';
      
      if (answer.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please answer all questions'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      responses.add({
        'question': questions[i],
        'answer': answer,
        'answeredAt': Timestamp.now(),
      });
    }

    setState(() => _isSubmitting = true);

    try {
      // Update question set with responses
      await FirebaseFirestore.instance
          .collection('parent_questions')
          .doc(questionSet['id'])
          .update({
        'status': 'responded',
        'responses': responses,
        'respondedAt': Timestamp.now(),
      });

      // Send notification to therapist
      await _sendNotificationToTherapist(questionSet);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Answers submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Close dialog
      _loadQuestionSets(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting answers: $e'),
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
      'message': 'Parent has answered your questions about ${questionSet['childName']}',
      'data': {
        'questionSetId': questionSet['id'],
        'childId': questionSet['childId'],
        'childName': questionSet['childName'],
      },
      'createdAt': Timestamp.now(),
      'read': false,
    });
  }
}
