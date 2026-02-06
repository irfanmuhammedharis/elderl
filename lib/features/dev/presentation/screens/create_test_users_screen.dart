import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';

/// Screen to create test users for development/testing
class CreateTestUsersScreen extends StatefulWidget {
  const CreateTestUsersScreen({super.key});

  @override
  State<CreateTestUsersScreen> createState() => _CreateTestUsersScreenState();
}

class _CreateTestUsersScreenState extends State<CreateTestUsersScreen> {
  final List<String> _logs = [];
  bool _isCreating = false;
  bool _isDone = false;

  // Test user credentials - minimal data for approval testing
  static const _testUsers = [
    {
      'email': 'admin@elderl.com',
      'password': 'Admin@123',
      'name': 'Admin User',
      'role': 'admin',
    },
    {
      'email': 'senior@elderl.com',
      'password': 'Senior@123',
      'name': 'Senior User',
      'role': 'senior',
    },
    {
      'email': 'caregiver@elderl.com',
      'password': 'Caregiver@123',
      'name': 'Caregiver User',
      'role': 'caregiver',
    },
    {
      'email': 'family@elderl.com',
      'password': 'Family@123',
      'name': 'Family User',
      'role': 'family',
    },
  ];

  void _log(String message) {
    setState(() {
      _logs.add(message);
    });
  }

  Future<void> _createTestUsers() async {
    setState(() {
      _isCreating = true;
      _logs.clear();
    });

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    _log('Creating test users...\n');

    for (final userData in _testUsers) {
      final email = userData['email']!;
      final password = userData['password']!;
      final name = userData['name']!;
      final role = userData['role']!;

      try {
        // Create Firebase Auth user
        final credential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (credential.user != null) {
          // Create Firestore user document - only essential approval fields
          await firestore.collection('users').doc(credential.user!.uid).set({
            'uid': credential.user!.uid,
            'email': email,
            'name': name,
            'role': role,
            'approvalStatus': role == 'admin' ? 'approved' : 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

          _log('✓ Created $role: $email');
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          _log('⚠ Already exists: $email');
        } else {
          _log('✗ Error: ${e.message}');
        }
      } catch (e) {
        _log('✗ Error: $e');
      }
    }

    // Sign out after creating users
    await auth.signOut();

    _log('\n--- LOGIN CREDENTIALS ---');
    _log('Admin:     admin@elderl.com / Admin@123');
    _log('Senior:    senior@elderl.com / Senior@123');
    _log('Caregiver: caregiver@elderl.com / Caregiver@123');
    _log('Family:    family@elderl.com / Family@123');

    setState(() {
      _isCreating = false;
      _isDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Test Accounts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Create Button
                ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createTestUsers,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(
                      _isCreating ? 'Creating...' : 'Create Test Accounts'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 24),

                // Log Output
                if (_logs.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: _logs.map((log) {
                          Color? color;
                          if (log.startsWith('✓')) color = Colors.green;
                          if (log.startsWith('⚠')) color = Colors.orange;
                          if (log.startsWith('✗')) color = Colors.red;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              log,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: color,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                // Go to Login Button
                if (_isDone) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.login),
                    icon: const Icon(Icons.login),
                    label: const Text('Go to Login'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
