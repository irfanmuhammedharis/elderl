import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/constants.dart';
import '../../auth/domain/entities/app_user.dart';
import '../../checkin/data/checkin_repository.dart';
import '../../requests/data/request_repository.dart';

/// Family repository for managing family-senior relationships
class FamilyRepository {
  final FirestoreService _firestoreService;
  FirebaseFirestore get _firestore => _firestoreService.firestore;

  FamilyRepository(this._firestoreService);

  /// Link a family member to a senior (by senior's email or invite code)
  Future<bool> linkToSenior(String familyUserId, String seniorEmail) async {
    if (familyUserId.isEmpty) {
      throw Exception('Not authenticated');
    }

    final normalizedEmail = seniorEmail.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw Exception('Please enter a valid email address');
    }

    // Find the senior by email.
    // We query without the role filter first (simpler index), then
    // verify the role in code. This avoids composite-index issues
    // and gives a clearer error when the email belongs to a non-senior.
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('No account found with this email. Please check the email address.');
    }

    final seniorDoc = snapshot.docs.first;
    final seniorData = seniorDoc.data();
    final seniorRole = seniorData['role'] as String? ?? '';

    if (seniorRole != 'senior') {
      throw Exception('That account is not a senior account. Only seniors can be linked to a family member.');
    }

    final seniorId = snapshot.docs.first.id;

    // [FIX] Use WriteBatch for atomic updates
    final batch = _firestore.batch();
    
    final familyRef = _firestore.collection(AppConstants.usersCollection).doc(familyUserId);
    final seniorRef = _firestore.collection(AppConstants.usersCollection).doc(seniorId);

    // Update family member's linkedSeniorId
    batch.update(familyRef, {'linkedSeniorId': seniorId});

    // Add family member to senior's linkedFamily list
    batch.update(seniorRef, {
      'linkedFamily': FieldValue.arrayUnion([familyUserId]),
    });

    await batch.commit();
    return true;
  }

  /// Unlink a family member from a senior
  Future<void> unlinkFromSenior(String familyUserId, String seniorId) async {
    // [FIX] Use WriteBatch for atomic updates
    final batch = _firestore.batch();
    
    final familyRef = _firestore.collection(AppConstants.usersCollection).doc(familyUserId);
    final seniorRef = _firestore.collection(AppConstants.usersCollection).doc(seniorId);

    // Remove linkedSeniorId from family member
    batch.update(familyRef, {'linkedSeniorId': null});

    // Remove family member from senior's linkedFamily list
    batch.update(seniorRef, {
      'linkedFamily': FieldValue.arrayRemove([familyUserId]),
    });

    await batch.commit();
  }

  /// Get the linked senior for a family member
  Future<AppUser?> getLinkedSenior(String familyUserId) async {
    // Get family member's document
    final familyDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(familyUserId)
        .get();

    if (!familyDoc.exists) return null;

    final linkedSeniorId = familyDoc.data()?['linkedSeniorId'] as String?;
    if (linkedSeniorId == null || linkedSeniorId.isEmpty) return null;

    // Get senior's document
    final seniorDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(linkedSeniorId)
        .get();

    if (!seniorDoc.exists) return null;

    return AppUser.fromMap({...seniorDoc.data()!, 'uid': seniorDoc.id});
  }

  /// Stream the linked senior for real-time updates
  Stream<AppUser?> streamLinkedSenior(String familyUserId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(familyUserId)
        .snapshots()
        .asyncMap((familyDoc) async {
      if (!familyDoc.exists) return null;

      final linkedSeniorId = familyDoc.data()?['linkedSeniorId'] as String?;
      // Guard against both null and empty-string values that would otherwise
      // cause a Firestore fetch with an invalid document ID.
      if (linkedSeniorId == null || linkedSeniorId.isEmpty) return null;

      final seniorDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(linkedSeniorId)
          .get();

      if (!seniorDoc.exists) return null;

      return AppUser.fromMap({...seniorDoc.data()!, 'uid': seniorDoc.id});
    });
  }

  /// Get senior's recent check-ins (for family to monitor)
  Future<List<CheckIn>> getSeniorCheckIns(String seniorId, {int limit = 7}) async {
    // Query by seniorId only (no orderBy) to avoid requiring a composite index.
    // Sort client-side; dataset is small (limit 7).
    final snapshot = await _firestore
        .collection(AppConstants.checkinsCollection)
        .where('seniorId', isEqualTo: seniorId)
        .limit(limit)
        .get();

    final results = snapshot.docs
        .map((doc) => CheckIn.fromMap(doc.data(), id: doc.id))
        .toList();
    results.sort((a, b) =>
        (b.checkinTime ?? DateTime(2000)).compareTo(a.checkinTime ?? DateTime(2000)));
    return results;
  }

  /// Stream senior's check-ins for real-time updates
  Stream<List<CheckIn>> streamSeniorCheckIns(String seniorId, {int limit = 7}) {
    // Query by seniorId only (no orderBy) to avoid requiring a composite index.
    // Sort client-side; dataset is small (limit 7).
    return _firestore
        .collection(AppConstants.checkinsCollection)
        .where('seniorId', isEqualTo: seniorId)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final results = snapshot.docs
              .map((doc) => CheckIn.fromMap(doc.data(), id: doc.id))
              .toList();
          results.sort((a, b) =>
              (b.checkinTime ?? DateTime(2000)).compareTo(a.checkinTime ?? DateTime(2000)));
          return results;
        });
  }

  /// Get senior's active requests
  Future<List<HelpRequest>> getSeniorRequests(String seniorId) async {
    // Query by seniorId only (no orderBy) to avoid requiring a composite index.
    // Sort client-side; dataset is small (limit 20).
    final snapshot = await _firestore
        .collection(AppConstants.requestsCollection)
        .where('seniorId', isEqualTo: seniorId)
        .limit(20)
        .get();

    final results = snapshot.docs
        .map((doc) => HelpRequest.fromMap(doc.data(), id: doc.id))
        .toList();
    results.sort((a, b) =>
        (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    return results;
  }

  /// Stream senior's requests for real-time updates
  Stream<List<HelpRequest>> streamSeniorRequests(String seniorId) {
    // Query by seniorId only (no orderBy) to avoid requiring a composite index.
    // Sort client-side; dataset is small (limit 20).
    return _firestore
        .collection(AppConstants.requestsCollection)
        .where('seniorId', isEqualTo: seniorId)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          final results = snapshot.docs
              .map((doc) => HelpRequest.fromMap(doc.data(), id: doc.id))
              .toList();
          results.sort((a, b) =>
              (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
          return results;
        });
  }

  /// Get all family members linked to a senior
  Future<List<AppUser>> getFamilyMembers(String seniorId) async {
    // Query by linkedSeniorId only; filter role client-side to avoid composite index.
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('linkedSeniorId', isEqualTo: seniorId)
        .get();

    return snapshot.docs
        .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
        .where((u) => u.role == 'family')
        .toList();
  }
}

/// Family repository provider
final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FamilyRepository(firestoreService);
});
