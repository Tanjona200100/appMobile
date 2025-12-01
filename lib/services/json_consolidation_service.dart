import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/form_data.dart';

/// Service pour consolider tous les JSON individuels en un seul fichier master
/// avec détection et filtrage des doublons
class JsonConsolidationService {
  static const String MASTER_JSON_FILENAME = 'master_consolidated_forms.json';
  static const String BACKUP_FOLDER = 'json_backups';

  /// Consolide tous les fichiers JSON individuels en un seul fichier master
  /// Filtre automatiquement les doublons basés sur UUID et CIN
  Future<Map<String, dynamic>> consolidateAllJsonFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final formsDir = Directory('${directory.path}/forms');

      if (!await formsDir.exists()) {
        return {
          'success': false,
          'error': 'Aucun dossier de formulaires trouvé',
          'total': 0,
        };
      }

      // Lire tous les fichiers JSON individuels
      final jsonFiles = formsDir
          .listSync()
          .where((file) => file.path.endsWith('.json'))
          .toList();

      if (jsonFiles.isEmpty) {
        return {
          'success': false,
          'error': 'Aucun fichier JSON trouvé',
          'total': 0,
        };
      }

      print('📁 ${jsonFiles.length} fichiers JSON trouvés');

      // Map pour stocker les données uniques (clé = UUID)
      Map<String, Map<String, dynamic>> uniqueForms = {};

      // Sets pour détecter les doublons
      Set<String> seenUUIDs = {};
      Set<String> seenCINs = {};

      int duplicateCount = 0;
      int errorCount = 0;

      // Parcourir chaque fichier JSON
      for (var file in jsonFiles) {
        try {
          final content = await File(file.path).readAsString();
          final jsonData = jsonDecode(content) as Map<String, dynamic>;

          // Convertir le format local en format master
          final masterFormatData = _convertLocalToMasterFormat(jsonData);

          final individu = masterFormatData['individu'] as Map<String, dynamic>;
          final uuid = individu['uuid'] as String?;
          if (uuid == null || uuid.isEmpty) {
            errorCount++;
            print('⚠️ UUID manquant dans ${file.path}');
            continue;
          }

          // Extraire le numéro CIN
          final cin = individu['cin'] as Map<String, dynamic>?;
          final numeroCIN = cin?['numero']?.toString().trim() ?? '';

          // Vérifier les doublons
          bool isDuplicate = false;

          if (seenUUIDs.contains(uuid)) {
            isDuplicate = true;
            print('🔄 Doublon UUID détecté: $uuid');
          }

          if (numeroCIN.isNotEmpty && seenCINs.contains(numeroCIN)) {
            isDuplicate = true;
            print('🔄 Doublon CIN détecté: $numeroCIN');
          }

          if (isDuplicate) {
            duplicateCount++;

            // Conserver la version la plus récente
            final existingForm = uniqueForms[uuid];
            final existingTimestamp = existingForm?['metadata']?['timestamp'];
            final newTimestamp = jsonData['metadata']?['timestamp'];

            if (newTimestamp != null &&
                (existingTimestamp == null ||
                    DateTime.parse(newTimestamp).isAfter(DateTime.parse(existingTimestamp)))) {
              print('✅ Conservation de la version la plus récente pour UUID: $uuid');
              uniqueForms[uuid] = masterFormatData;
            }
          } else {
            // Ajouter le nouveau formulaire
            uniqueForms[uuid] = masterFormatData;
            seenUUIDs.add(uuid);
            if (numeroCIN.isNotEmpty) {
              seenCINs.add(numeroCIN);
            }
          }

        } catch (e) {
          errorCount++;
          print('❌ Erreur lecture ${file.path}: $e');
        }
      }

      // Créer le fichier master consolidé
      final masterFile = File('${directory.path}/$MASTER_JSON_FILENAME');

      // Créer une sauvegarde si le fichier existe déjà
      if (await masterFile.exists()) {
        await _createBackup(masterFile);
      }

      // Préparer les données pour le fichier master - FORMAT TABLEAU
      final consolidatedData = uniqueForms.values.toList();

      // Sauvegarder le fichier master
      final jsonString = JsonEncoder.withIndent('  ').convert(consolidatedData);
      await masterFile.writeAsString(jsonString);

      print('✅ Fichier master créé: ${masterFile.path}');
      print('📊 Total unique: ${uniqueForms.length}');
      print('🔄 Doublons supprimés: $duplicateCount');
      print('❌ Erreurs: $errorCount');

      return {
        'success': true,
        'file_path': masterFile.path,
        'total_forms': uniqueForms.length,
        'duplicates_removed': duplicateCount,
        'errors': errorCount,
        'source_files': jsonFiles.length,
      };

    } catch (e) {
      print('❌ Erreur consolidation: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Convertit le format local en format master (API)
  Map<String, dynamic> _convertLocalToMasterFormat(Map<String, dynamic> localData) {
    // Conversion sécurisée des maps
    final identite = _convertToStringMap(localData['identite']);
    final parcelle = _convertToStringMap(localData['parcelle']);
    final metadata = _convertToStringMap(localData['metadata']);
    final questionnaire = localData['questionnaire_parcelles'];

    return {
      'individu': {
        'uuid': localData['uuid'],
        'nom': identite['nom'],
        'prenom': identite['prenom'],
        'surnom': identite['surnom'],
        'sexe': identite['sexe'],
        'date_naissance': identite['date_naissance'],
        'lieu_naissance': identite['lieu_naissance'],
        'adresse': identite['adresse'],
        'gps_point': '${parcelle['latitude']},${parcelle['longitude']}',
        'photo': '',
        'user_id': _safeInt(metadata['agent_id'], 1),
        'commune_id': 2,
        'nom_pere': identite['nom_pere'],
        'nom_mere': identite['nom_mere'],
        'profession': identite['metier'],
        'activites_complementaires': identite['activites_complementaires'],
        'statut_matrimonial': identite['statut_matrimonial'],
        'nombre_personnes_a_charge': _safeInt(identite['nombre_personnes_charge']),
        'telephone': identite['telephone1'],
        'cin': _buildCinData(identite['cin']),
        'commune_nom': identite['commune'],
        'fokontany_nom': identite['fokontany'],
        'nombre_enfants': _safeInt(identite['nombre_enfants']),
        'telephone2': identite['telephone2'],
      },
      'parcelles': [
        {
          'nom': parcelle['nom'],
          'superficie': _safeDouble(parcelle['superficie'], 1500.0),
          'gps': _safeGpsData(parcelle['gps']),
          'geom': _buildGeomData(parcelle),
          'description': parcelle['description'],
        }
      ],
      'questionnaire_parcelles': _buildQuestionnaireData(questionnaire),
    };
  }

  /// Ajoute un nouveau formulaire au fichier master (si non dupliqué)
  Future<Map<String, dynamic>> addToMaster(FormData formData) async {
    try {
      // Vérifier les doublons avant d'ajouter
      final uuidExists = await uuidExistsInMaster(formData.uuid);
      if (uuidExists) {
        return {
          'success': false,
          'error': 'UUID déjà existant dans le master',
          'duplicate': true,
        };
      }

      final cin = _convertToStringMap(formData.identite)['cin'] as Map<String, dynamic>?;
      final numeroCIN = cin?['numero']?.toString().trim() ?? '';

      if (numeroCIN.isNotEmpty) {
        final cinExists = await cinExistsInMaster(numeroCIN);
        if (cinExists) {
          return {
            'success': false,
            'error': 'CIN déjà existant dans le master',
            'duplicate': true,
          };
        }
      }

      // Charger le fichier master existant ou créer un nouveau
      final directory = await getApplicationDocumentsDirectory();
      final masterFile = File('${directory.path}/$MASTER_JSON_FILENAME');

      List<dynamic> masterForms = [];

      if (await masterFile.exists()) {
        final content = await masterFile.readAsString();
        masterForms = jsonDecode(content) as List<dynamic>;
      }

      // Convertir FormData en format master
      final formJson = _convertFormDataToMasterFormat(formData);

      // Ajouter le nouveau formulaire
      masterForms.add(formJson);

      // Sauvegarder
      final jsonString = JsonEncoder.withIndent('  ').convert(masterForms);
      await masterFile.writeAsString(jsonString);

      print('✅ Formulaire ajouté au master: ${formData.uuid}');

      return {
        'success': true,
        'file_path': masterFile.path,
        'total_forms': masterForms.length,
      };

    } catch (e) {
      print('❌ Erreur ajout au master: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Convertit FormData en format JSON pour le fichier master (format API)
  Map<String, dynamic> _convertFormDataToMasterFormat(FormData formData) {
    print('🔧 CONVERSION JSON pour ${formData.uuid}');

    // Conversion sécurisée des maps
    final identite = _convertToStringMap(formData.identite);
    final parcelle = _convertToStringMap(formData.parcelle);
    final metadata = _convertToStringMap(formData.metadata);

    // Variables préparées pour les valeurs complexes
    final user_id = _safeInt(metadata['agent_id'], 1);
    final nombrePersonnesCharge = _safeInt(identite['nombre_personnes_charge']);
    final nombreEnfants = _safeInt(identite['nombre_enfants']);
    final superficie = _safeDouble(parcelle['superficie'], 1500.0);

    // Structures complexes préparées
    final gpsData = {
      'latitude': _safeDouble(parcelle['latitude'], -18.879),
      'longitude': _safeDouble(parcelle['longitude'], 47.5078),
      'altitude': _safeDouble(parcelle['altitude'], 1280.0),
    };

    final geomData = _buildGeomData(parcelle);

    return {
      'individu': {
        'uuid': formData.uuid,
        'nom': identite['nom'] ?? 'Inconnu',
        'prenom': identite['prenom'] ?? 'Inconnu',
        'surnom': identite['surnom'] ?? '',
        'sexe': identite['sexe'] ?? '',
        'date_naissance': identite['date_naissance'] ?? '',
        'lieu_naissance': identite['lieu_naissance'] ?? '',
        'adresse': identite['adresse'] ?? '',
        'gps_point': '${parcelle['latitude'] ?? -18.879},${parcelle['longitude'] ?? 47.5078}',
        'photo': '',
        'user_id': user_id,
        'commune_id': 2,
        'nom_pere': identite['nom_pere'] ?? '',
        'nom_mere': identite['nom_mere'] ?? '',
        'profession': identite['metier'] ?? '',
        'activites_complementaires': identite['activites_complementaires'] ?? '',
        'statut_matrimonial': identite['statut_matrimonial'] ?? '',
        'nombre_personnes_a_charge': nombrePersonnesCharge,
        'telephone': identite['telephone1'] ?? '',
        'cin': _buildCinData(identite['cin']),
        'commune_nom': identite['commune'] ?? 'Non spécifié',
        'fokontany_nom': identite['fokontany'] ?? 'Non spécifié',
        'nombre_enfants': nombreEnfants,
        'telephone2': identite['telephone2'] ?? '',
      },
      'parcelles': [
        {
          'nom': parcelle['nom'] ?? 'Parcelle ${identite['nom']} ${identite['prenom']}',
          'superficie': superficie,
          'gps': gpsData,
          'geom': geomData,
          'description': parcelle['description'] ?? 'Rizière en terrasse',
        }
      ],
      'questionnaire_parcelles': _buildQuestionnaireData(formData.questionnaire_parcelles),
    };
  }

  // Fonction utilitaire pour convertir Map<dynamic, dynamic> en Map<String, dynamic>
  Map<String, dynamic> _convertToStringMap(dynamic originalMap) {
    if (originalMap == null) return {};
    if (originalMap is! Map) return {};

    final Map<String, dynamic> result = {};
    originalMap.forEach((key, value) {
      final String stringKey = key.toString();
      result[stringKey] = value;
    });
    return result;
  }

  // Fonctions utilitaires
  int _safeInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is double) return value.toInt();
    return defaultValue;
  }

  double _safeDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  dynamic _buildCinData(dynamic cinData) {
    if (cinData == null) return null;
    if (cinData is Map) return _convertToStringMap(cinData);
    if (cinData is String) return {'numero': cinData};
    return null;
  }

  dynamic _buildGeomData(Map<String, dynamic> parcelle) {
    return {
      'type': 'Point',
      'coordinates': [
        _safeDouble(parcelle['longitude'], 47.5078),
        _safeDouble(parcelle['latitude'], -18.879)
      ]
    };
  }

  dynamic _buildQuestionnaireData(dynamic questionnaire) {
    if (questionnaire == null) return [];

    // Si c'est déjà une List, la retourner
    if (questionnaire is List) {
      if (questionnaire.isEmpty) return [];

      // Nettoyer chaque élément de la liste
      return questionnaire.map((item) {
        if (item is Map) {
          return _convertToStringMap(item);
        }
        return item;
      }).toList();
    }

    // Si c'est une Map, la mettre dans un tableau
    if (questionnaire is Map) {
      return [_convertToStringMap(questionnaire)];
    }

    // Par défaut, retourner un tableau vide
    return [];
  }

  /// Sécurise les données GPS
  Map<String, dynamic> _safeGpsData(dynamic gpsData) {
    if (gpsData is Map) {
      final safeMap = _convertToStringMap(gpsData);
      return {
        'latitude': _safeDouble(safeMap['latitude'], -18.879),
        'longitude': _safeDouble(safeMap['longitude'], 47.5078),
        'altitude': _safeDouble(safeMap['altitude'], 1280.0),
      };
    }

    // Fallback si gpsData n'existe pas ou est invalide
    return {
      'latitude': -18.879,
      'longitude': 47.5078,
      'altitude': 1280.0,
    };
  }

  /// Vérifie si un UUID existe déjà dans le fichier master
  Future<bool> uuidExistsInMaster(String uuid) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final masterFile = File('${directory.path}/$MASTER_JSON_FILENAME');

      if (!await masterFile.exists()) {
        return false;
      }

      final content = await masterFile.readAsString();
      final forms = jsonDecode(content) as List<dynamic>;

      return forms.any((form) {
        final individu = form['individu'] as Map<String, dynamic>?;
        return individu?['uuid'] == uuid;
      });

    } catch (e) {
      print('❌ Erreur vérification UUID: $e');
      return false;
    }
  }

  /// Vérifie si un CIN existe déjà dans le fichier master
  Future<bool> cinExistsInMaster(String numeroCIN) async {
    if (numeroCIN.isEmpty) return false;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final masterFile = File('${directory.path}/$MASTER_JSON_FILENAME');

      if (!await masterFile.exists()) {
        return false;
      }

      final content = await masterFile.readAsString();
      final forms = jsonDecode(content) as List<dynamic>;

      return forms.any((form) {
        final individu = form['individu'] as Map<String, dynamic>?;
        final cin = individu?['cin'] as Map<String, dynamic>?;
        final formCIN = cin?['numero']?.toString().trim() ?? '';
        return formCIN == numeroCIN;
      });

    } catch (e) {
      print('❌ Erreur vérification CIN: $e');
      return false;
    }
  }

  /// Récupère les statistiques du fichier master
  Future<Map<String, dynamic>> getMasterStats() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final masterFile = File('${directory.path}/$MASTER_JSON_FILENAME');

      if (!await masterFile.exists()) {
        return {
          'exists': false,
          'total_forms': 0,
        };
      }

      final content = await masterFile.readAsString();
      final forms = jsonDecode(content) as List<dynamic>;

      // Obtenir la date de création du fichier
      final stat = await masterFile.stat();

      return {
        'exists': true,
        'file_path': masterFile.path,
        'file_size': await masterFile.length(),
        'total_forms': forms.length,
        'created_at': stat.modified.toIso8601String(),
        'last_updated': stat.modified.toIso8601String(),
      };

    } catch (e) {
      print('❌ Erreur récupération stats: $e');
      return {
        'exists': false,
        'error': e.toString(),
      };
    }
  }

  /// Exporte le fichier master vers un emplacement spécifique
  Future<String?> exportMasterFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final masterFile = File('${directory.path}/$MASTER_JSON_FILENAME');

      if (!await masterFile.exists()) {
        print('❌ Fichier master introuvable');
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final exportFile = File('${directory.path}/export_master_$timestamp.json');

      await masterFile.copy(exportFile.path);
      print('✅ Master exporté: ${exportFile.path}');

      return exportFile.path;

    } catch (e) {
      print('❌ Erreur export master: $e');
      return null;
    }
  }

  /// Crée une sauvegarde du fichier master existant
  Future<void> _createBackup(File masterFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/$BACKUP_FOLDER');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${backupDir.path}/master_backup_$timestamp.json');

      await masterFile.copy(backupFile.path);
      print('💾 Sauvegarde créée: ${backupFile.path}');

      // Garder seulement les 5 dernières sauvegardes
      await _cleanOldBackups(backupDir);

    } catch (e) {
      print('⚠️ Erreur création sauvegarde: $e');
    }
  }

  /// Nettoie les anciennes sauvegardes (garde les 5 plus récentes)
  Future<void> _cleanOldBackups(Directory backupDir) async {
    try {
      final backups = backupDir
          .listSync()
          .where((file) => file.path.contains('master_backup_'))
          .toList();

      if (backups.length > 5) {
        // Trier par date (du plus ancien au plus récent)
        backups.sort((a, b) => a.path.compareTo(b.path));

        // Supprimer les plus anciens
        for (var i = 0; i < backups.length - 5; i++) {
          await backups[i].delete();
          print('🗑️ Ancienne sauvegarde supprimée: ${backups[i].path}');
        }
      }
    } catch (e) {
      print('⚠️ Erreur nettoyage sauvegardes: $e');
    }
  }
}