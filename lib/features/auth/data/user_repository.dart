import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/constants.dart';
import '../domain/entities/app_user.dart';

/// User repository for Firestore operations
class UserRepository {
  final FirestoreService _firestoreService;

  UserRepository(this._firestoreService);

  /// Create a new user profile in Firestore
  Future<void> createUser(AppUser user) async {
    await _firestoreService.set(
      AppConstants.usersCollection,
      user.uid,
      user.toMap(),
    );
  }

  /// Get user by ID
  Future<AppUser?> getUser(String uid) async {
    final doc = await _firestoreService.get(AppConstants.usersCollection, uid);
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return AppUser.fromMap({...doc.data()!, 'uid': doc.id});
  }

  /// Update user profile
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestoreService.update(AppConstants.usersCollection, uid, data);
  }

  /// Delete user profile
  Future<void> deleteUser(String uid) async {
    await _firestoreService.delete(AppConstants.usersCollection, uid);
  }

  /// Stream user data
  Stream<AppUser?> streamUser(String uid) {
    return _firestoreService
        .streamDocument(AppConstants.usersCollection, uid)
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return AppUser.fromMap({...doc.data()!, 'uid': doc.id});
    });
  }

  /// Get users by role
  Future<List<AppUser>> getUsersByRole(String role) async {
    final snapshot = await _firestoreService.query(
      AppConstants.usersCollection,
      filters: [QueryFilter(field: 'role', isEqualTo: role)],
    );
    return snapshot.docs
        .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
        .toList();
  }

  /// Get caregivers for a senior
  Future<List<AppUser>> getCaregiversForSenior(String seniorId) async {
    final snapshot = await _firestoreService.query(
      AppConstants.usersCollection,
      filters: [
        QueryFilter(field: 'role', isEqualTo: AppConstants.roleCaregiver),
        QueryFilter(field: 'assignedSeniors', arrayContains: seniorId),
      ],
    );
    return snapshot.docs
        .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
        .toList();
  }

  /// Get family members for a senior
  Future<List<AppUser>> getFamilyForSenior(String seniorId) async {
    final snapshot = await _firestoreService.query(
      AppConstants.usersCollection,
      filters: [
        QueryFilter(field: 'role', isEqualTo: AppConstants.roleFamily),
        QueryFilter(field: 'linkedSeniorId', isEqualTo: seniorId),
      ],
    );
    return snapshot.docs
        .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
        .toList();
  }

  /// Update FCM token for push notifications
  Future<void> updateFcmToken(String uid, String token) async {
    await _firestoreService.update(
      AppConstants.usersCollection,
      uid,
      {'fcmToken': token},
    );
  }

  /// Update user's last active timestamp
  Future<void> updateLastActive(String uid) async {
    await _firestoreService.update(
      AppConstants.usersCollection,
      uid,
      {'lastActiveAt': FieldValue.serverTimestamp()},
    );
  }
}

/// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return UserRepository(firestoreService);
});
