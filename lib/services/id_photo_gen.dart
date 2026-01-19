import 'package:image/image.dart' as img;
import '../core/photo_standards.dart';
// import 'dart:math'; // No longer needed since we don't use max()

class IdPhotoGenerator {
  
  Map<String, img.Image> generateAllPreviews(img.Image personCutout) {
    Map<String, img.Image> previews = {};

    // 1. Trim transparency
    img.Image content = img.trim(personCutout, mode: img.TrimMode.transparent);

    for (var size in availableSizes) {
      img.Image canvas = img.Image(width: size.pixelWidth, height: size.pixelHeight);
      img.fill(canvas, color: img.ColorRgba8(255, 255, 255, 255));

      // 2. SCALE LOGIC UPDATE: FIT WIDTH
      // Old Logic: max(scaleX, scaleY) -> Zoomed in and cut shoulders.
      // New Logic: scaleX -> Fits the shoulders perfectly.
      double scale = size.pixelWidth / content.width;

      int newWidth = (content.width * scale).round();
      int newHeight = (content.height * scale).round();

      img.Image scaledPerson = img.copyResize(
        content, 
        width: newWidth, 
        height: newHeight, 
        interpolation: img.Interpolation.linear
      );

      // 3. POSITION LOGIC
      // Center Horizontally
      int dstX = (size.pixelWidth - newWidth) ~/ 2;
      
      // Top Align with small "Headroom" (Padding)
      // Gives a cleaner, more professional look (approx 3% of height)
      int dstY = (size.pixelHeight * 0.03).round(); 

      img.compositeImage(canvas, scaledPerson, dstX: dstX, dstY: dstY);

      previews[size.label] = canvas;
    }
    return previews;
  }
}