import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/constants.dart';
import '../../auth/domain/entities/app_user.dart';

/// Admin repository for user management operations
class AdminRepository {
  final FirestoreService _firestoreService;

  AdminRepository(this._firestoreService);

  /// Get all users
  Future<List<AppUser>> getAllUsers() async {
    final snapshot =
        await _firestoreService.getAll(AppConstants.usersCollection);
    return snapshot.docs
        .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
        .toList();
  }

  /// Get users by role
  Future<List<AppUser>> getUsersByRole(String role) async {
    final snapshot = await _firestoreService.query(
      AppConstants.usersCollection,
      filters: [QueryFilter(field: 'role', isEqualTo: role)],
    );
    final users = snapshot.docs
        .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
        .toList();
    users.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    return users;
  }

  /// Get users by approval status
  Future<List<AppUser>> getUsersByApprovalStatus(ApprovalStatus status) async {
    final statusString = _approvalStatusToString(status);
    final snapshot = await _firestoreService.query(
      AppConstants.usersCollection,
      filters: [QueryFilter(field: 'approvalStatus', isEqualTo: statusString)],
    );
    final users = snapshot.docs
        .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
        .toList();
    users.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    return users;
  }

  /// Get pending approval users
  Future<List<AppUser>> getPendingUsers() async {
    return getUsersByApprovalStatus(ApprovalStatus.pending);
  }

  /// Get users by role and approval status
  Future<List<AppUser>> getUsersByRoleAndStatus(
      String? role, ApprovalStatus? status) async {
    final List<QueryFilter> filters = [];

    if (role != null && role.isNotEmpty) {
      filters.add(QueryFilter(field: 'role', isEqualTo: role));
    }

    if (status != null) {
      filters.add(QueryFilter(
          field: 'approvalStatus', isEqualTo: _approvalStatusToString(status)));
    }

    final snapshot = await _firestoreService.query(
      AppConstants.usersCollection,
      filters: filters.isEmpty ? null : filters,
    );

    final users = snapshot.docs
        .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
        .toList();
    users.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    return users;
  }

  /// Stream all users
  Stream<List<AppUser>> streamAllUsers() {
    return _firestoreService
        .streamCollection(AppConstants.usersCollection,
            orderBy: 'createdAt', descending: true)
        .map((snapshot) => snapshot.docs
            .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
            .toList());
  }

  /// Stream pending users
  Stream<List<AppUser>> streamPendingUsers() {
    return _firestoreService
        .streamCollection(
          AppConstants.usersCollection,
          filters: [QueryFilter(field: 'approvalStatus', isEqualTo: 'pending')],
        )
        .map((snapshot) {
          final users = snapshot.docs
              .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
              .toList();
          users.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
          return users;
        });
  }

  /// Stream users by role
  Stream<List<AppUser>> streamUsersByRole(String role) {
    return _firestoreService
        .streamCollection(
          AppConstants.usersCollection,
          filters: [QueryFilter(field: 'role', isEqualTo: role)],
        )
        .map((snapshot) {
          final users = snapshot.docs
              .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
              .toList();
          users.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
          return users;
        });
  }

  /// Get single user by ID
  Future<AppUser?> getUserById(String uid) async {
    final doc = await _firestoreService.get(AppConstants.usersCollection, uid);
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return AppUser.fromMap({...doc.data()!, 'uid': doc.id});
  }

  /// Stream single user
  Stream<AppUser?> streamUser(String uid) {
    return _firestoreService
        .streamDocument(AppConstants.usersCollection, uid)
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap({...doc.data()!, 'uid': doc.id});
    });
  }

  /// Approve user
  Future<void> approveUser(String uid, String adminUid) async {
    await _firestoreService.update(
      AppConstants.usersCollection,
      uid,
      {
        'approvalStatus': 'approved',
        'approvedBy': adminUid,
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
      },
    );
  }

  /// Reject user
  Future<void> rejectUser(String uid, String adminUid, String reason) async {
    await _firestoreService.update(
      AppConstants.usersCollection,
      uid,
      {
        'approvalStatus': 'rejected',
        'approvedBy': adminUid,
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      },
    );
  }

  /// Reset user to pending (for re-review)
  Future<void> resetToPending(String uid) async {
    await _firestoreService.update(
      AppConstants.usersCollection,
      uid,
      {
        'approvalStatus': 'pending',
        'approvedBy': null,
        'approvedAt': null,
        'rejectionReason': null,
      },
    );
  }

  /// Update user profile
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestoreService.update(AppConstants.usersCollection, uid, data);
  }

  /// Delete user
  Future<void> deleteUser(String uid) async {
    await _firestoreService.delete(AppConstants.usersCollection, uid);
  }

  /// Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    final allUsers = await getAllUsers();

    return {
      'total': allUsers.length,
      'seniors': allUsers.where((u) => u.role == 'senior').length,
      'caregivers': allUsers.where((u) => u.role == 'caregiver').length,
      'family': allUsers.where((u) => u.role == 'family').length,
      'admins': allUsers.where((u) => u.role == 'admin').length,
      'pending': allUsers
          .where((u) => u.approvalStatus == ApprovalStatus.pending)
          .length,
      'approved': allUsers
          .where((u) => u.approvalStatus == ApprovalStatus.approved)
          .length,
      'rejected': allUsers
          .where((u) => u.approvalStatus == ApprovalStatus.rejected)
          .length,
    };
  }

  /// Search users by name or email
  Future<List<AppUser>> searchUsers(String query) async {
    // Firestore doesn't support native full-text search
    // We'll fetch all and filter client-side for now
    final allUsers = await getAllUsers();
    final queryLower = query.toLowerCase();

    return allUsers.where((user) {
      return user.name.toLowerCase().contains(queryLower) ||
          user.email.toLowerCase().contains(queryLower) ||
          (user.phone?.contains(query) ?? false);
    }).toList();
  }

  // ─── Admin Linking / Assignment Methods ────────────────────────────

  /// Assign a caregiver to a senior (bidirectional atomic update)
  Future<void> assignCaregiverToSenior(String caregiverId, String seniorId) async {
    final firestore = _firestoreService.firestore;
    final batch = firestore.batch();

    final caregiverRef = firestore.collection(AppConstants.usersCollection).doc(caregiverId);
    final seniorRef = firestore.collection(AppConstants.usersCollection).doc(seniorId);

    batch.update(caregiverRef, {
      'assignedSeniors': FieldValue.arrayUnion([seniorId]),
    });
    batch.update(seniorRef, {
      'assignedCaregivers': FieldValue.arrayUnion([caregiverId]),
    });

    await batch.commit();
  }

  /// Unassign a caregiver from a senior (bidirectional atomic removal)
  Future<void> unassignCaregiverFromSenior(String caregiverId, String seniorId) async {
    final firestore = _firestoreService.firestore;
    final batch = firestore.batch();

    final caregiverRef = firestore.collection(AppConstants.usersCollection).doc(caregiverId);
    final seniorRef = firestore.collection(AppConstants.usersCollection).doc(seniorId);

    batch.update(caregiverRef, {
      'assignedSeniors': FieldValue.arrayRemove([seniorId]),
    });
    batch.update(seniorRef, {
      'assignedCaregivers': FieldValue.arrayRemove([caregiverId]),
    });

    await batch.commit();
  }

  /// Link a family member to a senior (bidirectional atomic update)
  Future<void> linkFamilyToSenior(String familyId, String seniorId) async {
    final firestore = _firestoreService.firestore;
    final batch = firestore.batch();

    final familyRef = firestore.collection(AppConstants.usersCollection).doc(familyId);
    final seniorRef = firestore.collection(AppConstants.usersCollection).doc(seniorId);

    batch.update(familyRef, {'linkedSeniorId': seniorId});
    batch.update(seniorRef, {
      'linkedFamily': FieldValue.arrayUnion([familyId]),
    });

    await batch.commit();
  }

  /// Unlink a family member from a senior (bidirectional atomic removal)
  Future<void> unlinkFamilyFromSenior(String familyId, String seniorId) async {
    final firestore = _firestoreService.firestore;
    final batch = firestore.batch();

    final familyRef = firestore.collection(AppConstants.usersCollection).doc(familyId);
    final seniorRef = firestore.collection(AppConstants.usersCollection).doc(seniorId);

    batch.update(familyRef, {'linkedSeniorId': null});
    batch.update(seniorRef, {
      'linkedFamily': FieldValue.arrayRemove([familyId]),
    });

    await batch.commit();
  }

  /// Get approved users by role
  Future<List<AppUser>> getApprovedUsersByRole(String role) async {
    // Query by role only; filter approvalStatus client-side to avoid composite index.
    final firestore = _firestoreService.firestore;
    final snapshot = await firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: role)
        .get();

    final users = snapshot.docs
        .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
        .where((u) => u.approvalStatus == ApprovalStatus.approved)
        .toList();
    users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return users;
  }

  /// Batch-fetch users by IDs (max 10 per Firestore whereIn)
  Future<List<AppUser>> getUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final firestore = _firestoreService.firestore;
    final users = <AppUser>[];
    for (var i = 0; i < ids.length; i += 10) {
      final end = i + 10 > ids.length ? ids.length : i + 10;
      final batch = ids.sublist(i, end);
      final snapshot = await firestore
          .collection(AppConstants.usersCollection)
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      users.addAll(
        snapshot.docs.map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id})),
      );
    }
    return users;
  }

  String _approvalStatusToString(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.approved:
        return 'approved';
      case ApprovalStatus.rejected:
        return 'rejected';
      case ApprovalStatus.pending:
        return 'pending';
    }
  }
}

/// Admin repository provider
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return AdminRepository(firestoreService);
});
