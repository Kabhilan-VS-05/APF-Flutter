import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/child_service.dart';

class TherapistChildrenPage extends StatefulWidget {
  final List<Map<String, dynamic>> children;

  const TherapistChildrenPage({
    super.key,
    required this.children,
  });

  @override
  State<TherapistChildrenPage> createState() => _TherapistChildrenPageState();
}

class _TherapistChildrenPageState extends State<TherapistChildrenPage> {
  final ChildService _childService = ChildService();
  Map<String, dynamic>? selectedChild;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredChildren = [];

  @override
  void initState() {
    super.initState();
    _filteredChildren = widget.children;
    if (widget.children.isNotEmpty) {
      selectedChild = widget.children.first;
    }
  }

  void _filterChildren(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredChildren = widget.children;
      } else {
        _filteredChildren = widget.children.where((child) {
          final name = (child['name'] ?? '').toLowerCase();
          final id = (child['id'] ?? '').toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || id.contains(searchLower);
        }).toList();
      }
    });
    
    // Auto-select first child if current selection is filtered out
    if (_filteredChildren.isNotEmpty && 
        (!_filteredChildren.any((child) => child['id'] == selectedChild?['id']))) {
      setState(() {
        selectedChild = _filteredChildren.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Children'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: widget.children.isEmpty
          ? const Center(
              child: Text(
                'No children assigned to you yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[50],
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search children by name or ID...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterChildren('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: _filterChildren,
                  ),
                ),
                
                // Child List Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      const Text(
                        'Select a Child:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_filteredChildren.length != widget.children.length)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_filteredChildren.length} found',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Child List
                Container(
                  height: 120,
                  child: _filteredChildren.isEmpty
                      ? const Center(
                          child: Text(
                            'No children found matching your search.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filteredChildren.length,
                          itemBuilder: (context, index) {
                            final child = _filteredChildren[index];
                            final isSelected = selectedChild?['id'] == child['id'];
                            
                            return Container(
                              width: 150,
                              margin: const EdgeInsets.all(8),
                              child: Card(
                                color: isSelected ? Colors.blue[100] : Colors.white,
                                elevation: isSelected ? 4 : 2,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedChild = child;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: const Color(0xFF003366),
                                          child: Text(
                                            (child['name'] ?? '')[0].toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Flexible(
                                          child: Text(
                                            child['name'] ?? 'Unknown',
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Age: ${child['age'] ?? 'N/A'}',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                // Divider
                const Divider(height: 1, thickness: 1),
                
                // Child Details
                Expanded(
                  child: selectedChild == null
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
                                'Select a child to view details',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildChildDetails(),
                ),
              ],
            ),
    );
  }

  Widget _buildChildDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Child Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Child Information',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Name', selectedChild!['name']),
                  _buildDetailRow('Age', selectedChild!['age']),
                  _buildDetailRow('Gender', selectedChild!['gender']),
                  _buildDetailRow('Diagnosis', selectedChild!['diagnosis']),
                  
                  if (selectedChild!['additionalInfo'] != null && selectedChild!['additionalInfo'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Additional Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    _buildAdditionalInfo(selectedChild!['additionalInfo']),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    try {
      DateTime date;
      if (dateValue is Timestamp) {
        date = dateValue.toDate();
      } else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else {
        return 'Unknown date';
      }
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
