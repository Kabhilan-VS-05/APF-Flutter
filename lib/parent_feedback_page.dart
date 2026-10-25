import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

class ParentFeedbackPage extends StatefulWidget {
  const ParentFeedbackPage({super.key});

  @override
  State<ParentFeedbackPage> createState() => _ParentFeedbackPageState();
}

class _ParentFeedbackPageState extends State<ParentFeedbackPage>
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
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
        
        if (feedbackData['type'] == 'therapist_feedback') {
          received.add(feedbackData);
        } else if (feedbackData['type'] == 'parent_feedback') {
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

      setState(() {
        _receivedFeedback = received;
        _sentFeedback = sent;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading feedback: $e')),
      );
    }
  }

  Future<void> _sendFeedback() async {
    if (_selectedChild == null || _titleController.text.trim().isEmpty || _feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: AppTheme.accentAmber,
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
        'parentId': currentUserId,
        'parentName': _userData?['username'] ?? 'Parent',
        'therapistId': '',
        'therapistName': '',
        'title': _titleController.text.trim(),
        'message': _feedbackController.text.trim(),
        'type': 'parent_feedback',
        'createdAt': Timestamp.now(),
        'status': 'sent',
        'isRead': false,
      };

      await FirebaseFirestore.instance.collection('feedback').add(feedback);

      _titleController.clear();
      _feedbackController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback sent to therapist successfully!'),
          backgroundColor: AppTheme.secondary,
        ),
      );

      _loadFeedback();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending feedback: $e'),
          backgroundColor: AppTheme.accentRose,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Therapist Notes & Feedback',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.mark_email_read_outlined, size: 18),
                    text: 'Received Clinical Notes',
                  ),
                  Tab(
                    icon: Icon(Icons.outgoing_mail, size: 18),
                    text: 'Send Parent Feedback',
                  ),
                ],
              ),
              const Divider(height: 1, color: AppTheme.border),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
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
                          color: AppTheme.primaryLight,
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.child_care_rounded, color: AppTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedChild,
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
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: child,
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
                            onChanged: (child) {
                              setState(() {
                                _selectedChild = child;
                              });
                              _loadFeedback();
                            },
                          ),
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
                      _buildReceivedFeedbackTab(),
                      _buildSendFeedbackTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSendFeedbackTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildSendFeedbackSection(),
    );
  }

  Widget _buildReceivedFeedbackTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildFeedbackList(_receivedFeedback, 'Clinical Notes from Therapist'),
    );
  }

  Widget _buildSendFeedbackSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
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
                child: const Icon(Icons.send_rounded, size: 18, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compose Message for Therapist',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Share questions, observations or behavioral updates',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Subject / Concern',
              labelStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppTheme.border),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
              ),
              hintText: 'e.g., Sensory changes, Routine questions...',
              hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.surfaceSubtle,
            ),
          ),
          const SizedBox(height: 14),
          
          TextField(
            controller: _feedbackController,
            decoration: InputDecoration(
              labelText: 'Detailed Note / Message',
              labelStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppTheme.border),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
              ),
              hintText: 'Describe details regarding your child at home...',
              hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.surfaceSubtle,
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                elevation: 0,
              ),
              child: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Transmit to Therapist', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackList(List<Map<String, dynamic>> feedbackList, String title) {
    if (feedbackList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 36,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Clinical Notes Logged',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The assigned therapist has not recorded specific notes for ${_selectedChild?['name'] ?? 'your child'} yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '${feedbackList.length} notes',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: feedbackList.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> feedback = feedbackList[index];
            return _buildFeedbackCard(feedback);
          },
        ),
      ],
    );
  }

  void _showFeedbackDetails(Map<String, dynamic> feedback) {
    bool isFromTherapist = feedback['type'] == 'therapist_feedback';
    Color accentColor = isFromTherapist ? AppTheme.secondary : AppTheme.primary;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          backgroundColor: AppTheme.surface,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.primary, width: 4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Icon(
                        isFromTherapist ? Icons.verified_user_outlined : Icons.outgoing_mail,
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
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            isFromTherapist 
                                ? 'From: Therapist (${feedback['therapistName'] ?? 'Assigned Clinical Staff'})'
                                : 'From: You (Parent)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: AppTheme.textMuted,
                    ),
                  ],
                ),
                
                const SizedBox(height: 18),
                
                // Child info banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.child_care_rounded, color: AppTheme.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Child Profile: ${feedback['childName'] ?? 'Unknown'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                const Text(
                  'Message Body:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    feedback['message'] ?? 'No message body provided.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 14),
                
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: AppTheme.textMuted, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(feedback['createdAt']),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceSubtle,
                      foregroundColor: AppTheme.textPrimary,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(color: AppTheme.border),
                      ),
                    ),
                    child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    bool isFromTherapist = feedback['type'] == 'therapist_feedback';
    Color accentColor = isFromTherapist ? AppTheme.secondary : AppTheme.primary;
    IconData icon = isFromTherapist ? Icons.reply_rounded : Icons.send_rounded;
    String sender = isFromTherapist 
        ? 'Therapist (${feedback['therapistName'] ?? 'Assigned Staff'})' 
        : 'Parent (You)';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: InkWell(
        onTap: () => _showFeedbackDetails(feedback),
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback['title'] ?? 'No Subject',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feedback['message'] ?? 'No message',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'By $sender',
                            style: TextStyle(
                              fontSize: 11,
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatDate(feedback['createdAt']),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
