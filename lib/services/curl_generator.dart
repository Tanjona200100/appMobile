import 'dart:io';
import 'image_manager.dart';

/// Service de génération des commandes CURL
class CurlGenerator {
  /// Générer la commande CURL pour l'upload des photos
  Future<void> generateCurlCommand(
      String uuid, String appDirPath, ImageManager imageManager) async {
    final curlFile = File('$appDirPath/upload_commands.txt');

    String curlCommand = 'curl -X POST http://localhost:3000/upload_photos_massif \\\n';
    bool hasPhotos = false;

    if (imageManager.portraitImageFile != null) {
      final imageName = '${uuid}_portrait.${imageManager.portraitImageFile!.path.split('.').last}';
      curlCommand += '  -F "uuid[]=$uuid" -F "photo_type[]=portrait" -F "file[]=@$appDirPath/images_formulaires/$imageName" \\\n';
      hasPhotos = true;
    }

    if (imageManager.cinRectoImageFile != null) {
      final imageName = '${uuid}_cin_recto.${imageManager.cinRectoImageFile!.path.split('.').last}';
      curlCommand += '  -F "uuid[]=$uuid" -F "photo_type[]=cin_recto" -F "file[]=@$appDirPath/images_formulaires/$imageName" \\\n';
      hasPhotos = true;
    }

    if (imageManager.cinVersoImageFile != null) {
      final imageName = '${uuid}_cin_verso.${imageManager.cinVersoImageFile!.path.split('.').last}';
      curlCommand += '  -F "uuid[]=$uuid" -F "photo_type[]=cin_verso" -F "file[]=@$appDirPath/images_formulaires/$imageName" \\\n';
      hasPhotos = true;
    }

    if (imageManager.parcelleImageFile != null) {
      final imageName = '${uuid}_photo_parcelle.${imageManager.parcelleImageFile!.path.split('.').last}';
      curlCommand += '  -F "uuid[]=$uuid" -F "photo_type[]=photo_parcelle" -F "file[]=@$appDirPath/images_formulaires/$imageName" \\\n';
      hasPhotos = true;
    }

    if (hasPhotos) {
      if (curlCommand.endsWith('\\\n')) {
        curlCommand = curlCommand.substring(0, curlCommand.length - 3);
      }

      await curlFile.writeAsString('$curlCommand\n\n', mode: FileMode.append);

      print('=== COMMANDE CURL GÉNÉRÉE ===');
      print(curlCommand);
      print('=============================');
    }
  }
}