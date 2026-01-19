import 'package:image/image.dart' as img;
import '../core/photo_standards.dart';
// import 'dart:math'; 

class PackageGenerator {
  
  img.Image generatePrintableSheet(img.Image personImage, List<PhotoSize> cart) {
    final paper = availableSizes.firstWhere((s) => s.label == "A4");
    
    img.Image sheet = img.Image(width: paper.pixelWidth, height: paper.pixelHeight);
    img.fill(sheet, color: img.ColorRgba8(255, 255, 255, 255));

    cart.sort((a, b) => b.pixelHeight.compareTo(a.pixelHeight));

    int currentX = 0;
    int currentY = 0;
    int currentRowHeight = 0;
    int padding = 20;

    img.Image content = img.trim(personImage, mode: img.TrimMode.transparent);

    for (var size in cart) {
      img.Image photo = _createSinglePhoto(content, size);

      if (currentX + size.pixelWidth > paper.pixelWidth) {
        currentX = 0;
        currentY += currentRowHeight + padding;
        currentRowHeight = 0;
      }

      if (currentY + size.pixelHeight > paper.pixelHeight) {
        continue; 
      }

      img.compositeImage(sheet, photo, dstX: currentX, dstY: currentY);

      currentX += size.pixelWidth + padding;
      if (size.pixelHeight > currentRowHeight) {
        currentRowHeight = size.pixelHeight;
      }
    }
    return sheet;
  }

  img.Image _createSinglePhoto(img.Image trimmedPerson, PhotoSize size) {
     img.Image photo = img.Image(width: size.pixelWidth, height: size.pixelHeight);
     img.fill(photo, color: img.ColorRgba8(255, 255, 255, 255));
     
     // --- SAME NEW LOGIC AS PREVIEW ---
     // Fit Width (Show Shoulders)
     double scale = size.pixelWidth / trimmedPerson.width;

     int newWidth = (trimmedPerson.width * scale).round();
     int newHeight = (trimmedPerson.height * scale).round();

     img.Image scaled = img.copyResize(
       trimmedPerson, 
       width: newWidth, 
       height: newHeight,
       interpolation: img.Interpolation.linear // or .average
     );
     
     int x = (size.pixelWidth - newWidth) ~/ 2;
     // Headroom
     int y = (size.pixelHeight * 0.03).round(); 
     
     img.compositeImage(photo, scaled, dstX: x, dstY: y);
     
     img.drawRect(
       photo, 
       x1: 0, y1: 0, 
       x2: size.pixelWidth-1, y2: size.pixelHeight-1, 
       color: img.ColorRgba8(200, 200, 200, 255)
     );
     
     return photo;
  }
}