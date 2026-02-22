import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/user_repository.dart';

/// Background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[NotificationService] Background message: ${message.messageId}');
}

/// Notification payload model for in-app alerts
class InAppAlert {
  final String id;
  final String title;
  final String body;
  final String type; // 'request', 'emergency', 'message'
  final Map<String, dynamic>? data;
  final DateTime receivedAt;

  InAppAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();
}

/// Central notification service
/// Handles FCM setup, token management, foreground messages, and
/// real-time RTDB-based request alert streaming for caregivers.
class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseDatabase _database;

  /// Stream controller for in-app alerts (foreground notifications)
  final _alertController = StreamController<InAppAlert>.broadcast();

  /// Public stream that UI widgets listen to for in-app banners
  Stream<InAppAlert> get alertStream => _alertController.stream;

  /// RTDB subscription for new request alerts
  StreamSubscription<DatabaseEvent>? _requestAlertSub;

  NotificationService(this._messaging, this._database);

  // ─────────── INITIALIZATION ───────────

  /// Initialize FCM, request permissions, set up foreground listener.
  /// Call once from main.dart after Firebase.initializeApp().
  Future<void> initialize() async {
    // 1. Request permission (iOS/macOS/web require explicit ask)
    await _requestPermission();

    // 2. Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 4. Handle notification tap (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 5. Check if app was opened by a notification while terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    debugPrint('[NotificationService] Initialized');
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[NotificationService] Permission: ${settings.authorizationStatus}');
  }

  // ─────────── TOKEN MANAGEMENT ───────────

  /// Get the current FCM token and save it to Firestore user doc.
  /// Should be called after successful login.
  Future<String?> getAndSaveToken(String userId, UserRepository userRepo) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await userRepo.updateFcmToken(userId, token);
        debugPrint('[NotificationService] Token saved for $userId');
      }

      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) async {
        await userRepo.updateFcmToken(userId, newToken);
        debugPrint('[NotificationService] Token refreshed for $userId');
      });

      return token;
    } catch (e) {
      debugPrint('[NotificationService] Token error: $e');
      return null;
    }
  }

  // ─────────── FOREGROUND MESSAGES ───────────

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[NotificationService] Foreground: ${message.notification?.title}');

    final notification = message.notification;
    if (notification != null) {
      _alertController.add(InAppAlert(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        type: message.data['type'] ?? 'general',
        data: message.data,
      ));
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[NotificationService] Tapped: ${message.data}');
    // Navigation can be handled via a global navigator key or GoRouter
    // For now, the app will just open to the home screen
  }

  // ─────────── RTDB REQUEST ALERT STREAM ───────────

  /// Start listening for new pending request alerts via RTDB.
  /// This gives ~200ms latency vs Firestore's ~1-3s.
  /// Call when caregiver logs in.
  void startRequestAlertStream() {
    _requestAlertSub?.cancel();

    final ref = _database.ref('pending_request_alerts');

    // Record the time when the listener starts so we only alert on NEW entries,
    // not the entire existing history that onChildAdded replays.
    final listenStartTime = DateTime.now().millisecondsSinceEpoch;

    _requestAlertSub = ref.onChildAdded.listen((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return;

      final map = Map<String, dynamic>.from(data);

      // Skip historical alerts created before this listener started
      final alertCreatedAt = map['createdAt'];
      if (alertCreatedAt is int && alertCreatedAt < listenStartTime) {
        return;
      }

      _alertController.add(InAppAlert(
        id: event.snapshot.key ?? '',
        title: 'New Help Request',
        body: '${map['seniorName'] ?? 'A senior'} needs ${map['type'] ?? 'help'}',
        type: 'request',
        data: map,
      ));

      debugPrint('[NotificationService] RTDB alert: ${event.snapshot.key}');
    });

    debugPrint('[NotificationService] Request alert stream started');
  }

  /// Stop listening (call on logout or when caregiver leaves).
  void stopRequestAlertStream() {
    _requestAlertSub?.cancel();
    _requestAlertSub = null;
    debugPrint('[NotificationService] Request alert stream stopped');
  }

  // ─────────── CLEANUP ───────────

  void dispose() {
    stopRequestAlertStream();
    _alertController.close();
  }
}

// ─────────── PROVIDERS ───────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final database = FirebaseDatabase.instance;
  final messaging = FirebaseMessaging.instance;
  return NotificationService(messaging, database);
});
