import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../domain/entities/activity_log.dart';

/// Repository for managing activity logs
class ActivityRepository {
  final FirestoreService _firestoreService;

  ActivityRepository(this._firestoreService);

  /// Create activity log
  Future<String> createActivityLog(ActivityLog activity) async {
    try {
      final docRef = await _firestoreService.add(
        'activities',
        activity.toMap(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create activity log: $e');
    }
  }

  /// Stream activities for a specific senior (for family members to view)
  Stream<List<ActivityLog>> streamActivitiesForSenior(String seniorId) {
    return _firestoreService
        .streamCollection(
          'activities',
          filters: [QueryFilter(field: 'seniorId', isEqualTo: seniorId)],
          orderBy: 'timestamp',
          descending: true,
          limit: 50,
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityLog.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream activities for family member (shows activities of their linked senior)
  Stream<List<ActivityLog>> streamActivitiesForFamily(String linkedSeniorId) {
    return streamActivitiesForSenior(linkedSeniorId);
  }

  /// Get recent activities
  Future<List<ActivityLog>> getRecentActivities(String seniorId, {int limit = 20}) async {
    try {
      final snapshot = await _firestoreService.query(
        'activities',
        filters: [QueryFilter(field: 'seniorId', isEqualTo: seniorId)],
        orderBy: 'timestamp',
        descending: true,
        limit: limit,
      );

      return snapshot.docs
          .map((doc) => ActivityLog.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get activities: $e');
    }
  }

  /// Delete old activities (cleanup - older than 90 days)
  Future<void> deleteOldActivities() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      final snapshot = await FirebaseFirestore.instance
          .collection('activities')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete old activities: $e');
    }
  }
}

/// Activity repository provider
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ActivityRepository(firestoreService);
});
