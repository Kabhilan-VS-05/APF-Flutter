import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DebugParentsPage extends StatefulWidget {
  const DebugParentsPage({super.key});

  @override
  State<DebugParentsPage> createState() => _DebugParentsPageState();
}

class _DebugParentsPageState extends State<DebugParentsPage> {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _parents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      
      // Get all users
      QuerySnapshot allUsersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      // Get only parents
      QuerySnapshot parentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Parent')
          .get();
      
      setState(() {
        _allUsers = allUsersSnapshot.docs.map((doc) {
          Map<String, dynamic> user = doc.data() as Map<String, dynamic>;
          user['id'] = doc.id;
          return user;
        }).toList();
        
        _parents = parentsSnapshot.docs.map((doc) {
          Map<String, dynamic> parent = doc.data() as Map<String, dynamic>;
          parent['id'] = doc.id;
          return parent;
        }).toList();
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug: Users & Parents'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Users: ${_allUsers.length}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Parent Users: ${_parents.length}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    'All Users:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._allUsers.map((user) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Username: ${user['username'] ?? 'N/A'}'),
                          Text('Email: ${user['email'] ?? 'N/A'}'),
                          Text('Role: ${user['role'] ?? 'N/A'}'),
                          Text('Phone: ${user['phone'] ?? 'N/A'}'),
                          Text('Contact: ${user['contact'] ?? 'N/A'}'),
                          Text('Work: ${user['work'] ?? 'N/A'}'),
                          Text('Active: ${user['isActive'] ?? 'N/A'}'),
                          Text('ID: ${user['id']}'),
                        ],
                      ),
                    ),
                  )).toList(),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Parents Only:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._parents.map((parent) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Username: ${parent['username'] ?? 'N/A'}'),
                          Text('Email: ${parent['email'] ?? 'N/A'}'),
                          Text('Phone: ${parent['phone'] ?? 'N/A'}'),
                          Text('Contact: ${parent['contact'] ?? 'N/A'}'),
                          Text('Work: ${parent['work'] ?? 'N/A'}'),
                          Text('ID: ${parent['id']}'),
                        ],
                      ),
                    ),
                  )).toList(),
                ],
              ),
            ),
    );
  }
}
