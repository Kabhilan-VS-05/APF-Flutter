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
    required String address,
    required String role,
    String? work,
  }) async {
    try {
      // Only check duplicate name + hospital address for Therapist accounts
      if (role == 'Therapist' && address.trim().isNotEmpty) {
        String normalize(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
        final targetName = normalize(username);
        final targetAddress = normalize(address);

        // Pre-check for duplicate Name and Address if unauthenticated query is permitted
        try {
          final usersSnapshot = await _firestore.collection('users').where('role', isEqualTo: 'Therapist').get();
          for (var doc in usersSnapshot.docs) {
            final data = doc.data();
            final existingName = normalize((data['username'] ?? '').toString());
            final existingAddress = normalize((data['address'] ?? '').toString());

            if (existingName.isNotEmpty &&
                existingAddress.isNotEmpty &&
                existingName == targetName &&
                existingAddress == targetAddress) {
              throw 'A therapist account already exists with the same Name and Hospital Address ($username, $address).';
            }
          }
        } catch (e) {
          if (e.toString().contains('already exists with the same Name and Hospital Address')) {
            rethrow;
          }
          // If unauthenticated list read is denied by Firestore rules, proceed to post-auth verification
        }
      }

      // Create user with email and password in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Post-auth duplicate check for Therapists with authenticated credentials
      if (role == 'Therapist' && address.trim().isNotEmpty) {
        try {
          String normalize(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
          final targetName = normalize(username);
          final targetAddress = normalize(address);

          final usersSnapshot = await _firestore.collection('users').where('role', isEqualTo: 'Therapist').get();
          for (var doc in usersSnapshot.docs) {
            if (doc.id == userCredential.user!.uid) continue;
            final data = doc.data();
            final existingName = normalize((data['username'] ?? '').toString());
            final existingAddress = normalize((data['address'] ?? '').toString());

            if (existingName.isNotEmpty &&
                existingAddress.isNotEmpty &&
                existingName == targetName &&
                existingAddress == targetAddress) {
              // Clean up newly created auth user before throwing
              try {
                await userCredential.user!.delete();
              } catch (_) {}
              try {
                await _auth.signOut();
              } catch (_) {}
              throw 'A therapist account already exists with the same Name and Hospital Address ($username, $address).';
            }
          }
        } catch (e) {
          if (e.toString().contains('already exists with the same Name and Hospital Address')) {
            rethrow;
          }
        }
      }

      // Store additional user data in Firestore
      Map<String, dynamic> userData = {
        'username': username.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'panCard': panCard.toUpperCase().trim(),
        'address': address.trim(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      // Add work field for parents
      if (role == 'Parent') {
        userData['work'] = work?.trim() ?? '';
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

  // Update user data in Firestore
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).set(data, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to update profile: $e';
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
