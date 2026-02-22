import 'package:cloud_firestore/cloud_firestore.dart';

/// Approval status for users
enum ApprovalStatus {
  pending,
  approved,
  rejected,
}

/// User entity representing app users
class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role; // senior, caregiver, family, admin
  final String? phone;
  final String? address;
  final String? avatarUrl;
  final String? fcmToken;
  final String? linkedSeniorId; // For family members - links to one senior
  final List<String>? linkedFamily; // For seniors - list of family member IDs
  final List<String>? assignedSeniors; // For caregivers - seniors they manage
  final List<String>?
      assignedCaregivers; // For seniors - caregivers assigned to them
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final DateTime? lastLogin;

  // Approval fields
  final ApprovalStatus approvalStatus;
  final String? approvedBy; // Admin UID who approved
  final DateTime? approvedAt;
  final String? rejectionReason;

  // Additional profile fields
  final DateTime? dateOfBirth;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? medicalConditions;
  final String? bloodType;
  final String? allergies;
  final String? notes;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.address,
    this.avatarUrl,
    this.fcmToken,
    this.linkedSeniorId,
    this.linkedFamily,
    this.assignedSeniors,
    this.assignedCaregivers,
    this.createdAt,
    this.lastActiveAt,
    this.lastLogin,
    this.approvalStatus = ApprovalStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.dateOfBirth,
    this.emergencyContact,
    this.emergencyPhone,
    this.medicalConditions,
    this.bloodType,
    this.allergies,
    this.notes,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String? ?? json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'senior',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      fcmToken: json['fcmToken'] as String?,
      linkedSeniorId: json['linkedSeniorId'] as String?,
      linkedFamily: (json['linkedFamily'] as List<dynamic>?)?.cast<String>(),
      assignedSeniors:
          (json['assignedSeniors'] as List<dynamic>?)?.cast<String>(),
      assignedCaregivers:
          (json['assignedCaregivers'] as List<dynamic>?)?.cast<String>(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
      approvalStatus: _parseApprovalStatus(json['approvalStatus'] as String?),
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      rejectionReason: json['rejectionReason'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      emergencyContact: json['emergencyContact'] as String?,
      emergencyPhone: json['emergencyPhone'] as String?,
      medicalConditions: json['medicalConditions'] as String?,
      bloodType: json['bloodType'] as String?,
      allergies: json['allergies'] as String?,
      notes: json['notes'] as String?,
    );
  }

  static ApprovalStatus _parseApprovalStatus(String? status) {
    switch (status) {
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      default:
        return ApprovalStatus.pending;
    }
  }

  static String _approvalStatusToString(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.approved:
        return 'approved';
      case ApprovalStatus.rejected:
        return 'rejected';
      case ApprovalStatus.pending:
        return 'pending';
    }
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

  /// Factory constructor for Firestore documents
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? 'senior',
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      fcmToken: map['fcmToken'] as String?,
      linkedSeniorId: map['linkedSeniorId'] as String?,
      linkedFamily: (map['linkedFamily'] as List<dynamic>?)?.cast<String>(),
      assignedSeniors:
          (map['assignedSeniors'] as List<dynamic>?)?.cast<String>(),
      assignedCaregivers:
          (map['assignedCaregivers'] as List<dynamic>?)?.cast<String>(),
      createdAt: _parseTimestamp(map['createdAt']),
      lastActiveAt: _parseTimestamp(map['lastActiveAt']),
      lastLogin: _parseTimestamp(map['lastLogin']),
      approvalStatus: _parseApprovalStatus(map['approvalStatus'] as String?),
      approvedBy: map['approvedBy'] as String?,
      approvedAt: _parseTimestamp(map['approvedAt']),
      rejectionReason: map['rejectionReason'] as String?,
      dateOfBirth: _parseTimestamp(map['dateOfBirth']),
      emergencyContact: map['emergencyContact'] as String?,
      emergencyPhone: map['emergencyPhone'] as String?,
      medicalConditions: map['medicalConditions'] as String?,
      bloodType: map['bloodType'] as String?,
      allergies: map['allergies'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'address': address,
      'avatarUrl': avatarUrl,
      'fcmToken': fcmToken,
      'linkedSeniorId': linkedSeniorId,
      'linkedFamily': linkedFamily,
      'assignedSeniors': assignedSeniors,
      'assignedCaregivers': assignedCaregivers,
      'createdAt': createdAt?.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'approvalStatus': _approvalStatusToString(approvalStatus),
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'medicalConditions': medicalConditions,
      'bloodType': bloodType,
      'allergies': allergies,
      'notes': notes,
    };
  }

  /// Convert to Firestore map (with Timestamps)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'address': address,
      'avatarUrl': avatarUrl,
      'fcmToken': fcmToken,
      'linkedSeniorId': linkedSeniorId,
      'linkedFamily': linkedFamily,
      'assignedSeniors': assignedSeniors,
      'assignedCaregivers': assignedCaregivers,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'lastActiveAt':
          lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'approvalStatus': _approvalStatusToString(approvalStatus),
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'medicalConditions': medicalConditions,
      'bloodType': bloodType,
      'allergies': allergies,
      'notes': notes,
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? address,
    String? avatarUrl,
    String? fcmToken,
    String? linkedSeniorId,
    List<String>? linkedFamily,
    List<String>? assignedSeniors,
    List<String>? assignedCaregivers,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    DateTime? lastLogin,
    ApprovalStatus? approvalStatus,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? dateOfBirth,
    String? emergencyContact,
    String? emergencyPhone,
    String? medicalConditions,
    String? bloodType,
    String? allergies,
    String? notes,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      linkedSeniorId: linkedSeniorId ?? this.linkedSeniorId,
      linkedFamily: linkedFamily ?? this.linkedFamily,
      assignedSeniors: assignedSeniors ?? this.assignedSeniors,
      assignedCaregivers: assignedCaregivers ?? this.assignedCaregivers,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      lastLogin: lastLogin ?? this.lastLogin,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      notes: notes ?? this.notes,
    );
  }

  bool get isSenior => role == 'senior';
  bool get isCaregiver => role == 'caregiver';
  bool get isFamily => role == 'family';
  bool get isAdmin => role == 'admin';

  bool get isPending => approvalStatus == ApprovalStatus.pending;
  bool get isApproved => approvalStatus == ApprovalStatus.approved;
  bool get isRejected => approvalStatus == ApprovalStatus.rejected;

  /// Check if senior has linked family members
  bool get hasLinkedFamily => linkedFamily != null && linkedFamily!.isNotEmpty;

  /// Check if senior has assigned caregivers
  bool get hasAssignedCaregivers =>
      assignedCaregivers != null && assignedCaregivers!.isNotEmpty;

  /// Check if family member is linked to a senior
  bool get isLinkedToSenior =>
      linkedSeniorId != null && linkedSeniorId!.isNotEmpty;

  /// Check if caregiver has assigned seniors
  bool get hasAssignedSeniors =>
      assignedSeniors != null && assignedSeniors!.isNotEmpty;

  /// Get role display name
  String get roleDisplayName {
    switch (role) {
      case 'senior':
        return 'Senior/Elderly';
      case 'caregiver':
        return 'Caregiver';
      case 'family':
        return 'Family Member';
      case 'admin':
        return 'Administrator';
      default:
        return role;
    }
  }

  /// Get approval status display name
  String get approvalStatusDisplayName {
    switch (approvalStatus) {
      case ApprovalStatus.pending:
        return 'Pending Approval';
      case ApprovalStatus.approved:
        return 'Approved';
      case ApprovalStatus.rejected:
        return 'Rejected';
    }
  }
}
