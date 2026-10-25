import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';
import 'services/auth_service.dart';
import 'services/pdf_service.dart';
import 'theme/app_theme.dart';

class TherapistReportsPage extends StatefulWidget {
  const TherapistReportsPage({super.key});

  @override
  State<TherapistReportsPage> createState() => _TherapistReportsPageState();
}

class _TherapistReportsPageState extends State<TherapistReportsPage> {
  final ChildService _childService = ChildService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _children = [];
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _filteredReports = [];
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
        _loadReports();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppTheme.error,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    }
  }

  Future<void> _loadReports() async {
    if (_selectedChildId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('childId', isEqualTo: _selectedChildId)
          .where('status', isEqualTo: 'therapist_assessment')
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

      if (mounted) {
        setState(() {
          _reports = reports;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: $e'),
            backgroundColor: AppTheme.error,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_reports);
    
    if (_startDate != null || _endDate != null) {
      filtered = filtered.where((report) {
        Timestamp? timestamp = report['createdAt'] as Timestamp?;
        if (timestamp == null) return false;
        
        DateTime reportDate = timestamp.toDate();
        bool matchesStart = _startDate == null || reportDate.isAfter(_startDate!.subtract(const Duration(days: 1)));
        bool matchesEnd = _endDate == null || reportDate.isBefore(_endDate!.add(const Duration(days: 1)));
        
        return matchesStart && matchesEnd;
      }).toList();
    }
    
    setState(() {
      _filteredReports = filtered;
    });
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.secondary,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.secondary,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
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
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Invalid date';
    }
  }

  Future<void> _generatePDF(Map<String, dynamic> report) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating clinical PDF report...'),
          duration: Duration(seconds: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
      
      await PDFService.generateAndShareReport(report);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generated successfully!'),
            backgroundColor: AppTheme.secondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppTheme.error,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clinical Reports Archive',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Assessment Records & PDF Export',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.secondary))
          : Column(
              children: [
                // Filter Control Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(bottom: BorderSide(color: AppTheme.border)),
                  ),
                  child: Column(
                    children: [
                      // Patient Dropdown Selector
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryLight,
                              border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.face_rounded, color: AppTheme.secondary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedChildId,
                              decoration: const InputDecoration(
                                labelText: 'SELECT PATIENT',
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: AppTheme.secondary,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.secondary, width: 1.5)),
                                filled: true,
                                fillColor: AppTheme.background,
                              ),
                              items: _children.map((child) {
                                return DropdownMenuItem<String>(
                                  value: child['id'] as String?,
                                  child: Text(
                                    child['name'] ?? 'Unnamed Patient',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Date Filter Bar
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectStartDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  border: Border.all(color: _startDate != null ? AppTheme.secondary : AppTheme.border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 14,
                                      color: _startDate != null ? AppTheme.secondary : AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _startDate != null 
                                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                            : 'From Date',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: _startDate != null ? FontWeight.bold : FontWeight.normal,
                                          color: _startDate != null ? AppTheme.textPrimary : AppTheme.textSecondary,
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  border: Border.all(color: _endDate != null ? AppTheme.secondary : AppTheme.border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 14,
                                      color: _endDate != null ? AppTheme.secondary : AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _endDate != null 
                                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                            : 'To Date',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: _endDate != null ? FontWeight.bold : FontWeight.normal,
                                          color: _endDate != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_startDate != null || _endDate != null) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _clearFilters,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textSecondary),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      // Filter count strip
                      if (_startDate != null || _endDate != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryLight,
                            border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Showing ${_filteredReports.length} of ${_reports.length} assessment records matching date filter',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Reports List
                Expanded(
                  child: _filteredReports.isEmpty
                      ? Center(
                          child: Container(
                            margin: const EdgeInsets.all(24),
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              border: Border.all(color: AppTheme.border),
                              boxShadow: AppTheme.softShadow,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.assignment_outlined,
                                  size: 48,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'No Assessment Reports Found',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Published clinical evaluations and domain assessments for this patient will appear here.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredReports.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final report = _filteredReports[index];
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
    
    return InkWell(
      onTap: () => _showReportDetails(report),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.softShadow,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: AppTheme.secondary,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Clinical Assessment Report',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Patient: ${report['childName'] ?? 'Unknown'}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryLight,
                              border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                            ),
                            child: const Text(
                              'ASSESSMENT',
                              style: TextStyle(
                                color: AppTheme.secondary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      // Report Summary Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SUMMARY',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.8,
                                color: AppTheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              report['summary'] ?? 'No summary available for this assessment.',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.4),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Recorded: ${date.day}/${date.month}/${date.year}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Review Details',
                            style: TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.secondary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.border),
          ),
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryLight,
                      border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.assignment_rounded, color: AppTheme.secondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Therapist Assessment Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Comprehensive Clinical Evaluation',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppTheme.border),
              const SizedBox(height: 12),
              
              // Key info strip
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Patient', report['childName']),
                    _buildDetailRow('Therapist', report['therapistName']),
                    _buildDetailRow('Date', _formatDate(report['createdAt'])),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Scrollable Details Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection('Executive Summary', report['summary']),
                      _buildSection('Clinical Recommendations', report['recommendations']),
                      _buildSection('Next Session Focus', report['nextSessionFocus']),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _generatePDF(report),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppTheme.secondary),
                      label: const Text(
                        'Export PDF',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.secondary),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Dismiss',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String? content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 12, color: AppTheme.secondary),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content ?? 'No information recorded for this section.',
            style: const TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}
