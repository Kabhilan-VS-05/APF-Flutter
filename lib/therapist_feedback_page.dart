import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';
import 'services/auth_service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _loadFeedback() async {
    if (_selectedChild == null) return;
    
    try {
      print('Loading feedback for child: ${_selectedChild!['name']} (${_selectedChild!['id']})');
      
      // Use dedicated feedback collection with proper Firestore rules
      String currentUserId = _authService.currentUser!.uid;
      
      // Load feedback from feedback collection (no orderBy to avoid index requirement)
      QuerySnapshot feedbackSnapshot = await FirebaseFirestore.instance
          .collection('feedback')
          .where('childId', isEqualTo: _selectedChild!['id'])
          .limit(40)
          .get();

      print('Total feedback docs: ${feedbackSnapshot.docs.length}');

      List<Map<String, dynamic>> received = [];
      List<Map<String, dynamic>> sent = [];
      
      // Process all feedback and separate by type
      for (var doc in feedbackSnapshot.docs) {
        Map<String, dynamic> feedbackData = doc.data() as Map<String, dynamic>;
        feedbackData['id'] = doc.id;
        
        if (feedbackData['type'] == 'parent_feedback') {
          received.add(feedbackData);
          print('Received feedback: ${feedbackData['title']}');
        } else if (feedbackData['type'] == 'therapist_feedback') {
          sent.add(feedbackData);
          print('Sent feedback: ${feedbackData['title']}');
        }
      }

      // Sort client-side by createdAt (newest first)
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
      
      print('Final received count: ${received.length}');
      print('Final sent count: ${sent.length}');
    } catch (e) {
      print('Error loading feedback: $e');
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
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // Use dedicated feedback collection with proper Firestore rules
      String currentUserId = _authService.currentUser!.uid;
      
      Map<String, dynamic> feedback = {
        'childId': _selectedChild!['id'],
        'childName': _selectedChild!['name'],
        'parentId': '', // Not needed for therapist feedback
        'parentName': '', // Not needed for therapist feedback
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

      // Clear form
      _titleController.clear();
      _feedbackController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback sent to parent successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload feedback list
      _loadFeedback();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.send),
              text: 'Send Feedback',
            ),
            Tab(
              icon: Icon(Icons.inbox),
              text: 'Received Feedback',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Child Selection
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedChild,
                    decoration: const InputDecoration(
                      labelText: 'Select Child',
                      border: OutlineInputBorder(),
                    ),
                    items: _children.map((child) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: child,
                        child: Text(child['name']),
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
      child: _buildSendFeedbackSection(),
    );
  }

  Widget _buildReceivedFeedbackTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildFeedbackList(_receivedFeedback, 'Received Feedback'),
    );
  }

  Widget _buildSendFeedbackSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send Feedback to Parent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
                hintText: 'e.g., Progress Update, Next Steps',
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Feedback Message',
                border: OutlineInputBorder(),
                hintText: 'Share your observations and recommendations...',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  foregroundColor: Colors.white,
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
                    : const Text('Send Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackList(List<Map<String, dynamic>> feedbackList, String title) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            
            if (feedbackList.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.feedback_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title == 'Received Feedback' ? 'No received feedback yet' : 'No sent feedback yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        title == 'Received Feedback' 
                            ? 'Parents haven\'t sent any feedback yet'
                            : 'You haven\'t sent any feedback yet',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
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
        ),
      ),
    );
  }

  void _showFeedbackDetails(Map<String, dynamic> feedback) {
    bool isFromParent = feedback['type'] == 'parent_feedback';
    Color cardColor = isFromParent ? Colors.blue : Colors.green;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: cardColor.withOpacity(0.1),
                      child: Icon(
                        isFromParent ? Icons.send : Icons.reply,
                        color: cardColor,
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isFromParent 
                                ? 'From: Parent (${feedback['parentName'] ?? 'Parent'})'
                                : 'From: You (Therapist)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Child info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.child_care, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Child: ${feedback['childName'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Message
                Text(
                  'Message:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    feedback['message'] ?? 'No message',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Date and time
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey[500], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(feedback['createdAt']),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cardColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Close'),
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
    bool isFromParent = feedback['type'] == 'parent_feedback';
    Color cardColor = isFromParent ? Colors.blue[50]! : Colors.green[50]!;
    Color iconColor = isFromParent ? Colors.blue : Colors.green;
    IconData icon = isFromParent ? Icons.send : Icons.reply;
    String sender = isFromParent 
        ? 'From: Parent (${feedback['parentName'] ?? 'Parent'})'
        : 'From: You (Therapist)';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: ListTile(
        onTap: () {
          _showFeedbackDetails(feedback);
        },
        leading: CircleAvatar(
          backgroundColor: iconColor,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          feedback['title'] ?? 'No Subject',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              feedback['message'] ?? 'No message',
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    sender,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(feedback['createdAt']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
