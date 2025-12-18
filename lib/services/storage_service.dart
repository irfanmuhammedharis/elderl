import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Local storage service using SharedPreferences
/// Handles persistent local data storage
class StorageService {
  factory StorageService() => _instance;
  StorageService._internal();
  static final StorageService _instance = StorageService._internal();

  SharedPreferences? _prefs;

  /// Initialize storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    Logger.info('StorageService initialized');
  }

  /// Get SharedPreferences instance
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StorageException('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // String operations
  Future<bool> setString(String key, String value) async {
    try {
      return await prefs.setString(key, value);
    } catch (e) {
      Logger.error('Failed to set string: $e');
      return false;
    }
  }

  String? getString(String key) {
    try {
      return prefs.getString(key);
    } catch (e) {
      Logger.error('Failed to get string: $e');
      return null;
    }
  }

  // Int operations
  Future<bool> setInt(String key, int value) async {
    try {
      return await prefs.setInt(key, value);
    } catch (e) {
      Logger.error('Failed to set int: $e');
      return false;
    }
  }

  int? getInt(String key) {
    try {
      return prefs.getInt(key);
    } catch (e) {
      Logger.error('Failed to get int: $e');
      return null;
    }
  }

  // Bool operations
  Future<bool> setBool(String key, bool value) async {
    try {
      return await prefs.setBool(key, value);
    } catch (e) {
      Logger.error('Failed to set bool: $e');
      return false;
    }
  }

  bool? getBool(String key) {
    try {
      return prefs.getBool(key);
    } catch (e) {
      Logger.error('Failed to get bool: $e');
      return null;
    }
  }

  // Double operations
  Future<bool> setDouble(String key, double value) async {
    try {
      return await prefs.setDouble(key, value);
    } catch (e) {
      Logger.error('Failed to set double: $e');
      return false;
    }
  }

  double? getDouble(String key) {
    try {
      return prefs.getDouble(key);
    } catch (e) {
      Logger.error('Failed to get double: $e');
      return null;
    }
  }

  // List<String> operations
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      return await prefs.setStringList(key, value);
    } catch (e) {
      Logger.error('Failed to set string list: $e');
      return false;
    }
  }

  List<String>? getStringList(String key) {
    try {
      return prefs.getStringList(key);
    } catch (e) {
      Logger.error('Failed to get string list: $e');
      return null;
    }
  }

  // Remove and clear
  Future<bool> remove(String key) async {
    try {
      return await prefs.remove(key);
    } catch (e) {
      Logger.error('Failed to remove key: $e');
      return false;
    }
  }

  Future<bool> clear() async {
    try {
      return await prefs.clear();
    } catch (e) {
      Logger.error('Failed to clear storage: $e');
      return false;
    }
  }

  // Check if key exists
  bool containsKey(String key) {
    return prefs.containsKey(key);
  }
}

/// Custom Storage Exception
class StorageException implements Exception {
  StorageException(this.message);
  final String message;

  @override
  String toString() => message;
}
