import 'package:flutter/foundation.dart';

/// Main application state provider
/// Handles global app state following MVVM architecture
class AppProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Sets loading state
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Sets error message
  void setError(String? message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  /// Clears error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Generic async operation wrapper with error handling
  Future<T?> executeWithLoading<T>(Future<T> Function() operation) async {
    try {
      setLoading(true);
      final result = await operation();
      setLoading(false);
      return result;
    } catch (e) {
      setError(e.toString());
      return null;
    }
  }
}
