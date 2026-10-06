import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';
import 'services/auth_service.dart';
import 'services/pdf_service.dart';

class TherapistQuestionResponsesPage extends StatefulWidget {
  const TherapistQuestionResponsesPage({super.key});

  @override
  State<TherapistQuestionResponsesPage> createState() => _TherapistQuestionResponsesPageState();
}

class _TherapistQuestionResponsesPageState extends State<TherapistQuestionResponsesPage> {
  final ChildService _childService = ChildService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _children = [];
  List<Map<String, dynamic>> _questionSets = [];
  List<Map<String, dynamic>> _filteredQuestionSets = [];
  bool _isLoading = true;
  String? _selectedChildId;
  DateTime? _startDate;
  DateTime? _endDate;

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
          .where('therapistId', isEqualTo: _authService.currentUser!.uid)
          .where('status', whereIn: ['responded', 'completed'])
          .get();

      List<Map<String, dynamic>> questionSets = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> questionSet = doc.data() as Map<String, dynamic>;
        questionSet['id'] = doc.id;
        questionSets.add(questionSet);
      }

      // Sort client-side by both respondedAt and completedAt
      questionSets.sort((a, b) {
        Timestamp aTime = a['respondedAt'] as Timestamp? ?? a['completedAt'] as Timestamp? ?? Timestamp.now();
        Timestamp bTime = b['respondedAt'] as Timestamp? ?? b['completedAt'] as Timestamp? ?? Timestamp.now();
        return bTime.compareTo(aTime); // Descending order
      });

      setState(() {
        _questionSets = questionSets;
        _applyFilters();
      });
    } catch (e) {
      // Fallback to query without ordering if index not ready
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('parent_questions')
            .where('childId', isEqualTo: _selectedChildId)
            .where('therapistId', isEqualTo: _authService.currentUser!.uid)
            .where('status', whereIn: ['responded', 'completed'])
            .get();

        List<Map<String, dynamic>> questionSets = [];
        for (var doc in snapshot.docs) {
          Map<String, dynamic> questionSet = doc.data() as Map<String, dynamic>;
          questionSet['id'] = doc.id;
          questionSets.add(questionSet);
        }

        // Sort client-side
        questionSets.sort((a, b) {
          Timestamp aTime = a['respondedAt'] as Timestamp? ?? a['completedAt'] as Timestamp? ?? Timestamp.now();
          Timestamp bTime = b['respondedAt'] as Timestamp? ?? b['completedAt'] as Timestamp? ?? Timestamp.now();
          return bTime.compareTo(aTime);
        });

        setState(() {
          _questionSets = questionSets;
          _applyFilters();
        });
      } catch (fallbackError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading question sets: $fallbackError')),
        );
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_questionSets);
    
    // Apply date filters
    if (_startDate != null || _endDate != null) {
      filtered = filtered.where((questionSet) {
        Timestamp? timestamp = questionSet['respondedAt'] as Timestamp? ?? questionSet['completedAt'] as Timestamp?;
        if (timestamp == null) return false;
        
        DateTime responseDate = timestamp.toDate();
        bool matchesStart = _startDate == null || responseDate.isAfter(_startDate!.subtract(const Duration(days: 1)));
        bool matchesEnd = _endDate == null || responseDate.isBefore(_endDate!.add(const Duration(days: 1)));
        
        return matchesStart && matchesEnd;
      }).toList();
    }
    
    setState(() {
      _filteredQuestionSets = filtered;
    });
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
      _applyFilters();
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
      _applyFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Responses'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Child Selection and Date Filters
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      // Child Selection - Always show
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
                          _loadQuestionSets();
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Date Filters
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectStartDate,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _startDate != null 
                                            ? 'From: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                            : 'From Date',
                                        style: TextStyle(
                                          color: _startDate != null ? Colors.black : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: _selectEndDate,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _endDate != null 
                                            ? 'To: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                            : 'To Date',
                                        style: TextStyle(
                                          color: _endDate != null ? Colors.black : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      
                      // Filter Summary
                      if (_startDate != null || _endDate != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.filter_list, size: 16, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Showing ${_filteredQuestionSets.length} of ${_questionSets.length} responses',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Responses List
                Expanded(
                  child: _filteredQuestionSets.isEmpty
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
                                'No parent responses found',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters or check back later',
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
                          itemCount: _filteredQuestionSets.length,
                          itemBuilder: (context, index) {
                            final questionSet = _filteredQuestionSets[index];
                            return _buildResponseCard(questionSet);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildResponseCard(Map<String, dynamic> questionSet) {
    final respondedAt = questionSet['respondedAt'] as Timestamp? ?? questionSet['completedAt'] as Timestamp?;
    final date = respondedAt?.toDate() ?? DateTime.now();
    final isHierarchical = questionSet['type'] == 'hierarchical';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: InkWell(
        onTap: () => _showDetailedResponse(questionSet),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green, width: 2),
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
                            isHierarchical ? 'Hierarchical Questions Answered' : 'Parent Response Available',
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
                        color: isHierarchical ? Colors.blue : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isHierarchical ? 'HIERARCHICAL' : 'ANSWERED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Summary of Q&A
                Text(
                  isHierarchical 
                      ? '${_getMainQuestionCount(questionSet)} main questions, ${_getSubQuestionCount(questionSet)} subquestions'
                      : '${questionSet['questions'].length} questions answered',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Preview of first question and answer
                if (questionSet['responses'].isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q: ${questionSet['responses'][0]['questionText'] ?? questionSet['responses'][0]['question'] ?? 'Question'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'A: ${questionSet['responses'][0]['answer']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Responded: ${date.day}/${date.month}/${date.year}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Tap to view full response',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  void _showDetailedResponse(Map<String, dynamic> questionSet) {
    final isHierarchical = questionSet['type'] == 'hierarchical';
    
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
                        isHierarchical ? 'Hierarchical Questions Report' : 'Parent Response Report',
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
                
                // Report Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isHierarchical ? Colors.blue[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isHierarchical ? Colors.blue[200]! : Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Child Name', questionSet['childName']),
                      if (isHierarchical) ...[
                        _buildDetailRow('Main Questions', '${_getMainQuestionCount(questionSet)}'),
                        _buildDetailRow('Subquestions', '${_getSubQuestionCount(questionSet)}'),
                      ] else ...[
                        _buildDetailRow('Questions Sent', '${questionSet['questions'].length}'),
                      ],
                      _buildDetailRow('Questions Answered', '${questionSet['responses'].length}'),
                      _buildDetailRow('Response Date', _formatDate(questionSet['respondedAt'] ?? questionSet['completedAt'])),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Q&A Details
                Text(
                  isHierarchical ? 'Questions & Answers (Hierarchical)' : 'Questions & Answers',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366),
                  ),
                ),
                const SizedBox(height: 12),
                
                Expanded(
                  child: isHierarchical 
                      ? _buildHierarchicalQAView(questionSet)
                      : ListView.builder(
                          itemCount: questionSet['responses'].length,
                          itemBuilder: (context, index) {
                            final response = questionSet['responses'][index];
                            return _buildQuestionAnswerCard(index + 1, response);
                          },
                        ),
                ),
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _generatePDF(questionSet),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Generate PDF'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF003366)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Close'),
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

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionAnswerCard(int questionNumber, Map<String, dynamic> response) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question $questionNumber',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  response['question'],
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Parent Answer:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  response['answer'],
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Answered: ${_formatDate(response['answeredAt'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Unknown date';
      }
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> _generateReport(Map<String, dynamic> questionSet) async {
    try {
      // Create a formal report from the Q&A
      final report = {
        'reportId': FirebaseFirestore.instance.collection('reports').doc().id,
        'childId': questionSet['childId'],
        'childName': questionSet['childName'],
        'therapistId': _authService.currentUser!.uid,
        'therapistName': 'Current Therapist', // Get from auth service if needed
        'assessmentDate': _formatDate(questionSet['respondedAt']),
        'createdAt': Timestamp.now(),
        'status': 'parent_qa_report',
        'summary': _generateQASummary(questionSet),
        'detailedAssessment': {
          'type': 'parent_qa',
          'questions': questionSet['questions'],
          'responses': questionSet['responses'],
        },
        'recommendations': _generateRecommendations(questionSet),
        'nextSessionFocus': _generateNextSessionFocus(questionSet),
        'parentViewed': false,
      };

      // Save to Firestore
      await FirebaseFirestore.instance.collection('reports').add(report);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Close dialog
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateQASummary(Map<String, dynamic> questionSet) {
    final responses = questionSet['responses'] as List;
    final responseCount = responses.length;
    
    // Safely generate insights with proper bounds checking
    final insights = <String>[];
    for (int i = 0; i < responses.length && i < 3; i++) {
      try {
        final response = responses[i];
        if (response is Map<String, dynamic>) {
          final question = response['question']?.toString() ?? 'No question';
          final answer = response['answer']?.toString() ?? 'No answer';
          
          // Safe substring with bounds checking
          String answerPreview = answer;
          if (answer.length > 50) {
            answerPreview = '${answer.substring(0, 50)}...';
          }
          
          insights.add('• $question: $answerPreview');
        }
      } catch (e) {
        // Skip problematic responses
        continue;
      }
    }
    
    return '''Parent Q&A Summary for ${questionSet['childName']} - ${_formatDate(questionSet['respondedAt'])}

The parent has provided detailed responses to $responseCount questions about their child's progress and behavior at home.

Key insights from parent responses:
${insights.join('\n')}

This Q&A provides valuable insights into the child's home environment and progress outside therapy sessions.''';
  }

  String _generateRecommendations(Map<String, dynamic> questionSet) {
    return '''Based on parent responses:

1. Continue monitoring progress at home
2. Maintain open communication with parents
3. Adjust therapy strategies based on home observations
4. Provide specific activities for home practice
5. Schedule regular check-ins with parents''';
  }

  String _generateNextSessionFocus(Map<String, dynamic> questionSet) {
    return '''Next Session Priorities:

1. Review parent observations and concerns
2. Address any issues mentioned in responses
3. Align therapy goals with home progress
4. Provide updated strategies for home support
5. Discuss any behavioral changes noted by parents''';
  }

  Future<void> _generatePDF(Map<String, dynamic> questionSet) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Create a proper report structure for PDF generation
      final isHierarchical = questionSet['type'] == 'hierarchical';
      final report = {
        'childId': questionSet['childId'],
        'childName': questionSet['childName'],
        'therapistId': _authService.currentUser!.uid,
        'therapistName': 'Current Therapist',
        'createdAt': questionSet['respondedAt'] ?? questionSet['completedAt'],
        'status': 'parent_qa_report',
        'type': questionSet['type'], // Add type information
        'summary': _generateQASummary(questionSet),
        'detailedAssessment': {
          'type': isHierarchical ? 'hierarchical_parent_qa' : 'parent_qa',
          'questionSet': questionSet, // Pass the entire question set for hierarchical processing
          'questions': questionSet['questions'] ?? [],
          'responses': questionSet['responses'] ?? [],
        },
      };
      
      await PDFService.generateAndShareReport(report);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('PDF Generation Error: $e');
      print('Stack trace: ${StackTrace.current}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Build hierarchical Q&A view
  Widget _buildHierarchicalQAView(Map<String, dynamic> questionSet) {
    final responses = questionSet['responses'] as List?;
    if (responses == null || responses.isEmpty) {
      return const Center(child: Text('No responses available'));
    }

    // Group responses by main question
    final Map<String, List<Map<String, dynamic>>> groupedResponses = {};
    final Map<String, Map<String, dynamic>> mainQuestions = {};
    
    // First, get all main questions
    final questions = questionSet['questions'] as List?;
    if (questions != null) {
      for (final question in questions) {
        mainQuestions[question['id']] = question;
        groupedResponses[question['id']] = [];
      }
    }
    
    // Then, group responses by their parent question
    for (final response in responses) {
      final questionId = response['questionId'] as String?;
      final isMainQuestion = response['isMainQuestion'] as bool? ?? false;
      
      if (isMainQuestion) {
        // This is a main question response
        if (questionId != null && groupedResponses.containsKey(questionId)) {
          groupedResponses[questionId]!.insert(0, response); // Insert main question first
        }
      } else {
        // This is a subquestion response, find its parent
        final parentQuestionId = response['parentQuestionId'] as String?;
        if (parentQuestionId != null && groupedResponses.containsKey(parentQuestionId)) {
          groupedResponses[parentQuestionId]!.add(response);
        }
      }
    }

    return ListView.builder(
      itemCount: mainQuestions.length,
      itemBuilder: (context, index) {
        final mainQuestionId = mainQuestions.keys.elementAt(index);
        final mainQuestion = mainQuestions[mainQuestionId]!;
        final responses = groupedResponses[mainQuestionId] ?? [];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Question
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
                const SizedBox(height: 8),
                Text(
                  mainQuestion['text'] ?? 'Question not available',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366),
                  ),
                ),
                
                // Main Question Answer
                if (responses.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Parent Answer:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          responses[0]['answer'] ?? 'No answer',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                
                // Subquestions (if any)
                if (responses.length > 1) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Follow-up Questions:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...responses.skip(1).map((response) => Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          response['questionText'] ?? 'Subquestion not available',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Answer:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          response['answer'] ?? 'No answer',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper methods for hierarchical questions
  int _getMainQuestionCount(Map<String, dynamic> questionSet) {
    if (questionSet['type'] != 'hierarchical') return 0;
    return questionSet['questions']?.length ?? 0;
  }

  int _getSubQuestionCount(Map<String, dynamic> questionSet) {
    if (questionSet['type'] != 'hierarchical') return 0;
    int subCount = 0;
    final questions = questionSet['questions'] as List?;
    if (questions != null) {
      for (final question in questions) {
        final subQuestions = question['subQuestions'] as List?;
        if (subQuestions != null) {
          subCount += subQuestions.length;
        }
      }
    }
    return subCount;
  }
}
