import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (check if already initialized)
  // On some Android setups (especially after hot restart / previous process),
  // the native side may already have a DEFAULT app even if Dart thinks otherwise.
  // In that case Firebase throws [core/duplicate-app]. Treat it as non-fatal.
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      final message = e.toString();
      final isDuplicateDefaultApp =
          message.contains('[core/duplicate-app]') || message.contains('duplicate-app');
      if (!isDuplicateDefaultApp) {
        rethrow;
      }
    }
  }

  // Configure Firestore settings based on platform
  // Web and mobile have different persistence mechanisms
  if (kIsWeb) {
    // Web: Enable IndexedDB persistence with multi-tab synchronization
    // This ensures data syncs properly between browser tabs and with mobile apps
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    // Enable multi-tab IndexedDB persistence for web
    // This allows multiple browser tabs to share the same cache
    await FirebaseFirestore.instance.enablePersistence(
      const PersistenceSettings(synchronizeTabs: true),
    ).catchError((e) {
      // Persistence may already be enabled or not supported
      debugPrint('Firestore web persistence setup: $e');
    });
  } else {
    // Mobile (Android/iOS): Use native persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Configure Realtime Database for emergencies (lower latency)
  // Note: setPersistenceEnabled and keepSynced are not supported on web
  if (!kIsWeb) {
    try {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      // Keep emergencies synced for offline access
      FirebaseDatabase.instance.ref('active_emergencies').keepSynced(true);
    } catch (e) {
      // Realtime Database may not be configured - continue without it
      debugPrint('Realtime Database setup skipped: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: ElderLApp(),
    ),
  );
}

class ElderLApp extends ConsumerWidget {
  const ElderLApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    // Initialize sync service to monitor cross-platform data synchronization
    ref.watch(syncServiceProvider);

    return MaterialApp.router(
      title: 'ElderL - Senior Assistance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
