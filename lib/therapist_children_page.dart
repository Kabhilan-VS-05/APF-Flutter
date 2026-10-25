import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

class TherapistChildrenPage extends StatefulWidget {
  final List<Map<String, dynamic>> children;

  const TherapistChildrenPage({super.key, required this.children});

  @override
  State<TherapistChildrenPage> createState() => _TherapistChildrenPageState();
}

class _TherapistChildrenPageState extends State<TherapistChildrenPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredChildren = [];
  Map<String, dynamic>? selectedChild;

  @override
  void initState() {
    super.initState();
    _filteredChildren = widget.children;
    if (widget.children.isNotEmpty) {
      selectedChild = widget.children.first;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Patient Roster',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: widget.children.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryLight,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(
                        Icons.people_outline_rounded,
                        size: 36,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No Patients Assigned',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Registered patient profiles will appear here for evaluations.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 14.5, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search patients by name or ID...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13.5),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: AppTheme.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                _filterChildren('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.surfaceSubtle,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                      enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.border)),
                      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.secondary, width: 1.5)),
                    ),
                    onChanged: _filterChildren,
                  ),
                ),
                
                // Child List Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppTheme.surfaceSubtle,
                  child: Row(
                    children: [
                      const Text(
                        'SELECT PATIENT:',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_filteredChildren.length != widget.children.length)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryLight,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${_filteredChildren.length} found',
                            style: const TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Child Horizontal List
                SizedBox(
                  height: 122,
                  child: _filteredChildren.isEmpty
                      ? const Center(
                          child: Text(
                            'No patients match your search.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: _filteredChildren.length,
                          itemBuilder: (context, index) {
                            final child = _filteredChildren[index];
                            final isSelected = selectedChild?['id'] == child['id'];
                            
                            return Container(
                              width: 136,
                              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedChild = child;
                                    });
                                  },
                                  borderRadius: BorderRadius.zero,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.secondaryLight : AppTheme.surface,
                                      borderRadius: BorderRadius.zero,
                                      border: Border.all(
                                        color: isSelected ? AppTheme.secondary : AppTheme.border,
                                        width: isSelected ? 1.8 : 1,
                                      ),
                                      boxShadow: isSelected ? AppTheme.cardShadow : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppTheme.secondary : AppTheme.surfaceSubtle,
                                            borderRadius: BorderRadius.zero,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            (child['name'] ?? 'P')[0].toUpperCase(),
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          child['name'] ?? 'Unknown',
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            fontSize: 12,
                                            color: isSelected ? AppTheme.secondary : AppTheme.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Age: ${child['age'] ?? 'N/A'}',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: AppTheme.textSecondary,
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
                
                const Divider(height: 1, thickness: 1, color: AppTheme.border),
                
                // Child Details
                Expanded(
                  child: selectedChild == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceSubtle,
                                  borderRadius: BorderRadius.zero,
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: const Icon(
                                  Icons.touch_app_outlined,
                                  size: 28,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Select a patient above to view full clinical details',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Patient Details',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryLight,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppTheme.border, height: 20),
                const SizedBox(height: 6),
                _buildDetailRow('Full Name', selectedChild!['name']),
                _buildDetailRow('Age', '${selectedChild!['age'] ?? 'N/A'} years'),
                _buildDetailRow('Gender', selectedChild!['gender']),
                _buildDetailRow('Diagnosis', selectedChild!['diagnosis']),
                
                if (selectedChild!['additionalInfo'] != null && selectedChild!['additionalInfo'].toString().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Clinical Parent & Contact Info:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  _buildAdditionalInfo(selectedChild!['additionalInfo']),
                ],
              ],
            ),
          ),
        ],
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
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(String additionalInfo) {
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
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (infoMap['Parent Name'] != null) _buildInfoRow('Parent Name', infoMap['Parent Name']!),
          if (infoMap['Contact'] != null) _buildInfoRow('Contact', infoMap['Contact']!),
          if (infoMap['Parent Work'] != null) _buildInfoRow('Parent Work', infoMap['Parent Work']!),
          if (infoMap['Therapist'] != null) _buildInfoRow('Therapist ID', infoMap['Therapist']!),
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}
