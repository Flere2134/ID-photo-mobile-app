import 'dart:io';
import 'dart:typed_data';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class StorageService {
  Future<bool> saveToGallery(img.Image imageToSave) async {
    try {
      // Check permissions
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      // Convert image to JPG bytes
      Uint8List jpgBytes = Uint8List.fromList(img.encodeJpg(imageToSave));

      // Create temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = await File('${tempDir.path}/id_package_${DateTime.now().millisecondsSinceEpoch}.jpg').create();
      await tempFile.writeAsBytes(jpgBytes);

      // Save to Gallery
      await Gal.putImage(tempFile.path, album: 'ID Photo Magic');
      return true;
    } catch (e) {
      print("Save Error: $e");
      return false;
    }
  }
}