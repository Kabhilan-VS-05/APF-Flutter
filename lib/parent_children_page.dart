import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';

class ParentChildrenPage extends StatefulWidget {
  final List<Map<String, dynamic>> children;

  const ParentChildrenPage({super.key, required this.children});

  @override
  State<ParentChildrenPage> createState() => _ParentChildrenPageState();
}

class _ParentChildrenPageState extends State<ParentChildrenPage> {
  final ChildService _childService = ChildService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLoading = false;
  }

  void _viewChildDetails(Map<String, dynamic> child) {
    showDialog(
      context: context,
      builder: (context) => ChildDetailsDialog(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.children.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.child_care,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No children registered yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Register your first child to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.children.length,
                  itemBuilder: (context, index) {
                    final child = widget.children[index];
                    return ChildCard(
                      child: child,
                      onView: () => _viewChildDetails(child),
                    );
                  },
                ),
    );
  }
}

class ChildCard extends StatelessWidget {
  final Map<String, dynamic> child;
  final VoidCallback onView;

  const ChildCard({
    super.key,
    required this.child,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF003366),
                  radius: 30,
                  child: Text(
                    (child['name'] ?? '')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child['name'] ?? 'Unknown Child',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Age: ${child['age'] ?? 'N/A'}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.wc, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            child['gender'] ?? 'N/A',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('View Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChildDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> child;

  const ChildDetailsDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Child Details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow('Name', child['name']),
            _buildDetailRow('Age', child['age']),
            _buildDetailRow('Gender', child['gender']),
            _buildDetailRow('Diagnosis', child['diagnosis']),
            
            if (child['additionalInfo'] != null && child['additionalInfo'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Additional Information:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildAdditionalInfo(child['additionalInfo']),
            ],
            
            const SizedBox(height: 20),
            
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
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  Widget _buildAdditionalInfo(String additionalInfo) {
    // Parse the additional info string and format without commas
    Map<String, String> infoMap = {};
    
    final parts = additionalInfo.split(',');
    for (String part in parts) {
      if (part.contains('Parent Name:')) {
        infoMap['Parent Name'] = part.split(':').last.trim();
      } else if (part.contains('Contact:')) {
        infoMap['Contact'] = part.split(':').last.trim();
      } else if (part.contains('Parent Work:')) {
        infoMap['Parent Work'] = part.split(':').last.trim();
      } else if (part.contains('Therapist:')) {
        infoMap['Therapist'] = part.split(':').last.trim();
      }
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (infoMap['Parent Name'] != null) _buildInfoRow('Parent Name', infoMap['Parent Name']!),
          if (infoMap['Contact'] != null) _buildInfoRow('Contact', infoMap['Contact']!),
          if (infoMap['Parent Work'] != null) _buildInfoRow('Parent Work', infoMap['Parent Work']!),
          if (infoMap['Therapist'] != null) _buildInfoRow('Therapist', infoMap['Therapist']!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366)),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
