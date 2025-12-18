/// Application constants
/// Contains all constant values used across the app
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // API Configuration
  static const String baseUrl = 'https://api.example.com';
  static const int apiTimeout = 30; // seconds

  // App Info
  static const String appName = 'ElderL';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyFirstLaunch = 'first_launch';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // UI Constants
  static const double defaultPadding = 16;
  static const double smallPadding = 8;
  static const double largePadding = 24;
  static const double defaultBorderRadius = 8;

  // Animation Durations
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 400);
  static const Duration longDuration = Duration(milliseconds: 600);
}

/// Route names for navigation
class RouteNames {
  RouteNames._();

  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

/// Asset paths
class AssetPaths {
  AssetPaths._();

  // Images
  static const String imagesPath = 'assets/images';
  static const String logo = '$imagesPath/logo.png';
  static const String placeholder = '$imagesPath/placeholder.png';

  // Icons
  static const String iconsPath = 'assets/icons';
}
