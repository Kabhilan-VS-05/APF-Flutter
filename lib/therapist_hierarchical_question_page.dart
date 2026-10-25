import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Clinical Questionnaire Builder',
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
                        labelText: 'Assigned Patient',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: AppTheme.secondary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Parents answer primary questions first. Conditional follow-up subquestions expand automatically when parents indicate "Yes".',
                            style: TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Main Questions
                  ..._mainQuestions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final question = entry.value;
                    return _buildMainQuestionCard(index, question);
                  }),
                  
                  const SizedBox(height: 12),
                  
                  // Add Main Question Button
                  OutlinedButton.icon(
                    onPressed: _addMainQuestion,
                    icon: const Icon(Icons.add, size: 18, color: AppTheme.secondary),
                    label: const Text('Add Primary Question', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: AppTheme.secondary,
                      side: const BorderSide(color: AppTheme.secondary, width: 1.5),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSending ? null : _sendQuestions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
                                    Text('Transmitting Questionnaire...', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Send to Parent Portal', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _buildMainQuestionCard(int index, QuestionItem question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
            // Main Question Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryLight,
                    border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    'PRIMARY QUESTION ${index + 1}',
                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                if (_mainQuestions.length > 1)
                  IconButton(
                    onPressed: () => _removeMainQuestion(index),
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentRose, size: 20),
                    tooltip: 'Remove primary question',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Main Question Input
            TextField(
              controller: question.controller,
              maxLines: 2,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter observation question for parent...',
                hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
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
            ),
            
            const SizedBox(height: 16),
            
            // Subquestions Section Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Branching subquestions (triggered on "Yes"):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addSubQuestion(index),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add Branch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 30),
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
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: AppTheme.border),
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Center(
                  child: Text(
                    'No conditional follow-up questions linked.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ),
              ),
          ],
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
            width: 3,
            height: 38,
            color: AppTheme.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: subQuestion.controller,
              decoration: const InputDecoration(
                hintText: 'Enter follow-up question...',
                hintStyle: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppTheme.secondary, width: 1.5),
                ),
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => _removeSubQuestion(parentIndex, subIndex),
            icon: const Icon(Icons.remove_circle_outline, color: AppTheme.accentRose, size: 18),
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
