import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/form_data.dart';

/// Service de synchronisation automatique amélioré
class AutoSyncService {
  static const String _masterFileName = 'formulaires_master.json';
  static const String _syncLogFileName = 'auto_sync_log.json';

  // URL de votre API backend - À CONFIGURER
  static const String _apiBaseUrl = 'https://votre-api.com/api';
  static const String _syncEndpoint = '/formulaires/sync';

  // Configuration de retry
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);

  bool _autoSyncEnabled = true;
  bool _isSyncing = false;

  AutoSyncService();

  /// Activer/Désactiver la synchronisation automatique
  void setAutoSyncEnabled(bool enabled) {
    _autoSyncEnabled = enabled;
  }

  bool get isSyncing => _isSyncing;

  // =====================================================================
  // SYNCHRONISATION VERS LE SERVEUR DISTANT
  // =====================================================================

  /// Synchroniser un formulaire vers le serveur distant
  Future<bool?> syncFormToServer(FormData formData) async {
    if (!_autoSyncEnabled) {
      print('⚠️ Auto-sync désactivé');
      return false;
    }

    print('📡 Tentative de synchronisation vers le serveur: ${formData.uuid}');

    int retryCount = 0;

    while (retryCount < _maxRetries) {
      try {
        // Préparer les données à envoyer
        final Map<String, dynamic> payload = {
          'uuid': formData.uuid,
          'identite': formData.identite,
          'parcelle': formData.parcelle,
          'metadata': formData.metadata,
          'sync_timestamp': DateTime.now().toIso8601String(),
        };

        // Envoyer vers le serveur
        final response = await http.post(
          Uri.parse('$_apiBaseUrl$_syncEndpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Timeout de connexion au serveur');
          },
        );

        // Vérifier la réponse
        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ Synchronisation réussie: ${formData.uuid}');

          // Logger le succès
          await _logSyncOperation({
            'uuid': formData.uuid,
            'timestamp': DateTime.now().toIso8601String(),
            'status': 'success',
            'server_response': jsonDecode(response.body),
            'retry_count': retryCount,
          });

          // Synchroniser aussi vers le master local
          await _syncToMasterJSON(formData);

          return true;
        } else if (response.statusCode == 409) {
          // Doublon détecté côté serveur
          print('⚠️ Doublon détecté par le serveur: ${formData.uuid}');

          await _logSyncOperation({
            'uuid': formData.uuid,
            'timestamp': DateTime.now().toIso8601String(),
            'status': 'duplicate',
            'message': 'Formulaire déjà existant sur le serveur',
          });

          return true; // Considéré comme un succès (pas besoin de réessayer)
        } else {
          // Erreur HTTP
          print('❌ Erreur serveur (${response.statusCode}): ${response.body}');

          retryCount++;
          if (retryCount < _maxRetries) {
            print('🔄 Nouvelle tentative dans ${_retryDelay.inSeconds}s... ($retryCount/$_maxRetries)');
            await Future.delayed(_retryDelay);
          }
        }
      } on SocketException catch (e) {
        print('❌ Pas de connexion réseau: $e');
        return false; // Pas de retry si pas de réseau
      } on TimeoutException catch (e) {
        print('❌ Timeout: $e');
        retryCount++;
        if (retryCount < _maxRetries) {
          await Future.delayed(_retryDelay);
        }
      } on FormatException catch (e) {
        print('❌ Erreur format données: $e');
        return false; // Erreur fatale, pas de retry
      } catch (e) {
        print('❌ Erreur inattendue: $e');
        retryCount++;
        if (retryCount < _maxRetries) {
          await Future.delayed(_retryDelay);
        }
      }
    }

    // Échec après tous les retries
    await _logSyncOperation({
      'uuid': formData.uuid,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'failed',
      'retry_count': retryCount,
      'message': 'Échec après $retryCount tentatives',
    });

    return false;
  }

  /// Synchroniser plusieurs formulaires avec gestion de progression
  Future<Map<String, dynamic>> syncMultipleForms(
      List<FormData> forms, {
        Function(int current, int total)? onProgress,
      }) async {
    if (_isSyncing) {
      return {
        'success': false,
        'message': 'Une synchronisation est déjà en cours',
      };
    }

    _isSyncing = true;

    int successCount = 0;
    int failureCount = 0;
    int duplicateCount = 0;
    List<String> failedUuids = [];

    try {
      for (int i = 0; i < forms.length; i++) {
        final form = forms[i];

        // Notifier la progression
        if (onProgress != null) {
          onProgress(i + 1, forms.length);
        }

        // Tenter la synchronisation
        final result = await syncFormToServer(form);

        if (result == true) {
          successCount++;
        } else if (result == false) {
          failureCount++;
          failedUuids.add(form.uuid);
        } else {
          // null signifie doublon ou déjà synchronisé
          duplicateCount++;
        }

        // Petite pause entre les envois pour ne pas surcharger le serveur
        await Future.delayed(const Duration(milliseconds: 500));
      }

      return {
        'success': true,
        'total': forms.length,
        'success_count': successCount,
        'failure_count': failureCount,
        'duplicate_count': duplicateCount,
        'failed_uuids': failedUuids,
      };
    } finally {
      _isSyncing = false;
    }
  }

  // =====================================================================
  // SYNCHRONISATION VERS MASTER LOCAL (Backup)
  // =====================================================================

  /// Obtenir le fichier JSON master
  Future<File> _getMasterFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    final masterDir = Directory('${appDir.path}/master_storage');

    if (!await masterDir.exists()) {
      await masterDir.create(recursive: true);
    }

    return File('${masterDir.path}/$_masterFileName');
  }

  /// Lire le fichier master
  Future<Map<String, dynamic>> _readMasterFile() async {
    try {
      final file = await _getMasterFile();

      if (!await file.exists()) {
        return {};
      }

      final content = await file.readAsString();
      if (content.isEmpty) {
        return {};
      }

      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Erreur lecture master: $e');
      return {};
    }
  }

  /// Écrire dans le fichier master
  Future<void> _writeMasterFile(Map<String, dynamic> data) async {
    try {
      final file = await _getMasterFile();
      final jsonData = JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonData);
    } catch (e) {
      throw Exception('Erreur écriture master: $e');
    }
  }

  /// Synchroniser vers le fichier JSON master local (backup)
  Future<Map<String, dynamic>> _syncToMasterJSON(FormData formData) async {
    try {
      final masterData = await _readMasterFile();

      // Vérifier si l'UUID existe déjà
      if (masterData.containsKey(formData.uuid)) {
        final existing = masterData[formData.uuid] as Map<String, dynamic>;
        final existingTimestamp = existing['metadata']?['timestamp'] ?? '';
        final newTimestamp = formData.metadata['timestamp'] ?? '';

        if (newTimestamp.compareTo(existingTimestamp) > 0) {
          // Mise à jour
          masterData[formData.uuid] = {
            ...formData.toJson(),
            'synced_to_master_at': DateTime.now().toIso8601String(),
            'is_update': true,
          };

          await _writeMasterFile(masterData);

          return {
            'success': true,
            'action': 'updated',
            'uuid': formData.uuid,
          };
        } else {
          return {
            'success': false,
            'action': 'skipped',
            'reason': 'duplicate_uuid',
          };
        }
      }

      // Ajouter au master
      masterData[formData.uuid] = {
        ...formData.toJson(),
        'synced_to_master_at': DateTime.now().toIso8601String(),
        'is_update': false,
      };

      await _writeMasterFile(masterData);

      return {
        'success': true,
        'action': 'inserted',
        'uuid': formData.uuid,
      };
    } catch (e) {
      print('❌ Erreur sync master local: $e');
      return {
        'success': false,
        'action': 'error',
        'error': e.toString(),
      };
    }
  }

  // =====================================================================
  // SYNCHRONISATION MASSIVE
  // =====================================================================

  /// Synchroniser tous les formulaires locaux vers le serveur
  Future<Map<String, dynamic>> syncAllFromLocalToMaster() async {
    try {
      print('📊 Lecture des formulaires locaux...');

      final appDir = await getApplicationDocumentsDirectory();
      final localFile = File('${appDir.path}/formulaires_agriculture/formulaires_agriculture.json');

      if (!await localFile.exists()) {
        return {
          'success': false,
          'message': 'Fichier local non trouvé',
        };
      }

      final localContent = await localFile.readAsString();
      final localData = jsonDecode(localContent) as Map<String, dynamic>;

      print('📊 ${localData.length} formulaires à synchroniser');

      final forms = localData.values
          .map((json) => FormData.fromJson(json as Map<String, dynamic>))
          .toList();

      return await syncMultipleForms(forms);
    } catch (e) {
      print('❌ Erreur synchronisation massive: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // =====================================================================
  // LOGS ET HISTORIQUE
  // =====================================================================

  /// Enregistrer le log de synchronisation
  Future<void> _logSyncOperation(Map<String, dynamic> result) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDir.path}/master_storage');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final logFile = File('${logDir.path}/$_syncLogFileName');

      List<dynamic> logs = [];

      if (await logFile.exists()) {
        final content = await logFile.readAsString();
        if (content.isNotEmpty) {
          logs = jsonDecode(content) as List<dynamic>;
        }
      }

      logs.add(result);

      // Garder seulement les 1000 derniers logs
      if (logs.length > 1000) {
        logs = logs.sublist(logs.length - 1000);
      }

      await logFile.writeAsString(JsonEncoder.withIndent('  ').convert(logs));
    } catch (e) {
      print('⚠️ Erreur log: $e');
    }
  }

  /// Obtenir les logs de synchronisation
  Future<List<dynamic>> getSyncLogs({int limit = 50}) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logFile = File('${appDir.path}/master_storage/$_syncLogFileName');

      if (!await logFile.exists()) {
        return [];
      }

      final content = await logFile.readAsString();
      if (content.isEmpty) {
        return [];
      }

      final logs = jsonDecode(content) as List<dynamic>;
      return logs.reversed.take(limit).toList();
    } catch (e) {
      print('❌ Erreur lecture logs: $e');
      return [];
    }
  }

  /// Nettoyer les anciens logs
  Future<void> cleanOldLogs({int keepLast = 500}) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logFile = File('${appDir.path}/master_storage/$_syncLogFileName');

      if (!await logFile.exists()) return;

      final content = await logFile.readAsString();
      if (content.isEmpty) return;

      final logs = jsonDecode(content) as List<dynamic>;

      if (logs.length > keepLast) {
        final newLogs = logs.sublist(logs.length - keepLast);
        await logFile.writeAsString(JsonEncoder.withIndent('  ').convert(newLogs));
        print('🧹 Logs nettoyés: ${logs.length - keepLast} supprimés');
      }
    } catch (e) {
      print('❌ Erreur nettoyage logs: $e');
    }
  }

  /// Obtenir le chemin du fichier master
  Future<String> getMasterFilePath() async {
    final file = await _getMasterFile();
    return file.path;
  }
}