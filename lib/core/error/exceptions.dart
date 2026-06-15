/// Low-level exceptions thrown by services and data sources.
///
/// Repositories catch these and convert them into [Failure]s for the BLoC
/// layer.
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when the AI / network call fails.
class ServerException extends AppException {
  const ServerException(super.message);
}

/// Thrown when local storage read/write fails.
class CacheException extends AppException {
  const CacheException(super.message);
}

/// Thrown when authentication (sign in / sign up / reset) fails.
class AuthException extends AppException {
  const AuthException(super.message);
}

/// Thrown when a required runtime permission is denied.
class PermissionException extends AppException {
  const PermissionException(super.message);
}

/// Thrown when a device capability (mic, camera, speech) is unavailable.
class DeviceException extends AppException {
  const DeviceException(super.message);
}

/// Thrown when initialization (Firebase, Hive, etc.) fails.
class InitializationException extends AppException {
  const InitializationException(super.message);
}
