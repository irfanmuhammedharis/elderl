import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/domain/entities/app_user.dart';

/// Repository for managing user links (senior-caregiver-family relationships)
class LinkingRepository {
  final FirestoreService _firestoreService;

  LinkingRepository(this._firestoreService);

  /// Link a caregiver to a senior
  Future<void> linkCaregiver(String seniorId, String caregiverId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Update senior's assignedCaregivers list
      final seniorRef = FirebaseFirestore.instance.collection('users').doc(seniorId);
      batch.update(seniorRef, {
        'assignedCaregivers': FieldValue.arrayUnion([caregiverId]),
      });

      // Update caregiver's assignedSeniors list
      final caregiverRef = FirebaseFirestore.instance.collection('users').doc(caregiverId);
      batch.update(caregiverRef, {
        'assignedSeniors': FieldValue.arrayUnion([seniorId]),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to link caregiver: $e');
    }
  }

  /// Link a family member to a senior
  Future<void> linkFamilyMember(String seniorId, String familyId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Update senior's linkedFamily list
      final seniorRef = FirebaseFirestore.instance.collection('users').doc(seniorId);
      batch.update(seniorRef, {
        'linkedFamily': FieldValue.arrayUnion([familyId]),
      });

      // Update family member's linkedSeniorId
      final familyRef = FirebaseFirestore.instance.collection('users').doc(familyId);
      batch.update(familyRef, {
        'linkedSeniorId': seniorId,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to link family member: $e');
    }
  }

  /// Unlink caregiver from senior
  Future<void> unlinkCaregiver(String seniorId, String caregiverId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      final seniorRef = FirebaseFirestore.instance.collection('users').doc(seniorId);
      batch.update(seniorRef, {
        'assignedCaregivers': FieldValue.arrayRemove([caregiverId]),
      });

      final caregiverRef = FirebaseFirestore.instance.collection('users').doc(caregiverId);
      batch.update(caregiverRef, {
        'assignedSeniors': FieldValue.arrayRemove([seniorId]),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to unlink caregiver: $e');
    }
  }

  /// Unlink family member from senior
  Future<void> unlinkFamilyMember(String seniorId, String familyId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      final seniorRef = FirebaseFirestore.instance.collection('users').doc(seniorId);
      batch.update(seniorRef, {
        'linkedFamily': FieldValue.arrayRemove([familyId]),
      });

      final familyRef = FirebaseFirestore.instance.collection('users').doc(familyId);
      batch.update(familyRef, {
        'linkedSeniorId': FieldValue.delete(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to unlink family member: $e');
    }
  }

  /// Get linked caregivers for a senior
  Future<List<AppUser>> getLinkedCaregivers(String seniorId) async {
    try {
      final seniorDoc = await _firestoreService.get('users', seniorId);
      if (!seniorDoc.exists || seniorDoc.data() == null) {
        return [];
      }

      final seniorData = seniorDoc.data()!;
      final caregiverIds = (seniorData['assignedCaregivers'] as List<dynamic>?)
          ?.cast<String>() ?? [];

      if (caregiverIds.isEmpty) return [];

      final caregivers = <AppUser>[];
      for (var id in caregiverIds) {
        final doc = await _firestoreService.get('users', id);
        if (doc.exists && doc.data() != null) {
          caregivers.add(AppUser.fromMap({...doc.data()!, 'uid': doc.id}));
        }
      }

      return caregivers;
    } catch (e) {
      throw Exception('Failed to get linked caregivers: $e');
    }
  }

  /// Get linked family members for a senior
  Future<List<AppUser>> getLinkedFamily(String seniorId) async {
    try {
      final seniorDoc = await _firestoreService.get('users', seniorId);
      if (!seniorDoc.exists || seniorDoc.data() == null) {
        return [];
      }

      final seniorData = seniorDoc.data()!;
      final familyIds = (seniorData['linkedFamily'] as List<dynamic>?)
          ?.cast<String>() ?? [];

      if (familyIds.isEmpty) return [];

      final family = <AppUser>[];
      for (var id in familyIds) {
        final doc = await _firestoreService.get('users', id);
        if (doc.exists && doc.data() != null) {
          family.add(AppUser.fromMap({...doc.data()!, 'uid': doc.id}));
        }
      }

      return family;
    } catch (e) {
      throw Exception('Failed to get linked family: $e');
    }
  }

  /// Get ALL linked users (caregivers + family) for a senior
  Future<List<AppUser>> getAllLinkedUsers(String seniorId) async {
    try {
      final caregivers = await getLinkedCaregivers(seniorId);
      final family = await getLinkedFamily(seniorId);
      return [...caregivers, ...family];
    } catch (e) {
      throw Exception('Failed to get linked users: $e');
    }
  }

  /// Validate that senior has minimum required links (1 caregiver + 2 family)
  Future<bool> validateMinimumLinks(String seniorId) async {
    try {
      final caregivers = await getLinkedCaregivers(seniorId);
      final family = await getLinkedFamily(seniorId);
      
      return caregivers.isNotEmpty && family.length >= 2;
    } catch (e) {
      return false;
    }
  }

  /// Get linking status for a senior
  Future<Map<String, dynamic>> getLinkingStatus(String seniorId) async {
    try {
      final caregivers = await getLinkedCaregivers(seniorId);
      final family = await getLinkedFamily(seniorId);
      
      return {
        'hasSufficientLinks': caregivers.isNotEmpty && family.length >= 2,
        'caregiverCount': caregivers.length,
        'familyCount': family.length,
        'requiresMoreCaregivers': caregivers.isEmpty,
        'requiresMoreFamily': family.length < 2,
        'caregivers': caregivers,
        'family': family,
      };
    } catch (e) {
      throw Exception('Failed to get linking status: $e');
    }
  }

  /// Get available caregivers (approved caregivers not yet linked to this senior)
  Future<List<AppUser>> getAvailableCaregivers(String seniorId) async {
    try {
      // Get all approved caregivers
      final snapshot = await _firestoreService.query(
        'users',
        filters: [
          QueryFilter(field: 'role', isEqualTo: 'caregiver'),
          QueryFilter(field: 'approvalStatus', isEqualTo: 'approved'),
        ],
      );

      final allCaregivers = snapshot.docs
          .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
          .toList();

      // Get currently linked caregivers
      final linked = await getLinkedCaregivers(seniorId);
      final linkedIds = linked.map((c) => c.uid).toSet();

      // Filter out already linked caregivers
      return allCaregivers.where((c) => !linkedIds.contains(c.uid)).toList();
    } catch (e) {
      throw Exception('Failed to get available caregivers: $e');
    }
  }

  /// Get available family members (approved family not yet linked to this senior)
  Future<List<AppUser>> getAvailableFamily(String seniorId) async {
    try {
      // Get all approved family members
      final snapshot = await _firestoreService.query(
        'users',
        filters: [
          QueryFilter(field: 'role', isEqualTo: 'family'),
          QueryFilter(field: 'approvalStatus', isEqualTo: 'approved'),
        ],
      );

      final allFamily = snapshot.docs
          .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
          .toList();

      // Get currently linked family
      final linked = await getLinkedFamily(seniorId);
      final linkedIds = linked.map((f) => f.uid).toSet();

      // Filter out already linked family members
      return allFamily.where((f) => !linkedIds.contains(f.uid)).toList();
    } catch (e) {
      throw Exception('Failed to get available family: $e');
    }
  }
}

/// Provider for linking repository
final linkingRepositoryProvider = Provider<LinkingRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return LinkingRepository(firestoreService);
});
