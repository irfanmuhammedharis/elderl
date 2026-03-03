/// Application constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'ElderL';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Senior Citizen Assistance App';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String profilesCollection = 'profiles';
  static const String requestsCollection = 'requests';
  static const String checkinsCollection = 'checkins';
  static const String emergenciesCollection = 'emergencies';
  static const String messagesCollection = 'messages';

  // User Roles
  static const String roleSenior = 'senior';
  static const String roleCaregiver = 'caregiver';
  static const String roleFamily = 'family';
  static const String roleAdmin = 'admin';

  // Request Types
  static const String requestMedical = 'medical';
  static const String requestFood = 'food';
  static const String requestTransport = 'transport';
  static const String requestCompanion = 'companion';

  // Request Status
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Check-in Status
  static const String checkinOk = 'ok';
  static const String checkinMissed = 'missed';
  static const String checkinPending = 'pending';

  // Storage Keys
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyFcmToken = 'fcm_token';
  static const String keyLastCheckin = 'last_checkin';
  static const String keyThemeMode = 'theme_mode';

  // Timeouts
  static const Duration checkInReminder = Duration(hours: 12);
  static const Duration emergencyTimeout = Duration(minutes: 5);
}
