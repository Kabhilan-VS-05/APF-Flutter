import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class ChildService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  // Register a new child (only for parents)
  Future<void> registerChild({
    required String name,
    required String age,
    required String gender,
    required String diagnosis,
    required String additionalInfo,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Check if user is a parent
      Map<String, dynamic>? userData = await _authService.getUserData(currentUser.uid);
      if (userData == null || userData['role'] != 'Parent') {
        throw 'Only parents can register children';
      }

      // Check if parent has already registered 3 children
      QuerySnapshot existingChildren = await _firestore
          .collection('children')
          .where('parentId', isEqualTo: currentUser.uid)
          .get();

      if (existingChildren.docs.length >= 3) {
        throw 'Maximum limit reached: You can register only 3 children';
      }

      // Create the child document
      await _firestore.collection('children').add({
        'name': name,
        'age': age,
        'gender': gender,
        'diagnosis': diagnosis,
        'additionalInfo': additionalInfo,
        'parentId': currentUser.uid,
        'createdAt': Timestamp.now(),
        'therapistId': null, // Will be assigned later
      });
    } catch (e) {
      throw e.toString();
    }
  }

  // Get children for current user (parent gets own children, therapist gets all)
  Future<List<Map<String, dynamic>>> getChildren() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      Map<String, dynamic>? userData = await _authService.getUserData(currentUser.uid);
      if (userData == null) {
        throw 'User data not found';
      }

      QuerySnapshot querySnapshot;
      
      if (userData['role'] == 'Parent') {
        // Parents can only see their own children
        querySnapshot = await _firestore
            .collection('children')
            .where('parentId', isEqualTo: currentUser.uid)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();
      } else if (userData['role'] == 'Therapist') {
        // Therapists can see all children
        querySnapshot = await _firestore
            .collection('children')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();
      } else {
        throw 'Invalid user role';
      }

      List<Map<String, dynamic>> children = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> childData = doc.data() as Map<String, dynamic>;
        childData['id'] = doc.id;
        children.add(childData);
      }

      return children;
    } catch (e) {
      throw e.toString();
    }
  }

  // Get specific child details
  Future<Map<String, dynamic>?> getChildDetails(String childId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      DocumentSnapshot doc = await _firestore.collection('children').doc(childId).get();
      
      if (!doc.exists) {
        throw 'Child not found';
      }

      Map<String, dynamic> childData = doc.data() as Map<String, dynamic>;
      childData['id'] = doc.id;

      // Check if user has access to this child
      Map<String, dynamic>? userData = await _authService.getUserData(currentUser.uid);
      if (userData == null) {
        throw 'User data not found';
      }

      if (userData['role'] == 'Parent' && childData['parentId'] != currentUser.uid) {
        throw 'Access denied: You can only view your own children';
      }

      return childData;
    } catch (e) {
      throw e.toString();
    }
  }

  // Update child information (only for parents)
  Future<void> updateChild({
    required String childId,
    required String name,
    required String age,
    required String gender,
    required String diagnosis,
    required String additionalInfo,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Check if user is the parent of this child
      DocumentSnapshot doc = await _firestore.collection('children').doc(childId).get();
      
      if (!doc.exists) {
        throw 'Child not found';
      }

      Map<String, dynamic> childData = doc.data() as Map<String, dynamic>;
      
      if (childData['parentId'] != currentUser.uid) {
        throw 'Access denied: You can only edit your own children';
      }

      // Update child information
      await _firestore.collection('children').doc(childId).update({
        'name': name,
        'age': age,
        'gender': gender,
        'diagnosis': diagnosis,
        'additionalInfo': additionalInfo,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw e.toString();
    }
  }

  // Delete child (only for parents)
  Future<void> deleteChild(String childId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Check if user is the parent of this child
      DocumentSnapshot doc = await _firestore.collection('children').doc(childId).get();
      
      if (!doc.exists) {
        throw 'Child not found';
      }

      Map<String, dynamic> childData = doc.data() as Map<String, dynamic>;
      
      if (childData['parentId'] != currentUser.uid) {
        throw 'Access denied: You can only delete your own children';
      }

      // Soft delete (set isActive to false)
      await _firestore.collection('children').doc(childId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw e.toString();
    }
  }

  // Add therapist note for a child
  Future<String> addTherapistNote({
    required String childId,
    required String note,
    required String sessionType,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Check if user is a therapist
      Map<String, dynamic>? userData = await _authService.getUserData(currentUser.uid);
      if (userData == null || userData['role'] != 'Therapist') {
        throw 'Only therapists can add notes';
      }

      // Add note
      DocumentReference noteRef = await _firestore
          .collection('children')
          .doc(childId)
          .collection('notes')
          .add({
        'note': note,
        'sessionType': sessionType,
        'therapistId': currentUser.uid,
        'therapistName': userData['username'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      return noteRef.id;
    } catch (e) {
      throw e.toString();
    }
  }

  // Get notes for a child
  Future<List<Map<String, dynamic>>> getChildNotes(String childId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Check if user has access to this child
      Map<String, dynamic>? userData = await _authService.getUserData(currentUser.uid);
      if (userData == null) {
        throw 'User data not found';
      }

      DocumentSnapshot childDoc = await _firestore.collection('children').doc(childId).get();
      
      if (!childDoc.exists) {
        throw 'Child not found';
      }

      Map<String, dynamic> childData = childDoc.data() as Map<String, dynamic>;
      
      if (userData['role'] == 'Parent' && childData['parentId'] != currentUser.uid) {
        throw 'Access denied: You can only view notes for your own children';
      }

      // Get notes
      QuerySnapshot notesSnapshot = await _firestore
          .collection('children')
          .doc(childId)
          .collection('notes')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> notes = [];
      for (var doc in notesSnapshot.docs) {
        Map<String, dynamic> noteData = doc.data() as Map<String, dynamic>;
        noteData['id'] = doc.id;
        notes.add(noteData);
      }

      return notes;
    } catch (e) {
      throw e.toString();
    }
  }

  // Add therapist report
  Future<void> addTherapistReport({
    required String childId,
    required Map<String, dynamic> report,
    required String therapistId,
    required String therapistName,
  }) async {
    try {
      // Get child details to find parent
      DocumentSnapshot childDoc = await _firestore.collection('children').doc(childId).get();
      if (!childDoc.exists) {
        throw 'Child not found';
      }
      
      Map<String, dynamic> childData = childDoc.data() as Map<String, dynamic>;
      String parentId = childData['parentId'];

      // Add report to reports collection
      await _firestore.collection('reports').add({
        ...report,
        'childId': childId,
        'parentId': parentId,
        'therapistId': therapistId,
        'therapistName': therapistName,
        'createdAt': Timestamp.now(),
      });

      // Add notification for parent
      await _firestore.collection('notifications').add({
        'userId': parentId,
        'type': 'new_report',
        'title': 'New Assessment Report',
        'message': 'A new assessment report is available for ${report['childName']}',
        'data': {
          'reportId': report['reportId'],
          'childId': childId,
          'childName': report['childName'],
        },
        'createdAt': Timestamp.now(),
        'read': false,
      });
    } catch (e) {
      throw e.toString();
    }
  }

  // Search children by name or ID (for therapists)
  Future<List<Map<String, dynamic>>> searchChildren(String searchTerm) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Check if user is a therapist
      Map<String, dynamic>? userData = await _authService.getUserData(currentUser.uid);
      if (userData == null || userData['role'] != 'Therapist') {
        throw 'Only therapists can search children';
      }

      // Search by name or ID
      QuerySnapshot querySnapshot = await _firestore
          .collection('children')
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> filteredChildren = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> childData = doc.data() as Map<String, dynamic>;
        childData['id'] = doc.id;

        // Check if search term matches name or ID
        if (childData['name'].toString().toLowerCase().contains(searchTerm.toLowerCase()) ||
            doc.id.toLowerCase().contains(searchTerm.toLowerCase())) {
          filteredChildren.add(childData);
        }
      }

      return filteredChildren;
    } catch (e) {
      throw e.toString();
    }
  }
}
