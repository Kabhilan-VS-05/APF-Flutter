import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';
import 'services/auth_service.dart';

class TherapistQuestionPage extends StatefulWidget {
  final Map<String, dynamic> child;
  final List<Map<String, dynamic>> children;

  const TherapistQuestionPage({
    super.key,
    required this.child,
    required this.children,
  });

  @override
  State<TherapistQuestionPage> createState() => _TherapistQuestionPageState();
}

class _TherapistQuestionPageState extends State<TherapistQuestionPage> {
  final ChildService _childService = ChildService();
  final AuthService _authService = AuthService();
  Map<String, dynamic> selectedChild = {};
  List<Map<String, dynamic>> _questions = [];
  Map<String, TextEditingController> _questionControllers = {};
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    selectedChild = widget.child;
    _initializeQuestionControllers();
  }

  void _initializeQuestionControllers() {
    // Start with 3 question fields
    for (int i = 0; i < 3; i++) {
      _questionControllers['question_$i'] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _questionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Questions to Parent'),
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
                  'Send questions for:',
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
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Questions Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Questions for Parent',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter questions you would like the parent to answer about their child\'s progress at home.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Question Fields
                  ..._questionControllers.entries.map((entry) {
                    final index = entry.key.split('_').last;
                    return _buildQuestionField(int.parse(index), entry.value);
                  }).toList(),
                  
                  const SizedBox(height: 16),
                  
                  // Add Question Button
                  OutlinedButton.icon(
                    onPressed: _addQuestionField,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Another Question'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSending ? null : _sendQuestions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                          child: _isSending
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
                                    Text('Sending...'),
                                  ],
                                )
                              : const Text('Send Questions'),
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

  Widget _buildQuestionField(int index, TextEditingController controller) {
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
                  Text(
                    'Question ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const Spacer(),
                  if (_questionControllers.length > 1)
                    IconButton(
                      onPressed: () => _removeQuestionField(index),
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      tooltip: 'Remove question',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Enter your question here...',
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
        ),
      ),
    );
  }

  void _addQuestionField() {
    setState(() {
      final newIndex = _questionControllers.length;
      _questionControllers['question_$newIndex'] = TextEditingController();
    });
  }

  void _removeQuestionField(int index) {
    setState(() {
      final key = 'question_$index';
      _questionControllers[key]?.dispose();
      _questionControllers.remove(key);
      
      // Reindex remaining controllers
      final newControllers = <String, TextEditingController>{};
      int newIndex = 0;
      for (final entry in _questionControllers.entries) {
        if (entry.key != key) {
          newControllers['question_$newIndex'] = entry.value;
          newIndex++;
        }
      }
      _questionControllers = newControllers;
    });
  }

  Future<void> _sendQuestions() async {
    // Validate questions
    final validQuestions = <String>[];
    for (final controller in _questionControllers.values) {
      final question = controller.text.trim();
      if (question.isNotEmpty) {
        validQuestions.add(question);
      }
    }

    if (validQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // Get therapist info
      final therapist = await _authService.getUserData(_authService.currentUser!.uid);
      
      // Create question set
      final questionSet = {
        'id': FirebaseFirestore.instance.collection('parent_questions').doc().id,
        'childId': selectedChild['id'],
        'childName': selectedChild['name'],
        'therapistId': _authService.currentUser!.uid,
        'therapistName': therapist?['username'] ?? 'Unknown Therapist',
        'questions': validQuestions,
        'sentAt': Timestamp.now(),
        'status': 'pending',
        'responses': <Map<String, dynamic>>[],
      };

      // Save to Firestore
      await FirebaseFirestore.instance.collection('parent_questions').add(questionSet);

      // Send notification to parent
      await _sendNotificationToParent(questionSet);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Questions sent to parent successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending questions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _sendNotificationToParent(Map<String, dynamic> questionSet) async {
    // Get child details to find parent
    DocumentSnapshot childDoc = await FirebaseFirestore.instance
        .collection('children')
        .doc(questionSet['childId'])
        .get();
    
    if (childDoc.exists) {
      Map<String, dynamic> childData = childDoc.data() as Map<String, dynamic>;
      String parentId = childData['parentId'];

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': parentId,
        'type': 'new_questions',
        'title': 'New Questions from Therapist',
        'message': 'Therapist has sent ${questionSet['questions'].length} questions about ${questionSet['childName']}',
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
}
