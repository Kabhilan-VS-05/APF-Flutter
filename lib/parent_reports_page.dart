import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';
import 'services/auth_service.dart';

class ParentReportsPage extends StatefulWidget {
  const ParentReportsPage({super.key});

  @override
  State<ParentReportsPage> createState() => _ParentReportsPageState();
}

class _ParentReportsPageState extends State<ParentReportsPage> {
  final ChildService _childService = ChildService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _children = [];
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
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
        _loadReports();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _loadReports() async {
    if (_selectedChildId == null) return;
    
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('childId', isEqualTo: _selectedChildId)
          .where('status', whereIn: ['parent_qa_report']) // Only show parent Q&A reports
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> reports = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> report = doc.data() as Map<String, dynamic>;
        report['id'] = doc.id;
        reports.add(report);
      }

      // Sort client-side as fallback
      reports.sort((a, b) {
        Timestamp aTime = a['createdAt'] as Timestamp;
        Timestamp bTime = b['createdAt'] as Timestamp;
        return bTime.compareTo(aTime); // Descending order
      });

      setState(() {
        _reports = reports;
      });
    } catch (e) {
      // Fallback to query without ordering if index not ready
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('reports')
            .where('childId', isEqualTo: _selectedChildId)
            .where('status', whereIn: ['parent_qa_report']) // Only show parent Q&A reports
            .get();

        List<Map<String, dynamic>> reports = [];
        for (var doc in snapshot.docs) {
          Map<String, dynamic> report = doc.data() as Map<String, dynamic>;
          report['id'] = doc.id;
          reports.add(report);
        }

        // Sort client-side
        reports.sort((a, b) {
          Timestamp aTime = a['createdAt'] as Timestamp;
          Timestamp bTime = b['createdAt'] as Timestamp;
          return bTime.compareTo(aTime);
        });

        setState(() {
          _reports = reports;
        });
      } catch (fallbackError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $fallbackError')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Reports'),
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
                        _loadReports();
                      },
                    ),
                  ),

                // Reports List
                Expanded(
                  child: _reports.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assessment,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No reports available yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Reports will appear here when therapists complete assessments',
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
                          itemCount: _reports.length,
                          itemBuilder: (context, index) {
                            final report = _reports[index];
                            return _buildReportCard(report);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final createdAt = report['createdAt'] as Timestamp?;
    final date = createdAt?.toDate() ?? DateTime.now();
    final isNew = !(report['parentViewed'] ?? false);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isNew ? 4 : 2,
      child: InkWell(
        onTap: () => _showReportDetails(report),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isNew 
                ? Border.all(color: Colors.blue, width: 2)
                : null,
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
                            'Assessment Report',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003366),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'By: ${report['therapistName'] ?? 'Unknown Therapist'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NEW',
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
                Text(
                  report['summary'] ?? 'No summary available',
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
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
                      '${date.day}/${date.month}/${date.year}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Tap to view details',
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

  void _showReportDetails(Map<String, dynamic> report) {
    // Mark as viewed
    if (!(report['parentViewed'] ?? false)) {
      FirebaseFirestore.instance
          .collection('reports')
          .doc(report['id'])
          .update({'parentViewed': true});
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
                        'Assessment Report',
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
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Child Name', report['childName']),
                        _buildDetailRow('Therapist', report['therapistName']),
                        _buildDetailRow('Assessment Date', report['assessmentDate']),
                        
                        const SizedBox(height: 16),
                        const Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            report['summary'] ?? 'No summary available',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        const Text(
                          'Recommendations',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            report['recommendations'] ?? 'No recommendations available',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        
                        if (report['nextSessionFocus'] != null && report['nextSessionFocus'].toString().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Next Session Focus',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003366),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Text(
                              report['nextSessionFocus'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                        
                        // Detailed Assessment Results
                        if (report['detailedAssessment'] != null) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Detailed Assessment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003366),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._buildDetailedAssessment(report['detailedAssessment']),
                        ],
                      ],
                    ),
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

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  List<Widget> _buildDetailedAssessment(Map<String, dynamic> assessment) {
    List<Widget> widgets = [];
    
    final questionOrder = [
      'overall_improvement',
      'communication_skills',
      'social_interaction',
      'behavior_pattern',
      'attention_span',
      'strengths',
      'areas_for_improvement',
      'activities_completed',
    ];
    
    final questionLabels = {
      'overall_improvement': 'Overall Improvement',
      'communication_skills': 'Communication Skills',
      'social_interaction': 'Social Interaction',
      'behavior_pattern': 'Behavior Pattern',
      'attention_span': 'Attention Span',
      'strengths': 'Strengths',
      'areas_for_improvement': 'Areas for Improvement',
      'activities_completed': 'Activities Completed',
    };
    
    for (String questionId in questionOrder) {
      if (assessment.containsKey(questionId)) {
        final answer = assessment[questionId];
        if (answer != null && answer.toString().isNotEmpty) {
          widgets.add(
            Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                    questionLabels[questionId] ?? questionId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    answer.toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }
    
    return widgets;
  }
}
