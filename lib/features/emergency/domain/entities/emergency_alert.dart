import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of emergency alert
enum EmergencyStatus {
  active,
  resolved,
  cancelled,
}

/// Emergency alert entity
class EmergencyAlert {
  final String id;
  final String seniorId;
  final String seniorName;
  final String? seniorPhone;
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime timestamp;
  final EmergencyStatus status;
  final List<String> notifiedUsers;
  final String? resolvedBy;
  final String? resolvedByName;
  final DateTime? resolvedAt;
  final String? notes;

  EmergencyAlert({
    required this.id,
    required this.seniorId,
    required this.seniorName,
    this.seniorPhone,
    this.latitude,
    this.longitude,
    this.address,
    required this.timestamp,
    required this.status,
    required this.notifiedUsers,
    this.resolvedBy,
    this.resolvedByName,
    this.resolvedAt,
    this.notes,
  });

  /// Convert EmergencyStatus to string
  static String statusToString(EmergencyStatus status) {
    switch (status) {
      case EmergencyStatus.active:
        return 'active';
      case EmergencyStatus.resolved:
        return 'resolved';
      case EmergencyStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Parse string to EmergencyStatus
  static EmergencyStatus parseStatus(String? status) {
    switch (status) {
      case 'active':
        return EmergencyStatus.active;
      case 'resolved':
        return EmergencyStatus.resolved;
      case 'cancelled':
        return EmergencyStatus.cancelled;
      default:
        return EmergencyStatus.active;
    }
  }

  /// Create from Firestore document
  factory EmergencyAlert.fromMap(Map<String, dynamic> map, String id) {
    return EmergencyAlert(
      id: id,
      seniorId: map['seniorId'] as String? ?? '',
      seniorName: map['seniorName'] as String? ?? '',
      seniorPhone: map['seniorPhone'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      address: map['address'] as String?,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: parseStatus(map['status'] as String?),
      notifiedUsers: (map['notifiedUsers'] as List<dynamic>?)?.cast<String>() ?? [],
      resolvedBy: map['resolvedBy'] as String?,
      resolvedByName: map['resolvedByName'] as String?,
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      notes: map['notes'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'seniorId': seniorId,
      'seniorName': seniorName,
      'seniorPhone': seniorPhone,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': statusToString(status),
      'notifiedUsers': notifiedUsers,
      'resolvedBy': resolvedBy,
      'resolvedByName': resolvedByName,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'notes': notes,
    };
  }

  /// Copy with method
  EmergencyAlert copyWith({
    String? id,
    String? seniorId,
    String? seniorName,
    String? seniorPhone,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? timestamp,
    EmergencyStatus? status,
    List<String>? notifiedUsers,
    String? resolvedBy,
    String? resolvedByName,
    DateTime? resolvedAt,
    String? notes,
  }) {
    return EmergencyAlert(
      id: id ?? this.id,
      seniorId: seniorId ?? this.seniorId,
      seniorName: seniorName ?? this.seniorName,
      seniorPhone: seniorPhone ?? this.seniorPhone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      notifiedUsers: notifiedUsers ?? this.notifiedUsers,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedByName: resolvedByName ?? this.resolvedByName,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      notes: notes ?? this.notes,
    );
  }

  /// Get time elapsed since alert
  String getTimeElapsed() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Check if alert is still active
  bool get isActive => status == EmergencyStatus.active;
}
