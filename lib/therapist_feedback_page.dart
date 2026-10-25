import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

class TherapistFeedbackPage extends StatefulWidget {
  const TherapistFeedbackPage({super.key});

  @override
  State<TherapistFeedbackPage> createState() => _TherapistFeedbackPageState();
}

class _TherapistFeedbackPageState extends State<TherapistFeedbackPage>
    with SingleTickerProviderStateMixin {
  final ChildService _childService = ChildService();
  final AuthService _authService = AuthService();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  
  List<Map<String, dynamic>> _children = [];
  Map<String, dynamic>? _selectedChild;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _receivedFeedback = [];
  List<Map<String, dynamic>> _sentFeedback = [];
  bool _isLoading = true;
  bool _isSending = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _feedbackController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final children = await _childService.getChildren();
      final userData = await _authService.getUserData(_authService.currentUser!.uid);
      setState(() {
        _children = children;
        _userData = userData;
        if (children.isNotEmpty) {
          _selectedChild = children.first;
        }
        _isLoading = false;
      });
      
      if (_selectedChild != null) {
        _loadFeedback();
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

  Future<void> _loadFeedback() async {
    if (_selectedChild == null) return;
    
    try {
      QuerySnapshot feedbackSnapshot = await FirebaseFirestore.instance
          .collection('feedback')
          .where('childId', isEqualTo: _selectedChild!['id'])
          .limit(40)
          .get();

      List<Map<String, dynamic>> received = [];
      List<Map<String, dynamic>> sent = [];
      
      for (var doc in feedbackSnapshot.docs) {
        Map<String, dynamic> feedbackData = doc.data() as Map<String, dynamic>;
        feedbackData['id'] = doc.id;
        
        if (feedbackData['type'] == 'parent_feedback') {
          received.add(feedbackData);
        } else if (feedbackData['type'] == 'therapist_feedback') {
          sent.add(feedbackData);
        }
      }

      received.sort((a, b) {
        Timestamp aTime = a['createdAt'] as Timestamp;
        Timestamp bTime = b['createdAt'] as Timestamp;
        return bTime.compareTo(aTime);
      });
      
      sent.sort((a, b) {
        Timestamp aTime = a['createdAt'] as Timestamp;
        Timestamp bTime = b['createdAt'] as Timestamp;
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _receivedFeedback = received;
          _sentFeedback = sent;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading feedback: $e'),
            backgroundColor: AppTheme.error,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    }
  }

  Future<void> _sendFeedback() async {
    if (_selectedChild == null || _titleController.text.trim().isEmpty || _feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both subject and note content'),
          backgroundColor: AppTheme.warning,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      String currentUserId = _authService.currentUser!.uid;
      
      Map<String, dynamic> feedback = {
        'childId': _selectedChild!['id'],
        'childName': _selectedChild!['name'],
        'parentId': '',
        'parentName': '',
        'therapistId': currentUserId,
        'therapistName': _userData?['username'] ?? 'Therapist',
        'title': _titleController.text.trim(),
        'message': _feedbackController.text.trim(),
        'type': 'therapist_feedback',
        'createdAt': Timestamp.now(),
        'status': 'sent',
        'isRead': false,
      };

      await FirebaseFirestore.instance.collection('feedback').add(feedback);

      _titleController.clear();
      _feedbackController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clinical note sent to parent successfully!'),
            backgroundColor: AppTheme.secondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }

      _loadFeedback();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending note: $e'),
            backgroundColor: AppTheme.error,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'N/A';
      }
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'N/A';
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
              'Session Feedback & Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Therapist Clinical Communication',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.secondary,
                indicatorWeight: 2.5,
                labelColor: AppTheme.secondary,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(
                    iconMargin: EdgeInsets.only(bottom: 2),
                    icon: Icon(Icons.rate_review_outlined, size: 18),
                    text: 'Send Feedback',
                  ),
                  Tab(
                    iconMargin: EdgeInsets.only(bottom: 2),
                    icon: Icon(Icons.inbox_outlined, size: 18),
                    text: 'Parent Messages',
                  ),
                ],
              ),
              const Divider(height: 1, color: AppTheme.border),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.secondary))
          : Column(
              children: [
                // Patient Selector Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(bottom: BorderSide(color: AppTheme.border)),
                  ),
                  child: Row(
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
                        child: DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedChild,
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
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: child,
                              child: Text(
                                child['name'] ?? 'Unnamed Patient',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (child) {
                            setState(() {
                              _selectedChild = child;
                            });
                            _loadFeedback();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSendFeedbackTab(),
                      _buildReceivedFeedbackTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSendFeedbackTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSendFeedbackSection(),
          const SizedBox(height: 20),
          _buildSentHistorySection(),
        ],
      ),
    );
  }

  Widget _buildReceivedFeedbackTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildFeedbackList(_receivedFeedback, 'Notes from Parents', isReceived: true),
    );
  }

  Widget _buildSendFeedbackSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'COMPOSE CLINICAL NOTE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Document session milestones, home strategies, or therapeutic recommendations for the parent.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Subject / Focus Area',
              labelStyle: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              hintText: 'e.g., Speech Modulation Progress & Home Exercises',
              hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.secondary, width: 1.5)),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: AppTheme.background,
            ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Clinical Observations & Recommendations',
              labelStyle: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              hintText: 'Detailed notes on progress, behaviors observed, and steps for the week...',
              hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.secondary, width: 1.5)),
              contentPadding: EdgeInsets.all(14),
              filled: true,
              fillColor: AppTheme.background,
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              icon: _isSending
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                _isSending ? 'Sending Note...' : 'Dispatch Clinical Note',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentHistorySection() {
    return _buildFeedbackList(_sentFeedback, 'Dispatched Clinical Notes', isReceived: false);
  }

  Widget _buildFeedbackList(List<Map<String, dynamic>> feedbackList, String title, {required bool isReceived}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    color: isReceived ? AppTheme.primary : AppTheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isReceived ? AppTheme.primary : AppTheme.secondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  '${feedbackList.length} Total',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (feedbackList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Icon(
                    isReceived ? Icons.mark_email_unread_outlined : Icons.outbox_rounded,
                    size: 38,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isReceived ? 'No notes received yet' : 'No clinical notes dispatched yet',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isReceived
                        ? 'Parent notes or questions for ${_selectedChild?['name'] ?? 'this patient'} will display here.'
                        : 'Use the form above to send therapy notes and recommendations.',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: feedbackList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _buildFeedbackCard(feedbackList[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    bool isFromParent = feedback['type'] == 'parent_feedback';
    Color accentColor = isFromParent ? AppTheme.primary : AppTheme.secondary;
    Color lightBg = isFromParent ? AppTheme.primaryLight : AppTheme.secondaryLight;
    
    String sender = isFromParent 
        ? 'Parent: ${feedback['parentName'] ?? 'Parent'}'
        : 'Therapist: ${feedback['therapistName'] ?? 'You'}';
    
    return InkWell(
      onTap: () => _showFeedbackDetails(feedback),
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
                color: accentColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              feedback['title'] ?? 'No Subject',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: lightBg,
                              border: Border.all(color: accentColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              isFromParent ? 'PARENT' : 'CLINICAL',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        feedback['message'] ?? 'No message content',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              sender,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time_rounded, size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(feedback['createdAt']),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.textMuted),
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

  void _showFeedbackDetails(Map<String, dynamic> feedback) {
    bool isFromParent = feedback['type'] == 'parent_feedback';
    Color accentColor = isFromParent ? AppTheme.primary : AppTheme.secondary;
    Color lightBg = isFromParent ? AppTheme.primaryLight : AppTheme.secondaryLight;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.border),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        color: lightBg,
                        border: Border.all(color: accentColor.withOpacity(0.3)),
                      ),
                      child: Icon(
                        isFromParent ? Icons.person_rounded : Icons.medical_services_rounded,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feedback['title'] ?? 'No Subject',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isFromParent 
                                ? 'From: Parent (${feedback['parentName'] ?? 'Parent'})'
                                : 'From: You (${feedback['therapistName'] ?? 'Therapist'})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 12),
                
                // Patient Tag & Timestamp row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.face_rounded, size: 14, color: AppTheme.secondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Patient: ${feedback['childName'] ?? 'Unknown'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(feedback['createdAt']),
                            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Message Content
                const Text(
                  'NOTE CONTENT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    feedback['message'] ?? 'No message content available.',
                    style: const TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textPrimary),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Close button
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.border),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
