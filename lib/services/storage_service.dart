import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/form_data.dart';

/// Service de gestion du stockage local
class StorageService {
  /// Générer un UUID unique
  String generateUuid(String nom, String prenom) {
    return '${DateTime.now().millisecondsSinceEpoch}-$nom-$prenom'
        .replaceAll(' ', '_')
        .toLowerCase();
  }

  /// Sauvegarder les données JSON dans l'application
  Future<String> saveFormDataToApp(FormData formData) async {
    final appDir = await getApplicationDocumentsDirectory();
    final projectFormsDir = Directory('${appDir.path}/formulaires_agriculture');

    if (!await projectFormsDir.exists()) {
      await projectFormsDir.create(recursive: true);
    }

    final jsonData = JsonEncoder.withIndent('  ').convert(formData.toJson());
    final fileName = 'formulaire_${formData.identite['nom']}_${formData.identite['prenom']}_${formData.uuid}.json'
        .replaceAll(' ', '_')
        .toLowerCase();

    final appFile = File('${projectFormsDir.path}/$fileName');
    await appFile.writeAsString(jsonData);

    return appFile.path;
  }

  /// Essayer de sauvegarder dans le stockage externe
  Future<void> trySaveToExternalStorage(String jsonData, String fileName) async {
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final externalFormsDir = Directory('${externalDir.path}/FormulairesAgriculture');
        if (!await externalFormsDir.exists()) {
          await externalFormsDir.create(recursive: true);
        }
        final externalFile = File('${externalFormsDir.path}/$fileName');
        await externalFile.writeAsString(jsonData);
        print('Sauvegarde externe réussie: ${externalFile.path}');
      }

      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final downloadsFile = File('${downloadsDir.path}/$fileName');
        await downloadsFile.writeAsString(jsonData);
        print('Sauvegarde téléchargements réussie: ${downloadsFile.path}');
      }
    } catch (e) {
      print('Sauvegarde externe échouée: $e');
    }
  }

  /// Sauvegarder la liste des photos à uploader
  Future<void> saveUploadList(List<Map<String, String>> photosToUpload) async {
    final appDir = await getApplicationDocumentsDirectory();
    final uploadListFile = File('${appDir.path}/upload_list.json');
    List<dynamic> existingList = [];

    if (await uploadListFile.exists()) {
      final content = await uploadListFile.readAsString();
      existingList = jsonDecode(content) as List<dynamic>;
    }

    existingList.addAll(photosToUpload);
    await uploadListFile.writeAsString(
        JsonEncoder.withIndent('  ').convert(existingList));
  }

  /// Préparer les données pour l'API
  Future<void> prepareApiUpload(FormData formData, String appDirPath) async {
    final apiDir = Directory('$appDirPath/api_ready');

    if (!await apiDir.exists()) {
      await apiDir.create(recursive: true);
    }

    final apiDataFile = File('${apiDir.path}/${formData.uuid}_data.json');
    await apiDataFile.writeAsString(
        JsonEncoder.withIndent('  ').convert(formData.toJson()));
  }

  /// Ouvrir l'emplacement du fichier
  Future<void> openFileLocation(String path) async {
    if (Platform.isWindows) {
      await Process.run('explorer', [path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
    }
  }
}