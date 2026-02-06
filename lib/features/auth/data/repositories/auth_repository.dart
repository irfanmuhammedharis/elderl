import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/app_user.dart';
import '../../../../core/utils/constants.dart';

/// Authentication repository wrapping Firebase Auth
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password
  Future<AppUser?> signIn(String email, String password) async {
    try {
      debugPrint('AuthRepository: Attempting sign in for $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      debugPrint('AuthRepository: Sign in successful, uid: ${credential.user?.uid}');
      
      if (credential.user != null) {
        final appUser = await _getUserData(credential.user!.uid);
        
        // If no user document exists, create a basic one
        if (appUser == null) {
          debugPrint('AuthRepository: Creating user document');
          final newUser = AppUser(
            uid: credential.user!.uid,
            email: email,
            name: email.split('@').first,
            role: 'senior',
            createdAt: DateTime.now(),
          );
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(newUser.uid)
              .set(newUser.toMap());
          return newUser;
        }
        
        return appUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthRepository: FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('AuthRepository: Unexpected error: $e');
      rethrow;
    }
  }

  /// Sign up with email, password and profile data
  Future<AppUser?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? linkedSeniorId,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        final user = AppUser(
          uid: credential.user!.uid,
          email: email,
          name: name,
          role: role,
          phone: phone,
          linkedSeniorId: linkedSeniorId,
          assignedSeniors: linkedSeniorId != null ? [linkedSeniorId] : null,
          createdAt: DateTime.now(),
        );
        
        // Save user data to Firestore
        // [FIX] Changed toJson() to toMap(). 
        // toJson() saves dates as Strings, but AppUser.fromMap() expects Firestore Timestamps.
        // Using toMap() ensures data consistency with the read pipeline.
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(user.toMap());
        
        // If linking to a senior, update the senior's linked family/caregivers list
        if (linkedSeniorId != null) {
          final seniorDoc = _firestore
              .collection(AppConstants.usersCollection)
              .doc(linkedSeniorId);
          
          if (role == AppConstants.roleFamily) {
            await seniorDoc.update({
              'linkedFamily': FieldValue.arrayUnion([credential.user!.uid]),
            });
          } else if (role == AppConstants.roleCaregiver) {
            await seniorDoc.update({
              'assignedCaregivers': FieldValue.arrayUnion([credential.user!.uid]),
            });
          }
        }
        
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Find a registered senior by their email
  /// Returns uid and name if found, null otherwise
  Future<Map<String, String>?> findSeniorByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isEqualTo: email.toLowerCase().trim())
          .where('role', isEqualTo: AppConstants.roleSenior)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['name'] as String? ?? 'Unknown',
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error finding senior by email: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current authenticated user's data from Firestore
  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _getUserData(user.uid);
  }

  /// Get user data from Firestore
  Future<AppUser?> _getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        // Use fromMap for Firestore documents (handles Timestamps)
        return AppUser.fromMap({...doc.data()!, 'uid': doc.id});
      }
      
      // If user doc doesn't exist, create a basic profile
      // This handles the case where auth succeeds but user doc wasn't created
      print('User document not found for uid: $uid, creating placeholder');
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Get user data stream
  Stream<AppUser?> getUserStream(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return AppUser.fromMap({...doc.data()!, 'uid': doc.id});
          }
          return null;
        });
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password provided';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
