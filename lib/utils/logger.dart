import 'package:flutter/foundation.dart';

/// Logger utility for consistent logging across the app
/// Only logs in debug mode
class Logger {
  Logger._();

  static const String _tag = 'ElderL';

  /// Log info message
  static void info(String message) {
    if (kDebugMode) {
      print('[$_tag] INFO: $message');
    }
  }

  /// Log warning message
  static void warning(String message) {
    if (kDebugMode) {
      print('[$_tag] WARNING: $message');
    }
  }

  /// Log error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('[$_tag] ERROR: $message');
      if (error != null) {
        print('[$_tag] EXCEPTION: $error');
      }
      if (stackTrace != null) {
        print('[$_tag] STACK TRACE: $stackTrace');
      }
    }
  }

  /// Log debug message
  static void debug(String message) {
    if (kDebugMode) {
      print('[$_tag] DEBUG: $message');
    }
  }

  /// Log API request
  static void apiRequest(String method, String url, [Map<String, dynamic>? body]) {
    if (kDebugMode) {
      print('[$_tag] API REQUEST: $method $url');
      if (body != null) {
        print('[$_tag] BODY: $body');
      }
    }
  }

  /// Log API response
  static void apiResponse(int statusCode, String url, [body]) {
    if (kDebugMode) {
      print('[$_tag] API RESPONSE: $statusCode $url');
      if (body != null) {
        print('[$_tag] RESPONSE BODY: $body');
      }
    }
  }
}
