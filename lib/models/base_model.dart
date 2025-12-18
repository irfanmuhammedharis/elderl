/// Base model class with common functionality
/// All data models should extend this class
abstract class BaseModel {
  /// Convert model to JSON map
  Map<String, dynamic> toJson();

  /// Create model from JSON map
  /// This is typically implemented in subclasses with a factory constructor

  @override
  String toString() {
    return '$runtimeType: ${toJson()}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BaseModel) return false;
    return toJson().toString() == other.toJson().toString();
  }

  @override
  int get hashCode => toJson().toString().hashCode;
}

/// API Response wrapper model
class ApiResponse<T> {

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  @override
  String toString() {
    return 'ApiResponse(success: $success, data: $data, message: $message)';
  }
}

/// Pagination model for list responses
class PaginatedResponse<T> {

  PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  })  : hasNextPage = currentPage < totalPages,
        hasPreviousPage = currentPage > 1;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return PaginatedResponse(
      items: (json['items'] as List)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList(),
      currentPage: json['currentPage'] as int,
      totalPages: json['totalPages'] as int,
      totalItems: json['totalItems'] as int,
    );
  }
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;
}
