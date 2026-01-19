import 'dart:typed_data';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:image/image.dart' as img;

class SegmentationService {
  final SubjectSegmenter _segmenter = SubjectSegmenter(
    options: SubjectSegmenterOptions(
      enableForegroundBitmap: true,
      enableForegroundConfidenceMask: false,
      enableMultipleSubjects: SubjectResultOptions(
        enableConfidenceMask: false,
        enableSubjectBitmap: false
      )
    ),
  );

  Future<img.Image?> removeBackground(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);

    try {
      final result = await _segmenter.processImage(inputImage);
      final foregroundBitmap = result.foregroundBitmap;

      if (foregroundBitmap == null) return null;

      // Decode the raw bytes into an editable Image object
      return img.decodeImage(Uint8List.fromList(foregroundBitmap));
    } catch (e) {
      print("Error in segmentation: $e");
      return null;
    }
  }

  void dispose() {
    _segmenter.close();
  }
}