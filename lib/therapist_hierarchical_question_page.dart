import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';
import 'services/auth_service.dart';

class QuestionItem {
  String id;
  String text;
  bool isMainQuestion;
  List<QuestionItem> subQuestions;
  TextEditingController controller;

  QuestionItem({
    required this.id,
    required this.text,
    this.isMainQuestion = true,
    List<QuestionItem>? subQuestions,
  }) : subQuestions = subQuestions ?? [], controller = TextEditingController();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isMainQuestion': isMainQuestion,
      'subQuestions': subQuestions.map((sq) => sq.toMap()).toList(),
    };
  }

  factory QuestionItem.fromMap(Map<String, dynamic> map, {bool isSub = false}) {
    final item = QuestionItem(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: map['text'] ?? '',
      isMainQuestion: map['isMainQuestion'] ?? !isSub,
    );
    
    if (map['subQuestions'] != null) {
      item.subQuestions = (map['subQuestions'] as List)
          .map((sq) => QuestionItem.fromMap(sq, isSub: true))
          .toList();
    }
    
    return item;
  }
}

class TherapistHierarchicalQuestionPage extends StatefulWidget {
  final Map<String, dynamic> child;
  final List<Map<String, dynamic>> children;

  const TherapistHierarchicalQuestionPage({
    super.key,
    required this.child,
    required this.children,
  });

  @override
  State<TherapistHierarchicalQuestionPage> createState() => _TherapistHierarchicalQuestionPageState();
}

class _TherapistHierarchicalQuestionPageState extends State<TherapistHierarchicalQuestionPage> {
  final ChildService _childService = ChildService();
  final AuthService _authService = AuthService();
  Map<String, dynamic> selectedChild = {};
  List<QuestionItem> _mainQuestions = [];
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    selectedChild = widget.child;
    _addInitialMainQuestion();
  }

  @override
  void dispose() {
    for (final question in _mainQuestions) {
      question.controller.dispose();
      for (final subQuestion in question.subQuestions) {
        subQuestion.controller.dispose();
      }
    }
    super.dispose();
  }

  void _addInitialMainQuestion() {
    setState(() {
      _mainQuestions.add(QuestionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '',
      ));
    });
  }

  void _addMainQuestion() {
    setState(() {
      _mainQuestions.add(QuestionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '',
      ));
    });
  }

  void _removeMainQuestion(int index) {
    setState(() {
      final question = _mainQuestions[index];
      question.controller.dispose();
      for (final subQuestion in question.subQuestions) {
        subQuestion.controller.dispose();
      }
      _mainQuestions.removeAt(index);
    });
  }

  void _addSubQuestion(int parentIndex) {
    setState(() {
      _mainQuestions[parentIndex].subQuestions.add(QuestionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '',
        isMainQuestion: false,
      ));
    });
  }

  void _removeSubQuestion(int parentIndex, int subIndex) {
    setState(() {
      final subQuestion = _mainQuestions[parentIndex].subQuestions[subIndex];
      subQuestion.controller.dispose();
      _mainQuestions[parentIndex].subQuestions.removeAt(subIndex);
    });
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
                    'Hierarchical Questions for Parent',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create main questions with optional subquestions. Parents will answer main questions first, and only see subquestions if they answer "Yes".',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Main Questions
                  ..._mainQuestions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final question = entry.value;
                    return _buildMainQuestionCard(index, question);
                  }).toList(),
                  
                  const SizedBox(height: 16),
                  
                  // Add Main Question Button
                  OutlinedButton.icon(
                    onPressed: _addMainQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Main Question'),
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

  Widget _buildMainQuestionCard(int index, QuestionItem question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Question Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003366),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'MAIN QUESTION',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_mainQuestions.length > 1)
                    IconButton(
                      onPressed: () => _removeMainQuestion(index),
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      tooltip: 'Remove main question',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Main Question Input
              TextField(
                controller: question.controller,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Enter main question here...',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Subquestions Section
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Subquestions (shown if parent answers "Yes"):',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _addSubQuestion(index),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size(0, 32),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Subquestions List
              if (question.subQuestions.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: question.subQuestions.asMap().entries.map((entry) {
                      final subIndex = entry.key;
                      final subQuestion = entry.value;
                      return _buildSubQuestionCard(index, subIndex, subQuestion);
                    }).toList(),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: const Center(
                    child: Text(
                      'No subquestions added yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubQuestionCard(int parentIndex, int subIndex, QuestionItem subQuestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: subQuestion.controller,
              decoration: const InputDecoration(
                hintText: 'Enter subquestion...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _removeSubQuestion(parentIndex, subIndex),
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
            tooltip: 'Remove subquestion',
          ),
        ],
      ),
    );
  }

  Future<void> _sendQuestions() async {
    // Validate questions
    final validMainQuestions = <Map<String, dynamic>>[];
    
    for (final mainQuestion in _mainQuestions) {
      final mainText = mainQuestion.controller.text.trim();
      if (mainText.isEmpty) continue;
      
      final validSubQuestions = <Map<String, dynamic>>[];
      for (final subQuestion in mainQuestion.subQuestions) {
        final subText = subQuestion.controller.text.trim();
        if (subText.isNotEmpty) {
          validSubQuestions.add({
            'id': subQuestion.id,
            'text': subText,
          });
        }
      }
      
      validMainQuestions.add({
        'id': mainQuestion.id,
        'text': mainText,
        'subQuestions': validSubQuestions,
      });
    }

    if (validMainQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one main question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // Get therapist info
      final therapist = await _authService.getUserData(_authService.currentUser!.uid);
      
      // Create hierarchical question set
      final questionSet = {
        'id': FirebaseFirestore.instance.collection('parent_questions').doc().id,
        'childId': selectedChild['id'],
        'childName': selectedChild['name'],
        'therapistId': _authService.currentUser!.uid,
        'therapistName': therapist?['username'] ?? 'Unknown Therapist',
        'questions': validMainQuestions,
        'sentAt': Timestamp.now(),
        'status': 'pending',
        'responses': <Map<String, dynamic>>[],
        'type': 'hierarchical', // New field to distinguish from flat questions
      };

      // Save to Firestore
      await FirebaseFirestore.instance.collection('parent_questions').add(questionSet);

      // Send notification to parent
      await _sendNotificationToParent(questionSet);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hierarchical questions sent to parent successfully!'),
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
        'message': 'Therapist has sent hierarchical questions about ${questionSet['childName']}',
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
