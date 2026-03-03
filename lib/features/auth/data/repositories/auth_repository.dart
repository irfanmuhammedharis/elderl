import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/app_user.dart';
import '../../../../core/utils/constants.dart';

/// Authentication repository wrapping Firebase Auth
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

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
        
        // If no user document exists, return an error instead of
        // silently creating a placeholder with a hardcoded role.
        if (appUser == null) {
          debugPrint('AuthRepository: No user document found for uid: ${credential.user!.uid}');
          throw Exception('Account profile not found. Please sign up first or contact an administrator.');
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
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        final user = AppUser(
          uid: credential.user!.uid,
          email: email.trim().toLowerCase(),
          name: name,
          role: role,
          phone: phone,
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
        
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('AuthRepository: SignUp error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('AuthRepository: SignOut error: $e');
      rethrow;
    }
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
  Exception _handleAuthException(FirebaseAuthException e) {
    final message = switch (e.code) {
      'user-not-found' => 'No user found with this email',
      'wrong-password' => 'Wrong password provided',
      'email-already-in-use' => 'Email is already registered',
      'weak-password' => 'Password is too weak',
      'invalid-email' => 'Invalid email address',
      'user-disabled' => 'This account has been disabled',
      _ => e.message ?? 'Authentication failed',
    };
    return Exception(message);
  }
}
