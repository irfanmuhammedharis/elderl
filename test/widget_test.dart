import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Note: Full widget tests with Firebase require firebase_core mocking.
// These are simplified unit tests for widget components.

void main() {
  group('Widget Unit Tests', () {
    testWidgets('MaterialApp can be created with basic configuration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          title: 'Elder Care',
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            appBar: AppBar(title: const Text('Elder Care')),
            body: const Center(child: Text('Welcome')),
          ),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Elder Care'), findsOneWidget);
      expect(find.text('Welcome'), findsOneWidget);
    });

    testWidgets('Large button renders correctly for accessibility', (
      WidgetTester tester,
    ) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 80,
                child: ElevatedButton(
                  onPressed: () => wasPressed = true,
                  child: const Text(
                    'Emergency',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Emergency'), findsOneWidget);
      await tester.tap(find.text('Emergency'));
      expect(wasPressed, isTrue);
    });

    testWidgets('Form validation works correctly', (
      WidgetTester tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      String? email;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!value.contains('@')) {
                        return 'Invalid email';
                      }
                      return null;
                    },
                    onSaved: (value) => email = value,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Test empty validation
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(find.text('Please enter email'), findsOneWidget);

      // Test invalid email
      await tester.enterText(find.byType(TextFormField), 'invalid');
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(find.text('Invalid email'), findsOneWidget);

      // Test valid email
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(find.text('Please enter email'), findsNothing);
      expect(find.text('Invalid email'), findsNothing);
      expect(email, 'test@example.com');
    });

    testWidgets('Card component displays correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('Senior Name'),
                subtitle: Text('Last check-in: Today'),
                trailing: Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Senior Name'), findsOneWidget);
      expect(find.text('Last check-in: Today'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Emergency button has large touch target for seniors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(200, 200),
                  ),
                  onPressed: () {},
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning, size: 64, color: Colors.white),
                      SizedBox(height: 8),
                      Text('EMERGENCY', style: TextStyle(fontSize: 24, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('EMERGENCY'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
      
      // Verify the button is large enough for elderly users
      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);
      final buttonSize = tester.getSize(buttonFinder);
      expect(buttonSize.width, greaterThanOrEqualTo(200));
      expect(buttonSize.height, greaterThanOrEqualTo(200));
    });

    testWidgets('Status indicator shows different states', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud_done, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Synced'),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Offline'),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.sync, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Syncing...'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Synced'), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Syncing...'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('Password field obscures text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    suffixIcon: Icon(Icons.visibility_off),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Password'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      
      // Enter text and verify it's rendered (but obscured in the widget)
      await tester.enterText(find.byType(TextFormField), 'SecretPass123');
      await tester.pump();
      // The text exists in the editing controller even though displayed as dots
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, true);
    });

    testWidgets('Role selection dropdown renders options', (
      WidgetTester tester,
    ) async {
      String selectedRole = 'senior';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DropdownButton<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'senior', child: Text('Senior/Elderly')),
                    DropdownMenuItem(value: 'caregiver', child: Text('Caregiver')),
                    DropdownMenuItem(value: 'family', child: Text('Family Member')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedRole = value!);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Initially shows Senior/Elderly
      expect(find.text('Senior/Elderly'), findsOneWidget);

      // Open dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // All options visible
      expect(find.text('Senior/Elderly'), findsWidgets);
      expect(find.text('Caregiver'), findsOneWidget);
      expect(find.text('Family Member'), findsOneWidget);
    });

    testWidgets('Check-in status badge renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Chip(
                  avatar: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  label: const Text('Checked In'),
                  backgroundColor: Colors.green.shade50,
                ),
                Chip(
                  avatar: const Icon(Icons.warning, color: Colors.orange, size: 18),
                  label: const Text('Missed'),
                  backgroundColor: Colors.orange.shade50,
                ),
                Chip(
                  avatar: const Icon(Icons.schedule, color: Colors.grey, size: 18),
                  label: const Text('Pending'),
                  backgroundColor: Colors.grey.shade200,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Checked In'), findsOneWidget);
      expect(find.text('Missed'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.byType(Chip), findsNWidgets(3));
    });

    testWidgets('Request type icons render correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ListTile(leading: Icon(Icons.medical_services), title: Text('Medical')),
                ListTile(leading: Icon(Icons.restaurant), title: Text('Food')),
                ListTile(leading: Icon(Icons.directions_car), title: Text('Transport')),
                ListTile(leading: Icon(Icons.people), title: Text('Companion')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Medical'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Companion'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(4));
    });

    testWidgets('Loading indicator shows during async operations', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('User info card displays profile details', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          child: Icon(Icons.person, size: 30),
                        ),
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('John Doe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('senior@example.com'),
                            Text('Senior/Elderly'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: const Text('Approved'),
                      backgroundColor: Colors.green.shade100,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('senior@example.com'), findsOneWidget);
      expect(find.text('Senior/Elderly'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });
  });
}
