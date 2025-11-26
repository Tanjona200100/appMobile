/// Configuration centralisée de l'API
class ApiConfig {
  // URL de base de l'API
  static const String BASE_URL = 'http://13.246.182.15:3001';

  // Endpoints d'authentification
  static const String LOGIN_ENDPOINT = '/login';
  static const String LOGOUT_ENDPOINT = '/api/auth/logout';
  static const String VALIDATE_TOKEN_ENDPOINT = '/api/auth/validate';
  static const String REFRESH_TOKEN_ENDPOINT = '/api/auth/refresh';

  // Endpoints des formulaires
  static const String FORMS_ENDPOINT = '/api/forms';
  static const String FORM_BY_ID_ENDPOINT = '/api/forms'; // + /{id}

  // Endpoints des images
  static const String UPLOAD_IMAGE_ENDPOINT = '/api/images/upload';

  // Timeouts
  static const Duration CONNECTION_TIMEOUT = Duration(seconds: 10);
  static const Duration REQUEST_TIMEOUT = Duration(seconds: 30);
  static const Duration UPLOAD_TIMEOUT = Duration(seconds: 60);

  // Headers communs
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };

  // URLs complètes
  static String get loginUrl => '$BASE_URL$LOGIN_ENDPOINT';
  static String get logoutUrl => '$BASE_URL$LOGOUT_ENDPOINT';
  static String get validateTokenUrl => '$BASE_URL$VALIDATE_TOKEN_ENDPOINT';
  static String get refreshTokenUrl => '$BASE_URL$REFRESH_TOKEN_ENDPOINT';
  static String get formsUrl => '$BASE_URL$FORMS_ENDPOINT';
  static String formByIdUrl(String id) => '$BASE_URL$FORM_BY_ID_ENDPOINT/$id';
  static String get uploadImageUrl => '$BASE_URL$UPLOAD_IMAGE_ENDPOINT';

  // Configuration de retry
  static const int MAX_RETRY_ATTEMPTS = 3;
  static const Duration RETRY_DELAY = Duration(seconds: 2);

  // Taille maximale des fichiers (en bytes)
  static const int MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5 MB
  static const int MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB

  // Messages d'erreur
  static const String ERROR_NO_INTERNET = 'Pas de connexion internet';
  static const String ERROR_TIMEOUT = 'Délai de connexion dépassé';
  static const String ERROR_SERVER = 'Erreur du serveur';
  static const String ERROR_AUTH_EXPIRED = 'Session expirée, veuillez vous reconnecter';
  static const String ERROR_INVALID_CREDENTIALS = 'Email ou mot de passe incorrect';
  static const String ERROR_UNKNOWN = 'Une erreur est survenue';

  // Status codes
  static const int STATUS_OK = 200;
  static const int STATUS_CREATED = 201;
  static const int STATUS_NO_CONTENT = 204;
  static const int STATUS_BAD_REQUEST = 400;
  static const int STATUS_UNAUTHORIZED = 401;
  static const int STATUS_FORBIDDEN = 403;
  static const int STATUS_NOT_FOUND = 404;
  static const int STATUS_CONFLICT = 409;
  static const int STATUS_SERVER_ERROR = 500;

  // Clés de stockage local
  static const String STORAGE_AUTH_TOKEN = 'auth_token';
  static const String STORAGE_REFRESH_TOKEN = 'refresh_token';
  static const String STORAGE_USER_DATA = 'user_data';
  static const String STORAGE_LAST_EMAIL = 'last_email';
  static const String STORAGE_LAST_SYNC = 'last_sync_date';

  // Paramètres de synchronisation
  static const Duration AUTO_SYNC_INTERVAL = Duration(minutes: 5);
  static const int SYNC_BATCH_SIZE = 10; // Nombre de formulaires par lot

  // Mode debug
  static const bool DEBUG_MODE = true; // Mettre à false en production

  static void logDebug(String message) {
    if (DEBUG_MODE) {
      print('🔍 [DEBUG] $message');
    }
  }

  static void logInfo(String message) {
    print('ℹ️ [INFO] $message');
  }

  static void logError(String message, [dynamic error]) {
    print('❌ [ERROR] $message');
    if (error != null && DEBUG_MODE) {
      print('   Details: $error');
    }
  }

  static void logSuccess(String message) {
    print('✅ [SUCCESS] $message');
  }
}

/// Classe pour gérer les réponses de l'API de manière unifiée
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? errorCode;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errorCode,
    this.statusCode,
  });

  factory ApiResponse.success({T? data, String? message, int? statusCode}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message ?? 'Opération réussie',
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error({
    required String message,
    String? errorCode,
    int? statusCode,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      errorCode: errorCode,
      statusCode: statusCode,
    );
  }

  bool get isAuthError =>
      errorCode == 'AUTH_EXPIRED' ||
          errorCode == 'NO_AUTH' ||
          statusCode == ApiConfig.STATUS_UNAUTHORIZED;

  bool get isNetworkError =>
      errorCode == 'NO_NETWORK' ||
          errorCode == 'TIMEOUT';

  bool get isDuplicateError =>
      errorCode == 'DUPLICATE' ||
          statusCode == ApiConfig.STATUS_CONFLICT;
}

/// Enumération des types d'erreur
enum ApiErrorType {
  network,
  timeout,
  authentication,
  validation,
  server,
  duplicate,
  unknown,
}

/// Extension pour faciliter la gestion des erreurs
extension ApiErrorTypeExtension on ApiErrorType {
  String get message {
    switch (this) {
      case ApiErrorType.network:
        return ApiConfig.ERROR_NO_INTERNET;
      case ApiErrorType.timeout:
        return ApiConfig.ERROR_TIMEOUT;
      case ApiErrorType.authentication:
        return ApiConfig.ERROR_AUTH_EXPIRED;
      case ApiErrorType.validation:
        return 'Données invalides';
      case ApiErrorType.server:
        return ApiConfig.ERROR_SERVER;
      case ApiErrorType.duplicate:
        return 'Cette donnée existe déjà';
      case ApiErrorType.unknown:
        return ApiConfig.ERROR_UNKNOWN;
    }
  }

  String get code {
    switch (this) {
      case ApiErrorType.network:
        return 'NO_NETWORK';
      case ApiErrorType.timeout:
        return 'TIMEOUT';
      case ApiErrorType.authentication:
        return 'AUTH_EXPIRED';
      case ApiErrorType.validation:
        return 'INVALID_DATA';
      case ApiErrorType.server:
        return 'SERVER_ERROR';
      case ApiErrorType.duplicate:
        return 'DUPLICATE';
      case ApiErrorType.unknown:
        return 'UNKNOWN';
    }
  }
}