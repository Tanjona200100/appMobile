import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Service de gestion des images
class ImageManager {
  final ImagePicker _imagePicker = ImagePicker();

  // Variables pour les images
  File? cinRectoImageFile;
  File? cinVersoImageFile;
  File? parcelleImageFile;
  File? portraitImageFile;

  String? cinRectoImagePath;
  String? cinVersoImagePath;
  String? parcelleImagePath;
  String? portraitImagePath;

  /// Sélectionner une image
  Future<void> pickImage(String imageType) async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final path = pickedFile.path;

      switch (imageType) {
        case 'cin_recto':
          cinRectoImageFile = file;
          cinRectoImagePath = path;
          break;
        case 'cin_verso':
          cinVersoImageFile = file;
          cinVersoImagePath = path;
          break;
        case 'parcelle':
          parcelleImageFile = file;
          parcelleImagePath = path;
          break;
        case 'portrait':
          portraitImageFile = file;
          portraitImagePath = path;
          break;
      }
    }
  }

  /// Supprimer une image
  void removeImage(String imageType) {
    switch (imageType) {
      case 'cin_recto':
        cinRectoImageFile = null;
        cinRectoImagePath = null;
        break;
      case 'cin_verso':
        cinVersoImageFile = null;
        cinVersoImagePath = null;
        break;
      case 'parcelle':
        parcelleImageFile = null;
        parcelleImagePath = null;
        break;
      case 'portrait':
        portraitImageFile = null;
        portraitImagePath = null;
        break;
    }
  }

  /// Sauvegarder les images dans le répertoire de l'application
  Future<List<Map<String, String>>> saveImagesToAppDirectory(String uuid) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/images_formulaires');

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    List<Map<String, String>> photosToUpload = [];

    if (portraitImageFile != null) {
      final newPath = await _copyImageToAppDirectory(
          portraitImageFile!, uuid, 'portrait', imagesDir.path);
      photosToUpload.add({
        'uuid': uuid,
        'photo_type': 'portrait',
        'file_path': newPath
      });
    }

    if (cinRectoImageFile != null) {
      final newPath = await _copyImageToAppDirectory(
          cinRectoImageFile!, uuid, 'cin_recto', imagesDir.path);
      photosToUpload.add({
        'uuid': uuid,
        'photo_type': 'cin_recto',
        'file_path': newPath
      });
    }

    if (cinVersoImageFile != null) {
      final newPath = await _copyImageToAppDirectory(
          cinVersoImageFile!, uuid, 'cin_verso', imagesDir.path);
      photosToUpload.add({
        'uuid': uuid,
        'photo_type': 'cin_verso',
        'file_path': newPath
      });
    }

    if (parcelleImageFile != null) {
      final newPath = await _copyImageToAppDirectory(
          parcelleImageFile!, uuid, 'photo_parcelle', imagesDir.path);
      photosToUpload.add({
        'uuid': uuid,
        'photo_type': 'photo_parcelle',
        'file_path': newPath
      });
    }

    return photosToUpload;
  }

  /// Copier une image vers le répertoire de l'application
  Future<String> _copyImageToAppDirectory(
      File originalFile, String uuid, String photoType, String imagesDirPath) async {
    final extension = originalFile.path.split('.').last;
    final newFileName = '${uuid}_${photoType}.$extension';
    final newFile = File('$imagesDirPath/$newFileName');
    await originalFile.copy(newFile.path);
    return newFile.path;
  }

  /// Réinitialiser toutes les images
  void clear() {
    cinRectoImageFile = null;
    cinVersoImageFile = null;
    parcelleImageFile = null;
    portraitImageFile = null;
    cinRectoImagePath = null;
    cinVersoImagePath = null;
    parcelleImagePath = null;
    portraitImagePath = null;
  }

  /// Obtenir le nom du fichier depuis le chemin
  String getFileName(String? path) {
    if (path == null) return '';
    return path.split('/').last;
  }

  /// Obtenir la taille du fichier
  String getFileSize(File? file) {
    if (file == null) return '0 KB';
    final size = file.lengthSync();
    if (size < 1024) {
      return '$size B';
    } else if (size < 1048576) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / 1048576).toStringAsFixed(1)} MB';
    }
  }

  getImageFile(String imageType) {}

  getImagePath(String imageType) {}
}