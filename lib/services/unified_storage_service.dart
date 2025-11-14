import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/form_data.dart';

/// Service de gestion du stockage unifié (tous les formulaires dans un seul fichier JSON)
class UnifiedStorageService {
  static const String _mainFileName = 'formulaires_agriculture.json';

  /// Générer un UUID unique
  String generateUuid(String nom, String prenom) {
    return '${DateTime.now().millisecondsSinceEpoch}-$nom-$prenom'
        .replaceAll(' ', '_')
        .toLowerCase();
  }

  /// Obtenir le chemin du fichier JSON principal
  Future<File> _getMainFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    final projectDir = Directory('${appDir.path}/formulaires_agriculture');

    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
    }

    return File('${projectDir.path}/$_mainFileName');
  }

  /// Lire tous les formulaires depuis le fichier JSON
  Future<Map<String, dynamic>> _readAllForms() async {
    try {
      final file = await _getMainFile();

      if (!await file.exists()) {
        return {};
      }

      final content = await file.readAsString();
      if (content.isEmpty) {
        return {};
      }

      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      print('Erreur lecture formulaires: $e');
      return {};
    }
  }

  /// Écrire tous les formulaires dans le fichier JSON
  Future<void> _writeAllForms(Map<String, dynamic> allForms) async {
    try {
      final file = await _getMainFile();
      final jsonData = JsonEncoder.withIndent('  ').convert(allForms);
      await file.writeAsString(jsonData);
    } catch (e) {
      throw Exception('Erreur écriture formulaires: $e');
    }
  }

  /// Sauvegarder un nouveau formulaire (ou mettre à jour un existant)
  Future<String> saveFormData(FormData formData) async {
    try {
      // Lire tous les formulaires existants
      final allForms = await _readAllForms();

      // Ajouter/Mettre à jour le formulaire avec son UUID comme clé
      allForms[formData.uuid] = formData.toJson();

      // Écrire le fichier mis à jour
      await _writeAllForms(allForms);

      final file = await _getMainFile();
      return file.path;
    } catch (e) {
      throw Exception('Erreur sauvegarde formulaire: $e');
    }
  }

  /// Récupérer un formulaire spécifique par UUID
  Future<FormData?> getFormByUuid(String uuid) async {
    try {
      final allForms = await _readAllForms();

      if (!allForms.containsKey(uuid)) {
        return null;
      }

      return FormData.fromJson(allForms[uuid] as Map<String, dynamic>);
    } catch (e) {
      print('Erreur récupération formulaire: $e');
      return null;
    }
  }

  /// Récupérer tous les formulaires
  Future<List<FormData>> getAllForms() async {
    try {
      final allForms = await _readAllForms();
      final formsList = <FormData>[];

      allForms.forEach((uuid, data) {
        try {
          formsList.add(FormData.fromJson(data as Map<String, dynamic>));
        } catch (e) {
          print('Erreur parsing formulaire $uuid: $e');
        }
      });

      return formsList;
    } catch (e) {
      print('Erreur récupération tous formulaires: $e');
      return [];
    }
  }

  /// Supprimer un formulaire par UUID
  Future<bool> deleteFormByUuid(String uuid) async {
    try {
      final allForms = await _readAllForms();

      if (!allForms.containsKey(uuid)) {
        return false;
      }

      allForms.remove(uuid);
      await _writeAllForms(allForms);
      return true;
    } catch (e) {
      print('Erreur suppression formulaire: $e');
      return false;
    }
  }

  /// Compter le nombre total de formulaires
  Future<int> getFormsCount() async {
    final allForms = await _readAllForms();
    return allForms.length;
  }

  /// Rechercher des formulaires par nom/prénom
  Future<List<FormData>> searchForms(String query) async {
    try {
      final allForms = await getAllForms();
      final searchQuery = query.toLowerCase();

      return allForms.where((form) {
        final nom = (form.identite['nom'] ?? '').toString().toLowerCase();
        final prenom = (form.identite['prenom'] ?? '').toString().toLowerCase();
        return nom.contains(searchQuery) || prenom.contains(searchQuery);
      }).toList();
    } catch (e) {
      print('Erreur recherche formulaires: $e');
      return [];
    }
  }

  /// Exporter tous les formulaires dans un fichier séparé (backup)
  Future<String?> exportAllForms() async {
    try {
      final allForms = await _readAllForms();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final appDir = await getApplicationDocumentsDirectory();
      final backupFile = File('${appDir.path}/backup_formulaires_$timestamp.json');

      final jsonData = JsonEncoder.withIndent('  ').convert(allForms);
      await backupFile.writeAsString(jsonData);

      return backupFile.path;
    } catch (e) {
      print('Erreur export formulaires: $e');
      return null;
    }
  }

  /// Importer des formulaires depuis un fichier de backup
  Future<bool> importForms(String filePath) async {
    try {
      final importFile = File(filePath);

      if (!await importFile.exists()) {
        return false;
      }

      final content = await importFile.readAsString();
      final importedForms = jsonDecode(content) as Map<String, dynamic>;

      // Fusionner avec les formulaires existants
      final allForms = await _readAllForms();
      allForms.addAll(importedForms);

      await _writeAllForms(allForms);
      return true;
    } catch (e) {
      print('Erreur import formulaires: $e');
      return false;
    }
  }

  /// Obtenir les statistiques des formulaires
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final allForms = await getAllForms();

      final Map<String, int> parRegion = {};
      final Map<String, int> parCommune = {};
      final Map<String, int> parTypeContrat = {};
      DateTime? lastDate;

      for (var form in allForms) {
        // Par région
        final region = form.identite['region']?.toString() ?? 'Non spécifié';
        parRegion[region] = (parRegion[region] ?? 0) + 1;

        // Par commune
        final commune = form.identite['commune']?.toString() ?? 'Non spécifié';
        parCommune[commune] = (parCommune[commune] ?? 0) + 1;

        // Par type de contrat
        final typeContrat = form.parcelle['type_contrat']?.toString() ?? 'Non spécifié';
        parTypeContrat[typeContrat] = (parTypeContrat[typeContrat] ?? 0) + 1;

        // Dernière date
        if (form.metadata['timestamp'] != null) {
          final date = DateTime.parse(form.metadata['timestamp']!);
          if (lastDate == null || date.isAfter(lastDate)) {
            lastDate = date;
          }
        }
      }

      return {
        'total': allForms.length,
        'par_region': parRegion,
        'par_commune': parCommune,
        'par_type_contrat': parTypeContrat,
        'dernier_ajout': lastDate?.toIso8601String(),
      };
    } catch (e) {
      print('Erreur calcul statistiques: $e');
      return {'total': 0};
    }
  }

  /// Vérifier si un UUID existe déjà
  Future<bool> uuidExists(String uuid) async {
    final allForms = await _readAllForms();
    return allForms.containsKey(uuid);
  }

  /// Nettoyer les doublons (même nom/prénom mais UUID différents)
  Future<int> cleanDuplicates() async {
    try {
      final allForms = await getAllForms();
      final uniqueForms = <String, FormData>{};
      int duplicatesCount = 0;

      for (var form in allForms) {
        final key = '${form.identite['nom']}_${form.identite['prenom']}'.toLowerCase();

        if (!uniqueForms.containsKey(key)) {
          uniqueForms[key] = form;
        } else {
          // Garder le plus récent
          final existingDate = DateTime.parse(uniqueForms[key]!.metadata['timestamp'] ?? '2000-01-01');
          final currentDate = DateTime.parse(form.metadata['timestamp'] ?? '2000-01-01');

          if (currentDate.isAfter(existingDate)) {
            uniqueForms[key] = form;
          }
          duplicatesCount++;
        }
      }

      // Reconstruire le fichier avec les formulaires uniques
      final cleanedForms = <String, dynamic>{};
      uniqueForms.forEach((key, form) {
        cleanedForms[form.uuid] = form.toJson();
      });

      await _writeAllForms(cleanedForms);
      return duplicatesCount;
    } catch (e) {
      print('Erreur nettoyage doublons: $e');
      return 0;
    }
  }
}