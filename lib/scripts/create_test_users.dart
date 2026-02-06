// Script to create test users in Firebase
// Run from the webapp: Navigate to /admin/create-test-users
// Or use Firebase Console to add users directly

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Test user credentials for different roles
class TestUsers {
  // Admin Account
  static const adminEmail = 'admin@elderl.com';
  static const adminPassword = 'Admin@123';
  static const adminName = 'System Admin';

  // Senior Account
  static const seniorEmail = 'senior@elderl.com';
  static const seniorPassword = 'Senior@123';
  static const seniorName = 'John Smith';

  // Caregiver Account
  static const caregiverEmail = 'caregiver@elderl.com';
  static const caregiverPassword = 'Caregiver@123';
  static const caregiverName = 'Mary Johnson';

  // Family Account
  static const familyEmail = 'family@elderl.com';
  static const familyPassword = 'Family@123';
  static const familyName = 'Sarah Williams';
}

/// Create a test user in Firebase Auth and Firestore
Future<void> createTestUser({
  required String email,
  required String password,
  required String name,
  required String role,
}) async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  try {
    // Create Firebase Auth user
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      // Create Firestore user document
      await firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email,
        'name': name,
        'role': role,
        'phone': '+1234567890',
        'address': '123 Test Street',
        'approvalStatus': role == 'admin' ? 'approved' : 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✓ Created $role user: $email');
    }
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      print('⚠ User already exists: $email');
    } else {
      print('✗ Error creating $role user: ${e.message}');
    }
  }
}

/// Create all test users
Future<void> createAllTestUsers() async {
  print('Creating test users...\n');

  await createTestUser(
    email: TestUsers.adminEmail,
    password: TestUsers.adminPassword,
    name: TestUsers.adminName,
    role: 'admin',
  );

  await createTestUser(
    email: TestUsers.seniorEmail,
    password: TestUsers.seniorPassword,
    name: TestUsers.seniorName,
    role: 'senior',
  );

  await createTestUser(
    email: TestUsers.caregiverEmail,
    password: TestUsers.caregiverPassword,
    name: TestUsers.caregiverName,
    role: 'caregiver',
  );

  await createTestUser(
    email: TestUsers.familyEmail,
    password: TestUsers.familyPassword,
    name: TestUsers.familyName,
    role: 'family',
  );

  print('\n========================================');
  print('TEST ACCOUNTS CREATED:');
  print('========================================');
  print('Admin:     ${TestUsers.adminEmail} / ${TestUsers.adminPassword}');
  print('Senior:    ${TestUsers.seniorEmail} / ${TestUsers.seniorPassword}');
  print(
      'Caregiver: ${TestUsers.caregiverEmail} / ${TestUsers.caregiverPassword}');
  print('Family:    ${TestUsers.familyEmail} / ${TestUsers.familyPassword}');
  print('========================================');
}
