import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/form_data.dart';

/// Service de synchronisation avec authentification
class AuthSyncService {
  static const String API_BASE_URL = 'http://13.246.182.15:3001';
  static const String FORMS_ENDPOINT = '/api/forms';

  String? _authToken;

  /// Initialise le service avec le token d'authentification
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
    } catch (e) {
      print('Erreur initialisation AuthSyncService: $e');
    }
  }

  /// Met à jour le token d'authentification
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Vérifie si le token est disponible
  bool hasValidToken() {
    return _authToken != null && _authToken!.isNotEmpty;
  }

  /// Synchronise un formulaire unique vers le serveur
  Future<Map<String, dynamic>> syncFormToServer(FormData formData) async {
    if (!hasValidToken()) {
      return {
        'success': false,
        'error': 'Token d\'authentification manquant',
        'code': 'NO_AUTH',
      };
    }

    try {
      final url = Uri.parse('$API_BASE_URL$FORMS_ENDPOINT');

      print('📡 Synchronisation vers: $url');
      print('📋 UUID: ${formData.uuid}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode(formData.toJson()),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Timeout de synchronisation');
        },
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Synchronisation réussie',
          'server_id': data['id'],
        };
      } else if (response.statusCode == 409) {
        // Doublon détecté
        return {
          'success': false,
          'error': 'Ce formulaire existe déjà sur le serveur',
          'code': 'DUPLICATE',
        };
      } else if (response.statusCode == 401) {
        // Token invalide ou expiré
        return {
          'success': false,
          'error': 'Session expirée, veuillez vous reconnecter',
          'code': 'AUTH_EXPIRED',
        };
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'error': data['message'] ?? 'Données invalides',
          'code': 'INVALID_DATA',
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur serveur (${response.statusCode})',
          'code': 'SERVER_ERROR',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Délai de synchronisation dépassé',
        'code': 'TIMEOUT',
      };
    } on SocketException {
      return {
        'success': false,
        'error': 'Pas de connexion réseau',
        'code': 'NO_NETWORK',
      };
    } catch (e) {
      print('❌ Erreur sync: $e');
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
        'code': 'UNKNOWN',
      };
    }
  }

  /// Synchronise plusieurs formulaires en lot
  Future<Map<String, dynamic>> syncMultipleForms(
      List<FormData> forms, {
        Function(int current, int total)? onProgress,
      }) async {
    if (!hasValidToken()) {
      return {
        'success': false,
        'error': 'Token d\'authentification manquant',
      };
    }

    int successCount = 0;
    int failureCount = 0;
    int duplicateCount = 0;
    List<String> failedUuids = [];
    Map<String, String> errors = {};

    for (int i = 0; i < forms.length; i++) {
      final form = forms[i];

      // Callback de progression
      if (onProgress != null) {
        onProgress(i + 1, forms.length);
      }

      final result = await syncFormToServer(form);

      if (result['success'] == true) {
        successCount++;
      } else {
        if (result['code'] == 'DUPLICATE') {
          duplicateCount++;
        } else {
          failureCount++;
          failedUuids.add(form.uuid);
          errors[form.uuid] = result['error'] ?? 'Erreur inconnue';
        }

        // Si le token a expiré, arrêter la synchronisation
        if (result['code'] == 'AUTH_EXPIRED') {
          return {
            'success': false,
            'error': 'Session expirée',
            'success_count': successCount,
            'failure_count': failureCount,
            'duplicate_count': duplicateCount,
            'failed_uuids': failedUuids,
            'errors': errors,
            'auth_expired': true,
          };
        }
      }

      // Petite pause entre les requêtes pour ne pas surcharger le serveur
      if (i < forms.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return {
      'success': true,
      'success_count': successCount,
      'failure_count': failureCount,
      'duplicate_count': duplicateCount,
      'failed_uuids': failedUuids,
      'errors': errors,
    };
  }

  /// Récupère les formulaires depuis le serveur
  Future<Map<String, dynamic>> fetchFormsFromServer({
    String? lastSyncDate,
    int? limit,
  }) async {
    if (!hasValidToken()) {
      return {
        'success': false,
        'error': 'Token d\'authentification manquant',
      };
    }

    try {
      var url = '$API_BASE_URL$FORMS_ENDPOINT';

      // Ajouter des paramètres de requête si nécessaire
      final queryParams = <String, String>{};
      if (lastSyncDate != null) {
        queryParams['since'] = lastSyncDate;
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'forms': data['forms'] ?? data,
          'count': data['count'] ?? (data['forms'] as List?)?.length ?? 0,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Session expirée',
          'auth_expired': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur serveur (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Supprime un formulaire du serveur
  Future<Map<String, dynamic>> deleteFormOnServer(String uuid) async {
    if (!hasValidToken()) {
      return {
        'success': false,
        'error': 'Token d\'authentification manquant',
      };
    }

    try {
      final url = Uri.parse('$API_BASE_URL$FORMS_ENDPOINT/$uuid');

      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Formulaire supprimé du serveur',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': true,
          'message': 'Formulaire introuvable sur le serveur',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Session expirée',
          'auth_expired': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur serveur (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Vérifie la validité du token auprès du serveur
  Future<bool> validateToken() async {
    if (!hasValidToken()) return false;

    try {
      final url = Uri.parse('$API_BASE_URL/api/auth/validate');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Rafraîchit le token d'authentification
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) {
        return {
          'success': false,
          'error': 'Pas de refresh token disponible',
        };
      }

      final url = Uri.parse('$API_BASE_URL/api/auth/refresh');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'refresh_token': refreshToken,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];

        if (newToken != null) {
          _authToken = newToken;
          await prefs.setString('auth_token', newToken);

          return {
            'success': true,
            'token': newToken,
          };
        }
      }

      return {
        'success': false,
        'error': 'Échec du rafraîchissement du token',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }
}