import 'package:flutter/material.dart';
import 'services/child_service.dart';
import 'theme/app_theme.dart';

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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'My Children',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : widget.children.isEmpty
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
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(
                            Icons.child_care_rounded,
                            size: 36,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'No Children Registered',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Registered children will appear here with clinical milestones.',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (child['name'] ?? 'C')[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child['name'] ?? 'Unknown Child',
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.cake_outlined, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Age: ${child['age'] ?? 'N/A'}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                          ),
                          const SizedBox(width: 14),
                          const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            child['gender'] ?? 'N/A',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            
            // Action Button with Sharp Box Edges
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View Clinical Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Child Profile Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
                ),
              ],
            ),
            const Divider(color: AppTheme.border, height: 16),
            const SizedBox(height: 8),
            
            _buildDetailRow('Full Name', child['name']),
            _buildDetailRow('Age', '${child['age'] ?? 'N/A'} years'),
            _buildDetailRow('Gender', child['gender']),
            _buildDetailRow('Diagnosis', child['diagnosis']),
            
            if (child['additionalInfo'] != null && child['additionalInfo'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Clinical Notes / Info:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              _buildAdditionalInfo(child['additionalInfo']),
            ],
            
            const SizedBox(height: 22),
            
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
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
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
            width: 90,
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
