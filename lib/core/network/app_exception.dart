/// Error taxonomy the rest of the app reasons about. Every failure that can
/// reach the UI is mapped to one of these so screens can show a contextual
/// message instead of a raw exception string or stack trace.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Pas de connexion réseau. Vérifiez votre connexion.']);
}

class TimeoutAppException extends AppException {
  const TimeoutAppException([super.message = "Le serveur met trop de temps à répondre."]);
}

class ValidationException extends AppException {
  const ValidationException([super.message = 'Requête invalide.']);
}

class AuthException extends AppException {
  const AuthException([super.message = 'Non autorisé.']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Ressource introuvable.']);
}

class ServerException extends AppException {
  const ServerException(this.statusCode, [String? message])
      : super(message ?? 'Erreur serveur ($statusCode).');

  final int statusCode;
}

class UnknownException extends AppException {
  const UnknownException([super.message = 'Une erreur inattendue est survenue.']);
}
