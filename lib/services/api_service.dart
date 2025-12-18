import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/logger.dart';

/// API Service for handling all network requests
/// Follows REST API integration guidelines
class ApiService {
  factory ApiService() => _instance;
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();

  final http.Client _client = http.Client();
  final Duration _timeout = const Duration(seconds: 30);

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      Logger.info('GET: $uri');

      final response = await _client
          .get(uri, headers: _buildHeaders(headers))
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      Logger.error('GET Error: $e');
      rethrow;
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      Logger.info('POST: $uri');

      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      Logger.error('POST Error: $e');
      rethrow;
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      Logger.info('PUT: $uri');

      final response = await _client
          .put(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      Logger.error('PUT Error: $e');
      rethrow;
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      Logger.info('DELETE: $uri');

      final response = await _client
          .delete(uri, headers: _buildHeaders(headers))
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      Logger.error('DELETE Error: $e');
      rethrow;
    }
  }

  /// Build URI with query parameters
  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  /// Build request headers
  Map<String, String> _buildHeaders(Map<String, String>? additionalHeaders) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    return headers;
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    Logger.info('Response Status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // Handle error responses
    String errorMessage;
    try {
      final errorBody = jsonDecode(response.body);
      errorMessage = errorBody['message'] ?? 'Unknown error occurred';
    } catch (_) {
      errorMessage = 'Server error: ${response.statusCode}';
    }

    switch (response.statusCode) {
      case 400:
        throw ApiException('Bad request: $errorMessage');
      case 401:
        throw ApiException('Unauthorized: Please login again');
      case 403:
        throw ApiException('Forbidden: Access denied');
      case 404:
        throw ApiException('Not found: $errorMessage');
      case 500:
        throw ApiException('Server error: Please try again later');
      default:
        throw ApiException(errorMessage);
    }
  }

  /// Dispose client
  void dispose() {
    _client.close();
  }
}

/// Custom API Exception
class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
