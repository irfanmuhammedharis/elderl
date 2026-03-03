import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/constants.dart';

/// Help request model
class HelpRequest {
  final String? id;
  final String seniorId;
  final String seniorName;
  final String type;
  final String description;
  final String status;
  final bool isUrgent;
  final String? assignedTo;
  final String? assignedToName;
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  HelpRequest({
    this.id,
    required this.seniorId,
    required this.seniorName,
    required this.type,
    required this.description,
    this.status = AppConstants.statusPending,
    this.isUrgent = false,
    this.assignedTo,
    this.assignedToName,
    this.latitude,
    this.longitude,
    this.address,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'seniorId': seniorId,
      'seniorName': seniorName,
      'type': type,
      'description': description,
      'status': status,
      'isUrgent': isUrgent,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  factory HelpRequest.fromMap(Map<String, dynamic> map, {String? id}) {
    return HelpRequest(
      id: id,
      seniorId: map['seniorId'] ?? '',
      seniorName: map['seniorName'] ?? '',
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? AppConstants.statusPending,
      isUrgent: map['isUrgent'] ?? false,
      assignedTo: map['assignedTo'],
      assignedToName: map['assignedToName'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      address: map['address'],
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
      completedAt: _parseDate(map['completedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  HelpRequest copyWith({
    String? id,
    String? seniorId,
    String? seniorName,
    String? type,
    String? description,
    String? status,
    bool? isUrgent,
    String? assignedTo,
    String? assignedToName,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return HelpRequest(
      id: id ?? this.id,
      seniorId: seniorId ?? this.seniorId,
      seniorName: seniorName ?? this.seniorName,
      type: type ?? this.type,
      description: description ?? this.description,
      status: status ?? this.status,
      isUrgent: isUrgent ?? this.isUrgent,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Request repository for Firestore operations
class RequestRepository {
  final FirestoreService _firestoreService;

  RequestRepository(this._firestoreService);

  /// Create a new help request with individual parameters
  Future<String> create({
    required String seniorId,
    required String seniorName,
    required String type,
    required String description,
    String? address,
    bool isUrgent = false,
    Map<String, dynamic>? location,
  }) async {
    final request = HelpRequest(
      seniorId: seniorId,
      seniorName: seniorName,
      type: type,
      description: description,
      address: address,
      latitude: location?['latitude'],
      longitude: location?['longitude'],
      status: AppConstants.statusPending,
      isUrgent: isUrgent,
    );
    return createRequest(request);
  }

  /// Create a new help request
  Future<String> createRequest(HelpRequest request) async {
    final docRef = await _firestoreService.add(
      AppConstants.requestsCollection,
      request.toMap(),
    );
    return docRef.id;
  }

  /// Get request by ID
  Future<HelpRequest?> getRequest(String requestId) async {
    final doc = await _firestoreService.get(AppConstants.requestsCollection, requestId);
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return HelpRequest.fromMap(doc.data()!, id: doc.id);
  }

  /// Update request status
  Future<void> updateRequestStatus(String requestId, String status) async {
    final updateData = <String, dynamic>{'status': status};
    if (status == AppConstants.statusCompleted) {
      updateData['completedAt'] = FieldValue.serverTimestamp();
    }
    await _firestoreService.update(AppConstants.requestsCollection, requestId, updateData);
  }

  /// Assign caregiver to request
  Future<void> assignRequest(String requestId, String caregiverId, String caregiverName) async {
    await _firestoreService.update(
      AppConstants.requestsCollection,
      requestId,
      {
        'assignedTo': caregiverId,
        'assignedToName': caregiverName,
        'status': AppConstants.statusAccepted,
      },
    );
  }

  /// Get requests for a senior
  Future<List<HelpRequest>> getRequestsForSenior(String seniorId, {String? status}) async {
    final filters = [QueryFilter(field: 'seniorId', isEqualTo: seniorId)];
    if (status != null) {
      filters.add(QueryFilter(field: 'status', isEqualTo: status));
    }

    final snapshot = await _firestoreService.query(
      AppConstants.requestsCollection,
      filters: filters,
      orderBy: 'createdAt',
      descending: true,
    );

    return snapshot.docs
        .map((doc) => HelpRequest.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  /// Get pending requests (for caregivers)
  Future<List<HelpRequest>> getPendingRequests() async {
    final snapshot = await _firestoreService.query(
      AppConstants.requestsCollection,
      filters: [QueryFilter(field: 'status', isEqualTo: AppConstants.statusPending)],
      orderBy: 'createdAt',
      descending: true,
    );

    return snapshot.docs
        .map((doc) => HelpRequest.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  /// Get assigned requests for a caregiver
  Future<List<HelpRequest>> getAssignedRequests(String caregiverId) async {
    final snapshot = await _firestoreService.query(
      AppConstants.requestsCollection,
      filters: [
        QueryFilter(field: 'assignedTo', isEqualTo: caregiverId),
        QueryFilter(field: 'status', whereIn: [
          AppConstants.statusAccepted,
          AppConstants.statusInProgress,
        ]),
      ],
      orderBy: 'createdAt',
      descending: true,
    );

    return snapshot.docs
        .map((doc) => HelpRequest.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  /// Stream requests for a senior
  Stream<List<HelpRequest>> streamRequestsForSenior(String seniorId) {
    return _firestoreService
        .streamCollection(
          AppConstants.requestsCollection,
          filters: [QueryFilter(field: 'seniorId', isEqualTo: seniorId)],
        )
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => HelpRequest.fromMap(doc.data(), id: doc.id))
              .toList();
          requests.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
          return requests;
        });
  }

  /// Stream pending requests (for caregivers)
  Stream<List<HelpRequest>> streamPendingRequests() {
    return _firestoreService
        .streamCollection(
          AppConstants.requestsCollection,
          filters: [QueryFilter(field: 'status', isEqualTo: AppConstants.statusPending)],
        )
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => HelpRequest.fromMap(doc.data(), id: doc.id))
              .toList();
          requests.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
          return requests;
        });
  }

  /// Cancel a request
  Future<void> cancelRequest(String requestId) async {
    await updateRequestStatus(requestId, AppConstants.statusCancelled);
  }

  /// Complete a request
  Future<void> completeRequest(String requestId) async {
    await updateRequestStatus(requestId, AppConstants.statusCompleted);
  }

  /// Stream all requests (for admin)
  Stream<List<HelpRequest>> streamAllRequests() {
    return _firestoreService
        .streamCollection(
          AppConstants.requestsCollection,
          orderBy: 'createdAt',
          descending: true,
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => HelpRequest.fromMap(doc.data(), id: doc.id))
            .toList());
  }
}

/// Request repository provider
final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return RequestRepository(firestoreService);
});
