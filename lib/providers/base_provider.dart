import 'package:flutter/foundation.dart';

/// Base provider class with common functionality
/// All feature providers should extend this class
abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Sets loading state safely
  void setLoading(bool value) {
    if (_isDisposed) return;
    _isLoading = value;
    notifyListeners();
  }

  /// Sets error message safely
  void setError(String? message) {
    if (_isDisposed) return;
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  /// Clears error message
  void clearError() {
    if (_isDisposed) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Safe notify listeners
  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// Dispose method
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Execute async operation with automatic loading state management
  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) setLoading(true);
      clearError();
      final result = await operation();
      if (showLoading) setLoading(false);
      return result;
    } catch (e) {
      setError(_formatError(e));
      return null;
    }
  }

  /// Format error message for display
  String _formatError(error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return error.toString();
  }
}
