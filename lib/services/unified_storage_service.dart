// services/unified_storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/form_data.dart';

class UnifiedStorageService {
  static const String _formsDirectory = 'forms';
  static const String _pendingSyncFile = 'pending_sync.json';

  /// Sauvegarde les données du formulaire
  Future<String> saveFormData(FormData formData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final formsDir = Directory('${directory.path}/$_formsDirectory');

      if (!await formsDir.exists()) {
        await formsDir.create(recursive: true);
      }

      final file = File('${formsDir.path}/${formData.uuid}.json');
      final jsonData = jsonEncode(formData.toJson());
      await file.writeAsString(jsonData);

      return file.path;
    } catch (e) {
      throw Exception('Erreur sauvegarde formulaire: $e');
    }
  }

  /// Récupère tous les formulaires
  Future<List<FormData>> getAllForms() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final formsDir = Directory('${directory.path}/$_formsDirectory');

      if (!await formsDir.exists()) {
        return [];
      }

      final files = formsDir.listSync();
      final forms = <FormData>[];

      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final jsonData = jsonDecode(content);
            forms.add(FormData.fromJson(jsonData));
          } catch (e) {
            print('❌ Erreur lecture fichier ${file.path}: $e');
          }
        }
      }

      // Trier par date (plus récent en premier)
      forms.sort((a, b) {
        final dateA = a.metadata['timestamp'] ?? '';
        final dateB = b.metadata['timestamp'] ?? '';
        return dateB.compareTo(dateA);
      });

      return forms;
    } catch (e) {
      throw Exception('Erreur chargement formulaires: $e');
    }
  }

  /// Récupère un formulaire par UUID
  Future<FormData?> getFormByUuid(String uuid) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_formsDirectory/$uuid.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        final jsonData = jsonDecode(content);
        return FormData.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération formulaire $uuid: $e');
      return null;
    }
  }

  /// Supprime un formulaire par UUID
  Future<bool> deleteFormByUuid(String uuid) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_formsDirectory/$uuid.json');

      if (await file.exists()) {
        await file.delete();
        await removeFromPendingSync(uuid);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur suppression formulaire $uuid: $e');
      return false;
    }
  }

  /// Vérifie si un numéro CIN existe déjà
  Future<bool> cinExists(String numeroCIN) async {
    if (numeroCIN.isEmpty) return false;

    final allForms = await getAllForms();
    return allForms.any((form) {
      final cin = form.identite['cin'] as Map<String, dynamic>? ?? {};
      final existingCIN = cin['numero']?.toString().trim() ?? '';
      return existingCIN.isNotEmpty && existingCIN == numeroCIN.trim();
    });
  }

  /// Vérifie si un UUID existe déjà
  Future<bool> uuidExists(String uuid) async {
    final allForms = await getAllForms();
    return allForms.any((form) => form.uuid == uuid);
  }

  /// Génère un UUID unique basé sur nom et prénom
  String generateUuid(String nom, String prenom) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final namePart = '${nom}_${prenom}'.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return '${namePart}_$timestamp';
  }

  /// Récupère les formulaires en attente de synchronisation
  Future<List<FormData>> getPendingSyncForms() async {
    final allForms = await getAllForms();
    return allForms.where((form) {
      final syncStatus = form.metadata['sync_status']?.toString();
      return syncStatus == 'pending' || syncStatus == 'offline';
    }).toList();
  }

  /// Ajoute un formulaire à la file d'attente de synchronisation
  Future<void> addToPendingSync(FormData formData) async {
    formData.metadata['sync_status'] = 'pending';
    formData.metadata['pending_since'] = DateTime.now().toIso8601String();
    await saveFormData(formData);
  }

  /// Retire un formulaire de la file d'attente
  Future<void> removeFromPendingSync(String uuid) async {
    final form = await getFormByUuid(uuid);
    if (form != null) {
      form.metadata.remove('pending_since');
      await saveFormData(form);
    }
  }

  /// Exporte tous les formulaires
  Future<String?> exportAllForms() async {
    try {
      final allForms = await getAllForms();
      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'total_forms': allForms.length,
        'forms': allForms.map((form) => form.toJson()).toList(),
      };

      final directory = await getApplicationDocumentsDirectory();
      final exportFile = File('${directory.path}/forms_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await exportFile.writeAsString(jsonEncode(exportData));

      return exportFile.path;
    } catch (e) {
      print('❌ Erreur export: $e');
      return null;
    }
  }

  /// Nettoie les doublons
  Future<void> cleanDuplicates() async {
    final allForms = await getAllForms();
    final uniqueForms = <String, FormData>{};
    final seenCINs = <String>{};

    for (final form in allForms) {
      final cin = form.identite['cin'] as Map<String, dynamic>? ?? {};
      final numeroCIN = cin['numero']?.toString().trim() ?? '';
      final uuid = form.uuid;

      bool isDuplicate = false;

      // Vérifier doublon par CIN
      if (numeroCIN.isNotEmpty && seenCINs.contains(numeroCIN)) {
        isDuplicate = true;
        print('🚫 Doublon CIN détecté: $numeroCIN - UUID: $uuid');
      }

      // Vérifier doublon par UUID
      if (uniqueForms.containsKey(uuid)) {
        isDuplicate = true;
        print('🚫 Doublon UUID détecté: $uuid');
      }

      if (!isDuplicate) {
        if (numeroCIN.isNotEmpty) {
          seenCINs.add(numeroCIN);
        }
        uniqueForms[uuid] = form;
      }
    }

    // Sauvegarder les formulaires uniques
    final directory = await getApplicationDocumentsDirectory();
    final formsDir = Directory('${directory.path}/$_formsDirectory');

    // Supprimer tous les fichiers existants
    if (await formsDir.exists()) {
      await formsDir.delete(recursive: true);
    }

    // Recréer le dossier et sauvegarder les formulaires uniques
    await formsDir.create(recursive: true);

    for (final form in uniqueForms.values) {
      final file = File('${formsDir.path}/${form.uuid}.json');
      await file.writeAsString(jsonEncode(form.toJson()));
    }

    print('✅ Nettoyage doublons terminé: ${allForms.length - uniqueForms.length} doublons supprimés');
  }

  Future getFormsByCIN(String numeroCIN) async {}
}