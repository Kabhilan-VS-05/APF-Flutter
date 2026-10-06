import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService() {
    // Set language code to prevent null locale header warnings
    try {
      _auth.setLanguageCode('en');
    } catch (e) {
      // Silently handle any errors during initialization
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String username,
    required String phone,
    required String panCard,
    required String role,
    String? work,
  }) async {
    try {
      // TODO: Re-enable duplicate checking after Firestore rules are deployed
      // For now, skip duplicate checking to avoid permission errors
      
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store additional user data in Firestore
      Map<String, dynamic> userData = {
        'username': username,
        'email': email,
        'phone': phone,
        'panCard': panCard.toUpperCase(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      // Add work field for parents
      if (role == 'Parent') {
        userData['work'] = work ?? '';
      }

      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Sign in with email or username and password
  Future<UserCredential?> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      String email = emailOrUsername;
      
      // TODO: Re-enable username lookup after Firestore rules are deployed
      // For now, only allow email login to avoid permission errors
      if (!emailOrUsername.contains('@')) {
        throw 'Please use your email address to login. Username login will be available after system updates.';
      }

      // Sign in with the email
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Get user role from Firestore
  Future<String?> getUserRole(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.get('role') as String?;
      }
      return null;
    } catch (e) {
      throw 'Failed to get user role.';
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw 'Failed to get user data.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Failed to sign out.';
    }
  }

  // Reset password
  Future<void> resetPassword(String emailOrUsername) async {
    try {
      String email = emailOrUsername;
      
      // TODO: Re-enable username lookup after Firestore rules are deployed
      // For now, only allow email reset to avoid permission errors
      if (!emailOrUsername.contains('@')) {
        throw 'Please use your email address to reset password. Username reset will be available after system updates.';
      }

      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Get user-friendly error messages
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found for this email/username.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      default:
        return 'An authentication error occurred: ${e.message}';
    }
  }
}
