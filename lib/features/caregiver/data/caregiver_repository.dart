import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/constants.dart';
import '../../auth/domain/entities/app_user.dart';
import '../../requests/data/request_repository.dart';

/// Caregiver repository for managing caregiver-senior relationships
class CaregiverRepository {
  final FirestoreService _firestoreService;
  FirebaseFirestore get _firestore => _firestoreService.firestore;

  CaregiverRepository(this._firestoreService);

  /// Assign a caregiver to a senior
  Future<void> assignToSenior(String caregiverId, String seniorId) async {
    // [FIX] Use a WriteBatch to ensure both updates happen atomically.
    // If one fails, neither is applied, maintaining data integrity.
    final batch = _firestore.batch();

    final caregiverRef = _firestore.collection(AppConstants.usersCollection).doc(caregiverId);
    final seniorRef = _firestore.collection(AppConstants.usersCollection).doc(seniorId);

    // Add senior to caregiver's assignedSeniors list
    batch.update(caregiverRef, {
      'assignedSeniors': FieldValue.arrayUnion([seniorId]),
    });

    // Add caregiver to senior's assignedCaregivers list
    batch.update(seniorRef, {
      'assignedCaregivers': FieldValue.arrayUnion([caregiverId]),
    });

    await batch.commit();
  }

  /// Unassign a caregiver from a senior
  Future<void> unassignFromSenior(String caregiverId, String seniorId) async {
    // [FIX] Use a WriteBatch for atomic removal.
    final batch = _firestore.batch();

    final caregiverRef = _firestore.collection(AppConstants.usersCollection).doc(caregiverId);
    final seniorRef = _firestore.collection(AppConstants.usersCollection).doc(seniorId);

    // Remove senior from caregiver's list
    batch.update(caregiverRef, {
      'assignedSeniors': FieldValue.arrayRemove([seniorId]),
    });

    // Remove caregiver from senior's list
    batch.update(seniorRef, {
      'assignedCaregivers': FieldValue.arrayRemove([caregiverId]),
    });

    await batch.commit();
  }

  /// Batch-fetch users by document IDs using whereIn (max 10 per query)
  Future<List<AppUser>> _batchFetchUsers(List<String> userIds) async {
    final users = <AppUser>[];
    for (var i = 0; i < userIds.length; i += 10) {
      final end = i + 10 > userIds.length ? userIds.length : i + 10;
      final batch = userIds.sublist(i, end);
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      users.addAll(
        snapshot.docs.map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id})),
      );
    }
    return users;
  }

  /// Get all seniors assigned to a caregiver
  Future<List<AppUser>> getAssignedSeniors(String caregiverId) async {
    // Get caregiver's document to get assigned senior IDs
    final caregiverDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(caregiverId)
        .get();

    if (!caregiverDoc.exists) return [];

    final assignedSeniors =
        (caregiverDoc.data()?['assignedSeniors'] as List<dynamic>?)
                ?.cast<String>() ??
            [];

    if (assignedSeniors.isEmpty) return [];

    // Batch fetch seniors using whereIn (fixes N+1 sequential reads)
    return _batchFetchUsers(assignedSeniors);
  }

  /// Stream assigned seniors for real-time updates
  Stream<List<AppUser>> streamAssignedSeniors(String caregiverId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(caregiverId)
        .snapshots()
        .asyncMap((caregiverDoc) async {
      if (!caregiverDoc.exists) return <AppUser>[];

      final assignedSeniors =
          (caregiverDoc.data()?['assignedSeniors'] as List<dynamic>?)
                  ?.cast<String>() ??
              [];

      if (assignedSeniors.isEmpty) return <AppUser>[];

      // Batch fetch seniors using whereIn (fixes N+1 sequential reads)
      return _batchFetchUsers(assignedSeniors);
    });
  }

  /// Get pending requests for all assigned seniors
  Future<List<HelpRequest>> getPendingRequests(String caregiverId) async {
    final snapshot = await _firestore
        .collection(AppConstants.requestsCollection)
        .where('status', isEqualTo: AppConstants.statusPending)
        .limit(50)
        .get();

    final requests = snapshot.docs
        .map((doc) => HelpRequest.fromMap(doc.data(), id: doc.id))
        .toList();
    requests.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    return requests;
  }

  /// Stream pending requests in real-time
  Stream<List<HelpRequest>> streamPendingRequests() {
    return _firestore
        .collection(AppConstants.requestsCollection)
        .where('status', isEqualTo: AppConstants.statusPending)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => HelpRequest.fromMap(doc.data(), id: doc.id))
              .toList();
          requests.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
          return requests;
        });
  }

  /// Get requests assigned to this caregiver
  Future<List<HelpRequest>> getMyAssignedRequests(String caregiverId) async {
    final snapshot = await _firestore
        .collection(AppConstants.requestsCollection)
        .where('assignedTo', isEqualTo: caregiverId)
        .where('status', whereIn: [
          AppConstants.statusAccepted,
          AppConstants.statusInProgress
        ])
        .get();

    final requests = snapshot.docs
        .map((doc) => HelpRequest.fromMap(doc.data(), id: doc.id))
        .toList();
    requests.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    return requests;
  }

  /// Stream my assigned requests
  Stream<List<HelpRequest>> streamMyAssignedRequests(String caregiverId) {
    return _firestore
        .collection(AppConstants.requestsCollection)
        .where('assignedTo', isEqualTo: caregiverId)
        .where('status', whereIn: [
          AppConstants.statusAccepted,
          AppConstants.statusInProgress,
        ])
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => HelpRequest.fromMap(doc.data(), id: doc.id))
              .toList();
          requests.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
          return requests;
        });
  }

  /// Accept a request (uses transaction to prevent race conditions)
  Future<void> acceptRequest(
      String requestId, String caregiverId, String caregiverName) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection(AppConstants.requestsCollection).doc(requestId);
      final snapshot = await transaction.get(docRef);
      
      if (!snapshot.exists) {
        throw Exception('Request no longer exists');
      }
      
      final currentStatus = snapshot.data()?['status'] as String?;
      if (currentStatus != AppConstants.statusPending) {
        throw Exception('Request is no longer available (status: $currentStatus)');
      }
      
      transaction.update(docRef, {
        'status': AppConstants.statusAccepted,
        'assignedTo': caregiverId,
        'assignedToName': caregiverName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    // Link the caregiver ↔ senior relationship
    // (runs outside the transaction since it touches different documents)
    final requestDoc = await _firestore
        .collection(AppConstants.requestsCollection)
        .doc(requestId)
        .get();
    final seniorId = requestDoc.data()?['seniorId'] as String?;
    if (seniorId != null && seniorId.isNotEmpty) {
      await assignToSenior(caregiverId, seniorId);
    }
  }

  /// Mark request as in progress
  Future<void> markInProgress(String requestId) async {
    await _firestore.collection(AppConstants.requestsCollection).doc(requestId).update({
      'status': AppConstants.statusInProgress,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Complete a request
  Future<void> completeRequest(String requestId) async {
    await _firestore.collection(AppConstants.requestsCollection).doc(requestId).update({
      'status': AppConstants.statusCompleted,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get completed requests history
  Future<List<HelpRequest>> getCompletedRequests(String caregiverId,
      {int limit = 50}) async {
    final snapshot = await _firestore
        .collection(AppConstants.requestsCollection)
        .where('assignedTo', isEqualTo: caregiverId)
        .where('status', isEqualTo: AppConstants.statusCompleted)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => HelpRequest.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  /// Get seniors who missed check-in today
  Future<List<AppUser>> getSeniorsWithMissedCheckIn(String caregiverId) async {
    final seniors = await getAssignedSeniors(caregiverId);
    final missedSeniors = <AppUser>[];

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    for (final senior in seniors) {
      final checkIn = await _firestore
          .collection(AppConstants.checkinsCollection)
          .where('seniorId', isEqualTo: senior.uid)
          .where('checkinTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .limit(1)
          .get();

      if (checkIn.docs.isEmpty) {
        missedSeniors.add(senior);
      }
    }

    return missedSeniors;
  }

  /// Get all caregivers (for admin)
  Future<List<AppUser>> getAllCaregivers() async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: 'caregiver')
        .get();

    return snapshot.docs
        .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
        .toList();
  }

  /// Get caregivers assigned to a senior
  Future<List<AppUser>> getCaregivers(String seniorId) async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('assignedSeniors', arrayContains: seniorId)
        .where('role', isEqualTo: 'caregiver')
        .get();

    return snapshot.docs
        .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
        .toList();
  }
}

/// Caregiver repository provider
final caregiverRepositoryProvider = Provider<CaregiverRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return CaregiverRepository(firestoreService);
});
