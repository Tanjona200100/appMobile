import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/form_data.dart';

/// Service de synchronisation automatique après chaque sauvegarde
class AutoSyncService {
  static const String _masterFileName = 'formulaires_master.json';
  static const String _syncLogFileName = 'auto_sync_log.json';

  bool _autoSyncEnabled = true;

  AutoSyncService();

  /// Activer/Désactiver la synchronisation automatique
  void setAutoSyncEnabled(bool enabled) {
    _autoSyncEnabled = enabled;
  }

  // =====================================================================
  // SYNCHRONISATION AUTOMATIQUE APRÈS SAUVEGARDE
  // =====================================================================

  /// Synchroniser automatiquement après sauvegarde d'un formulaire
  Future<Map<String, dynamic>> autoSyncAfterSave(FormData formData) async {
    if (!_autoSyncEnabled) {
      return {
        'success': false,
        'reason': 'Auto-sync désactivé',
      };
    }

    print('🔄 Synchronisation automatique de ${formData.uuid}...');

    Map<String, dynamic> result = {
      'uuid': formData.uuid,
      'timestamp': DateTime.now().toIso8601String(),
      'json_master': null,
    };

    // Synchroniser vers le fichier JSON master
    try {
      final jsonResult = await _syncToMasterJSON(formData);
      result['json_master'] = jsonResult;
    } catch (e) {
      result['json_master'] = {
        'success': false,
        'error': e.toString(),
      };
    }

    // Enregistrer le log
    await _logSyncOperation(result);

    return result;
  }

  // =====================================================================
  // SYNCHRONISATION VERS JSON MASTER
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

  /// Synchroniser vers le fichier JSON master avec vérification
  Future<Map<String, dynamic>> _syncToMasterJSON(FormData formData) async {
    try {
      // 1. Lire le fichier master
      final masterData = await _readMasterFile();

      // 2. Vérifier si l'UUID existe déjà
      if (masterData.containsKey(formData.uuid)) {
        print('⚠️ UUID ${formData.uuid} existe déjà dans master');

        // Comparer les timestamps pour savoir si c'est une mise à jour
        final existing = masterData[formData.uuid] as Map<String, dynamic>;
        final existingTimestamp = existing['metadata']?['timestamp'] ?? '';
        final newTimestamp = formData.metadata['timestamp'] ?? '';

        if (newTimestamp.compareTo(existingTimestamp) > 0) {
          // C'est une mise à jour
          masterData[formData.uuid] = {
            ...formData.toJson(),
            'synced_to_master_at': DateTime.now().toIso8601String(),
            'is_update': true,
            'previous_timestamp': existingTimestamp,
          };

          await _writeMasterFile(masterData);

          return {
            'success': true,
            'action': 'updated',
            'message': 'Formulaire mis à jour dans master',
            'uuid': formData.uuid,
          };
        } else {
          return {
            'success': false,
            'action': 'skipped',
            'reason': 'duplicate_uuid',
            'message': 'UUID existe déjà avec timestamp identique ou plus récent',
            'uuid': formData.uuid,
          };
        }
      }

      // 3. Vérifier les doublons par identité
      final duplicate = _findDuplicateInMaster(masterData, formData);
      if (duplicate != null) {
        print('⚠️ Doublon détecté: ${duplicate['uuid']}');
        return {
          'success': false,
          'action': 'rejected',
          'reason': 'duplicate_identity',
          'message': 'Personne déjà enregistrée',
          'existing_uuid': duplicate['uuid'],
          'match_type': duplicate['match_type'],
        };
      }

      // 4. Ajouter au master
      masterData[formData.uuid] = {
        ...formData.toJson(),
        'synced_to_master_at': DateTime.now().toIso8601String(),
        'is_update': false,
      };

      await _writeMasterFile(masterData);

      final file = await _getMasterFile();
      print('✅ Formulaire ajouté au master: ${file.path}');

      return {
        'success': true,
        'action': 'inserted',
        'message': 'Formulaire ajouté au master',
        'uuid': formData.uuid,
        'file_path': file.path,
      };
    } catch (e) {
      print('❌ Erreur sync master: $e');
      return {
        'success': false,
        'action': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Trouver un doublon dans le fichier master
  Map<String, dynamic>? _findDuplicateInMaster(
      Map<String, dynamic> masterData,
      FormData formData,
      ) {
    final nom = formData.identite['nom']?.toString().toLowerCase() ?? '';
    final prenom = formData.identite['prenom']?.toString().toLowerCase() ?? '';
    final dateNaissance = formData.identite['date_naissance'] ?? '';

    for (var entry in masterData.entries) {
      final data = entry.value as Map<String, dynamic>;
      final identite = data['identite'] as Map<String, dynamic>? ?? {};

      final existingNom = identite['nom']?.toString().toLowerCase() ?? '';
      final existingPrenom = identite['prenom']?.toString().toLowerCase() ?? '';
      final existingDateNaissance = identite['date_naissance'] ?? '';

      // Correspondance exacte
      if (nom == existingNom &&
          prenom == existingPrenom &&
          dateNaissance == existingDateNaissance) {
        return {
          'uuid': entry.key,
          'match_type': 'exact',
        };
      }

      // Correspondance similaire (optionnel)
      if (_areSimilar(nom, existingNom) && _areSimilar(prenom, existingPrenom)) {
        return {
          'uuid': entry.key,
          'match_type': 'similar',
        };
      }
    }

    return null;
  }

  /// Vérifier la similarité de deux chaînes
  bool _areSimilar(String str1, String str2) {
    if (str1.isEmpty || str2.isEmpty) return false;
    if (str1 == str2) return true;

    if ((str1.length - str2.length).abs() > 2) return false;

    int differences = 0;
    int minLength = str1.length < str2.length ? str1.length : str2.length;

    for (int i = 0; i < minLength; i++) {
      if (str1[i] != str2[i]) differences++;
      if (differences > 2) return false;
    }

    return true;
  }

  // =====================================================================
  // SYNCHRONISATION MASSIVE (TOUS LES FORMULAIRES)
  // =====================================================================

  /// Synchroniser tous les formulaires du fichier local vers master
  Future<Map<String, dynamic>> syncAllFromLocalToMaster() async {
    try {
      print('📊 Lecture du fichier local...');

      // 1. Lire le fichier local
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

      print('📊 ${localData.length} formulaires à traiter');

      int inserted = 0;
      int updated = 0;
      int skipped = 0;
      int errors = 0;
      List<Map<String, dynamic>> duplicates = [];

      // 2. Synchroniser chaque formulaire
      for (var entry in localData.entries) {
        try {
          final formData = FormData.fromJson(entry.value as Map<String, dynamic>);
          final result = await autoSyncAfterSave(formData);

          final jsonResult = result['json_master'];
          if (jsonResult != null && jsonResult['success'] == true) {
            if (jsonResult['action'] == 'inserted') {
              inserted++;
            } else if (jsonResult['action'] == 'updated') {
              updated++;
            }
          } else if (jsonResult?['reason'] == 'duplicate_identity' ||
              jsonResult?['reason'] == 'duplicate_uuid') {
            skipped++;
            duplicates.add({
              'uuid': formData.uuid,
              'nom': formData.identite['nom'],
              'prenom': formData.identite['prenom'],
              'reason': jsonResult['reason'],
            });
          } else {
            errors++;
          }
        } catch (e) {
          errors++;
          print('❌ Erreur traitement ${entry.key}: $e');
        }
      }

      final masterFile = await _getMasterFile();

      return {
        'success': true,
        'total': localData.length,
        'inserted': inserted,
        'updated': updated,
        'skipped': skipped,
        'errors': errors,
        'duplicates': duplicates,
        'master_file_path': masterFile.path,
      };
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
      final logFile = File('${appDir.path}/master_storage/$_syncLogFileName');

      List<dynamic> logs = [];

      if (await logFile.exists()) {
        final content = await logFile.readAsString();
        if (content.isNotEmpty) {
          logs = jsonDecode(content) as List<dynamic>;
        }
      }

      logs.add(result);

      // Garder seulement les 500 derniers logs
      if (logs.length > 500) {
        logs = logs.sublist(logs.length - 500);
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

      // Retourner les derniers logs (ordre inversé)
      return logs.reversed.take(limit).toList();
    } catch (e) {
      print('❌ Erreur lecture logs: $e');
      return [];
    }
  }

  // =====================================================================
  // STATISTIQUES
  // =====================================================================

  /// Obtenir les statistiques du master
  Future<Map<String, dynamic>> getMasterStatistics() async {
    try {
      final masterData = await _readMasterFile();

      Map<String, int> byRegion = {};
      Map<String, int> byCommune = {};
      int withUpdates = 0;

      for (var entry in masterData.values) {
        final data = entry as Map<String, dynamic>;

        // Par région
        final region = data['identite']?['region'] ?? 'Non spécifié';
        byRegion[region] = (byRegion[region] ?? 0) + 1;

        // Par commune
        final commune = data['identite']?['commune'] ?? 'Non spécifié';
        byCommune[commune] = (byCommune[commune] ?? 0) + 1;

        // Avec mises à jour
        if (data['is_update'] == true) {
          withUpdates++;
        }
      }

      final masterFile = await _getMasterFile();

      return {
        'total_records': masterData.length,
        'by_region': byRegion,
        'by_commune': byCommune,
        'with_updates': withUpdates,
        'file_path': masterFile.path,
        'file_size': await _getFileSize(masterFile),
      };
    } catch (e) {
      print('❌ Erreur statistiques: $e');
      return {};
    }
  }

  /// Obtenir la taille du fichier
  Future<String> _getFileSize(File file) async {
    try {
      final size = await file.length();
      if (size < 1024) {
        return '$size B';
      } else if (size < 1048576) {
        return '${(size / 1024).toStringAsFixed(2)} KB';
      } else {
        return '${(size / 1048576).toStringAsFixed(2)} MB';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  // =====================================================================
  // MAINTENANCE
  // =====================================================================

  /// Nettoyer les anciens logs
  Future<void> cleanOldLogs({int keepLast = 100}) async {
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

  /// Réinitialiser le fichier master (ATTENTION: supprime tout!)
  Future<void> resetMasterFile() async {
    try {
      await _writeMasterFile({});
      print('⚠️ Fichier master réinitialisé');
    } catch (e) {
      print('❌ Erreur reset: $e');
    }
  }

  /// Obtenir le chemin du fichier master
  Future<String> getMasterFilePath() async {
    final file = await _getMasterFile();
    return file.path;
  }
}