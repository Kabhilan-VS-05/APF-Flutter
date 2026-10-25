import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

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
          .where('status', whereIn: ['parent_qa_report'])
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> reports = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> report = doc.data() as Map<String, dynamic>;
        report['id'] = doc.id;
        reports.add(report);
      }

      reports.sort((a, b) {
        Timestamp aTime = a['createdAt'] as Timestamp;
        Timestamp bTime = b['createdAt'] as Timestamp;
        return bTime.compareTo(aTime);
      });

      setState(() {
        _reports = reports;
      });
    } catch (e) {
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('reports')
            .where('childId', isEqualTo: _selectedChildId)
            .where('status', whereIn: ['parent_qa_report'])
            .get();

        List<Map<String, dynamic>> reports = [];
        for (var doc in snapshot.docs) {
          Map<String, dynamic> report = doc.data() as Map<String, dynamic>;
          report['id'] = doc.id;
          reports.add(report);
        }

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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Clinical Reports & Summaries',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                // Child Selection Header
                if (_children.length > 1)
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
                            color: AppTheme.primaryLight,
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.child_care_rounded, color: AppTheme.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<String>(
                              value: _selectedChildId,
                              decoration: InputDecoration(
                                labelText: 'Active Child Profile',
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
                                  borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
                                ),
                              ),
                              items: _children.map((child) {
                                return DropdownMenuItem<String>(
                                  value: child['id'],
                                  child: Text(
                                    child['name'] ?? 'Unnamed Child',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
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
                        ),
                      ],
                    ),
                  ),

                // Reports List
                Expanded(
                  child: _reports.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.zero,
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryLight,
                                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                                    ),
                                    child: const Icon(
                                      Icons.description_outlined,
                                      size: 36,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'No Assessment Reports Yet',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Assessment summaries and printable clinical reports will appear here once finalized by your clinical team.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: isNew ? AppTheme.primary : AppTheme.border,
          width: isNew ? 1.5 : 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRoseLight,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: AppTheme.accentRose.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.accentRose, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clinical Assessment Report',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Evaluator: ${report['therapistName'] ?? 'Assigned Clinical Staff'}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                report['summary'] ?? 'Clinical evaluation finalized. Tap to review complete findings and recommended steps.',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'View Findings',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDetails(Map<String, dynamic> report) {
    if (!(report['parentViewed'] ?? false)) {
      FirebaseFirestore.instance
          .collection('reports')
          .doc(report['id'])
          .update({'parentViewed': true});
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        backgroundColor: AppTheme.surface,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.primary, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.description_outlined, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Assessment Report',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: AppTheme.textMuted,
                    ),
                  ],
                ),
                const Divider(color: AppTheme.border, height: 24),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Child Profile', report['childName']),
                        _buildDetailRow('Clinical Staff', report['therapistName']),
                        _buildDetailRow('Assessment Date', report['assessmentDate']),
                        
                        const SizedBox(height: 18),
                        const Text(
                          'Executive Summary',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceSubtle,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            report['summary'] ?? 'No summary available',
                            style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textPrimary),
                          ),
                        ),
                        
                        const SizedBox(height: 18),
                        const Text(
                          'Clinical Recommendations',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.zero,
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            report['recommendations'] ?? 'No recommendations available',
                            style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textPrimary),
                          ),
                        ),
                        
                        if (report['nextSessionFocus'] != null && report['nextSessionFocus'].toString().isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const Text(
                            'Next Session Focus',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.accentAmberLight.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.zero,
                              border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              report['nextSessionFocus'],
                              style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textPrimary),
                            ),
                          ),
                        ],
                        
                        // Detailed Assessment Results
                        if (report['detailedAssessment'] != null) ...[
                          const SizedBox(height: 22),
                          const Text(
                            'Itemized Findings',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
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
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: const Text('Close Report', style: TextStyle(fontWeight: FontWeight.w700)),
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
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
            ),
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
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    questionLabels[questionId] ?? questionId,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    answer.toString(),
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
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
