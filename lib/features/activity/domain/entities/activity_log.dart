import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of activities that can be logged
enum ActivityType {
  requestCreated,
  requestAccepted,
  requestCompleted,
  requestCancelled,
  checkinCreated,
  messagesSent,
  emergencyTriggered,
  emergencyResolved,
}

/// Activity log entity for tracking senior-caregiver interactions
class ActivityLog {
  final String id;
  final String seniorId;
  final String seniorName;
  final String? caregiverId;
  final String? caregiverName;
  final ActivityType activityType;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? requestId;
  final String? checkinId;
  final Map<String, dynamic>? metadata;

  ActivityLog({
    required this.id,
    required this.seniorId,
    required this.seniorName,
    this.caregiverId,
    this.caregiverName,
    required this.activityType,
    required this.title,
    required this.description,
    required this.timestamp,
    this.requestId,
    this.checkinId,
    this.metadata,
  });

  /// Convert ActivityType to string
  static String activityTypeToString(ActivityType type) {
    switch (type) {
      case ActivityType.requestCreated:
        return 'request_created';
      case ActivityType.requestAccepted:
        return 'request_accepted';
      case ActivityType.requestCompleted:
        return 'request_completed';
      case ActivityType.requestCancelled:
        return 'request_cancelled';
      case ActivityType.checkinCreated:
        return 'checkin_created';
      case ActivityType.messagesSent:
        return 'messages_sent';
      case ActivityType.emergencyTriggered:
        return 'emergency_triggered';
      case ActivityType.emergencyResolved:
        return 'emergency_resolved';
    }
  }

  /// Parse string to ActivityType
  static ActivityType parseActivityType(String? type) {
    switch (type) {
      case 'request_created':
        return ActivityType.requestCreated;
      case 'request_accepted':
        return ActivityType.requestAccepted;
      case 'request_completed':
        return ActivityType.requestCompleted;
      case 'request_cancelled':
        return ActivityType.requestCancelled;
      case 'checkin_created':
        return ActivityType.checkinCreated;
      case 'messages_sent':
        return ActivityType.messagesSent;
      case 'emergency_triggered':
        return ActivityType.emergencyTriggered;
      case 'emergency_resolved':
        return ActivityType.emergencyResolved;
      default:
        return ActivityType.requestCreated;
    }
  }

  /// Create ActivityLog from Firestore document
  factory ActivityLog.fromMap(Map<String, dynamic> map, String id) {
    return ActivityLog(
      id: id,
      seniorId: map['seniorId'] as String? ?? '',
      seniorName: map['seniorName'] as String? ?? '',
      caregiverId: map['caregiverId'] as String?,
      caregiverName: map['caregiverName'] as String?,
      activityType: parseActivityType(map['activityType'] as String?),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      requestId: map['requestId'] as String?,
      checkinId: map['checkinId'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'seniorId': seniorId,
      'seniorName': seniorName,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'activityType': activityTypeToString(activityType),
      'title': title,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'requestId': requestId,
      'checkinId': checkinId,
      'metadata': metadata,
    };
  }

  /// Copy with method
  ActivityLog copyWith({
    String? id,
    String? seniorId,
    String? seniorName,
    String? caregiverId,
    String? caregiverName,
    ActivityType? activityType,
    String? title,
    String? description,
    DateTime? timestamp,
    String? requestId,
    String? checkinId,
    Map<String, dynamic>? metadata,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      seniorId: seniorId ?? this.seniorId,
      seniorName: seniorName ?? this.seniorName,
      caregiverId: caregiverId ?? this.caregiverId,
      caregiverName: caregiverName ?? this.caregiverName,
      activityType: activityType ?? this.activityType,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      requestId: requestId ?? this.requestId,
      checkinId: checkinId ?? this.checkinId,
      metadata: metadata ?? this.metadata,
    );
  }
}
