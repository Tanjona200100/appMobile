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
    final identite = localData['identite'] as Map<String, dynamic>? ?? {};
    final parcelle = localData['parcelle'] as Map<String, dynamic>? ?? {};
    final metadata = localData['metadata'] as Map<String, dynamic>? ?? {};
    final questionnaire = localData['questionnaire_parcelles'] as List<dynamic>?;

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
        'user_id': metadata['agent_id'] ?? 1,
        'commune_id': 2,
        'nom_pere': identite['nom_pere'],
        'nom_mere': identite['nom_mere'],
        'profession': identite['metier'],
        'activites_complementaires': identite['activites_complementaires'],
        'statut_matrimonial': identite['statut_matrimonial'],
        'nombre_personnes_a_charge': identite['nombre_personnes_charge'],
        'telephone': identite['telephone1'],
        'cin': identite['cin'],
        'commune_nom': identite['commune'],
        'fokontany_nom': identite['fokontany'],
        'nombre_enfants': identite['nombre_enfants'],
        'telephone2': identite['telephone2'],
      },
      'parcelles': [
        {
          'nom': parcelle['nom'],
          'superficie': parcelle['superficie'],
          'gps': parcelle['gps'],
          'geom': parcelle['geom'],
          'description': parcelle['description'],
        }
      ],
      'questionnaire_parcelles': questionnaire,
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

      final cin = formData.identite['cin'] as Map<String, dynamic>?;
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
    // Convertir en format API complet
    return {
      'individu': {
        'uuid': formData.uuid,
        'nom': formData.identite['nom'],
        'prenom': formData.identite['prenom'],
        'surnom': formData.identite['surnom'],
        'sexe': formData.identite['sexe'],
        'date_naissance': formData.identite['date_naissance'],
        'lieu_naissance': formData.identite['lieu_naissance'],
        'adresse': formData.identite['adresse'],
        'gps_point': '${formData.parcelle['latitude']},${formData.parcelle['longitude']}',
        'photo': '', // À adapter selon votre gestion d'images
        'user_id': formData.metadata['agent_id'] ?? 1,
        'commune_id': 2, // À adapter selon vos besoins
        'nom_pere': formData.identite['nom_pere'],
        'nom_mere': formData.identite['nom_mere'],
        'profession': formData.identite['metier'],
        'activites_complementaires': formData.identite['activites_complementaires'],
        'statut_matrimonial': formData.identite['statut_matrimonial'],
        'nombre_personnes_a_charge': formData.identite['nombre_personnes_charge'],
        'telephone': formData.identite['telephone1'],
        'cin': formData.identite['cin'],
        'commune_nom': formData.identite['commune'],
        'fokontany_nom': formData.identite['fokontany'],
        'nombre_enfants': formData.identite['nombre_enfants'],
        'telephone2': formData.identite['telephone2'],
      },
      'parcelles': [
        {
          'nom': formData.parcelle['nom'],
          'superficie': formData.parcelle['superficie'],
          'gps': formData.parcelle['gps'],
          'geom': formData.parcelle['geom'],
          'description': formData.parcelle['description'],
        }
      ],
      'questionnaire_parcelles': formData.questionnaire_parcelles,
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