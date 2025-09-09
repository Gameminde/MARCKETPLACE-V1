/// Base API exception class
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const ApiException(this.message, {this.statusCode, this.code});

  @override
  String toString() => 'ApiException: $message';
}

/// Network-related exceptions
class NetworkException extends ApiException {
  const NetworkException(super.message, {super.statusCode, super.code});
}

/// Authentication exceptions
class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message, {super.statusCode, super.code});
}

/// Authorization exceptions
class ForbiddenException extends ApiException {
  const ForbiddenException(super.message, {super.statusCode, super.code});
}

/// Resource not found exceptions
class NotFoundException extends ApiException {
  const NotFoundException(super.message, {super.statusCode, super.code});
}

/// Validation exceptions
class ValidationException extends ApiException {
  final Map<String, List<String>>? errors;

  const ValidationException(super.message,
      {super.statusCode, super.code, this.errors});
}

/// Conflict exceptions
class ConflictException extends ApiException {
  const ConflictException(super.message, {super.statusCode, super.code});
}

/// Rate limit exceptions
class RateLimitException extends ApiException {
  final Duration? retryAfter;

  const RateLimitException(super.message,
      {super.statusCode, super.code, this.retryAfter});
}

/// Server exceptions
class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode, super.code});
}

/// Timeout exceptions
class TimeoutException extends ApiException {
  const TimeoutException(super.message, {super.statusCode, super.code});
}

/// Cache exceptions
class CacheException extends ApiException {
  const CacheException(super.message, {super.statusCode, super.code});
}

/// Parsing exceptions
class ParsingException extends ApiException {
  const ParsingException(super.message, {super.statusCode, super.code});
}
