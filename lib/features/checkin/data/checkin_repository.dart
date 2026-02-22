import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/constants.dart';

/// Check-in model
class CheckIn {
  final String? id;
  final String seniorId;
  final String status;
  final String? message;
  final DateTime? checkinTime;
  final DateTime? createdAt;

  CheckIn({
    this.id,
    required this.seniorId,
    required this.status,
    this.message,
    this.checkinTime,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'seniorId': seniorId,
      'status': status,
      'message': message,
      'checkinTime': checkinTime != null ? Timestamp.fromDate(checkinTime!) : FieldValue.serverTimestamp(),
    };
  }

  factory CheckIn.fromMap(Map<String, dynamic> map, {String? id}) {
    return CheckIn(
      id: id,
      seniorId: map['seniorId'] ?? '',
      status: map['status'] ?? AppConstants.checkinPending,
      message: map['message'],
      checkinTime: _parseTimestamp(map['checkinTime']),
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  /// Helper to parse timestamp that could be either Timestamp or String
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}

/// Check-in repository for Firestore operations
class CheckInRepository {
  final FirestoreService _firestoreService;

  CheckInRepository(this._firestoreService);

  /// Create a new check-in
  Future<String> createCheckIn(CheckIn checkin) async {
    final docRef = await _firestoreService.add(
      AppConstants.checkinsCollection,
      checkin.toMap(),
    );
    return docRef.id;
  }

  /// Get today's check-in for a senior
  Future<CheckIn?> getTodayCheckIn(String seniorId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestoreService.query(
      AppConstants.checkinsCollection,
      filters: [
        QueryFilter(field: 'seniorId', isEqualTo: seniorId),
        QueryFilter(field: 'checkinTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay)),
        QueryFilter(field: 'checkinTime', isLessThan: Timestamp.fromDate(endOfDay)),
      ],
      orderBy: 'checkinTime',
      descending: true,
      limit: 1,
    );

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return CheckIn.fromMap(snapshot.docs.first.data(), id: snapshot.docs.first.id);
  }

  /// Get check-in history for a senior
  Future<List<CheckIn>> getCheckInHistory(String seniorId, {int limit = 30}) async {
    final snapshot = await _firestoreService.query(
      AppConstants.checkinsCollection,
      filters: [QueryFilter(field: 'seniorId', isEqualTo: seniorId)],
      orderBy: 'checkinTime',
      descending: true,
      limit: limit,
    );

    return snapshot.docs
        .map((doc) => CheckIn.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  /// Stream today's check-in for a senior
  Stream<CheckIn?> streamTodayCheckIn(String seniorId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestoreService
        .streamCollection(
          AppConstants.checkinsCollection,
          filters: [
            QueryFilter(field: 'seniorId', isEqualTo: seniorId),
            QueryFilter(field: 'checkinTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay)),
            QueryFilter(field: 'checkinTime', isLessThan: Timestamp.fromDate(endOfDay)),
          ],
          orderBy: 'checkinTime',
          descending: true,
          limit: 1,
        )
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return CheckIn.fromMap(snapshot.docs.first.data(), id: snapshot.docs.first.id);
    });
  }

  /// Get missed check-ins (seniors who haven't checked in today)
  Future<List<String>> getMissedCheckIns(List<String> seniorIds) async {
    final missedIds = <String>[];
    
    for (final seniorId in seniorIds) {
      final todayCheckIn = await getTodayCheckIn(seniorId);
      if (todayCheckIn == null) {
        missedIds.add(seniorId);
      }
    }
    
    return missedIds;
  }
}

/// Check-in repository provider
final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return CheckInRepository(firestoreService);
});

/// Stream provider for today's check-in
final todayCheckInStreamProvider = StreamProvider.family<CheckIn?, String>((ref, seniorId) {
  final repo = ref.watch(checkInRepositoryProvider);
  return repo.streamTodayCheckIn(seniorId);
});

/// Stream provider for check-in history
final checkInHistoryProvider = FutureProvider.family<List<CheckIn>, String>((ref, seniorId) {
  final repo = ref.watch(checkInRepositoryProvider);
  return repo.getCheckInHistory(seniorId);
});
