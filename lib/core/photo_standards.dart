enum PhotoCategory { id, rSeries, aSeries, custom }

class PhotoSize {
  final String label;
  final double widthInches;
  final double heightInches;
  final PhotoCategory category;

  const PhotoSize(this.label, this.widthInches, this.heightInches, this.category);

  // 300 DPI (Dots Per Inch) for printing
  int get pixelWidth => (widthInches * 300).round();
  int get pixelHeight => (heightInches * 300).round();
}

const List<PhotoSize> availableSizes = [
  PhotoSize("1x1 ID", 1.0, 1.0, PhotoCategory.id),
  PhotoSize("2x2 ID", 2.0, 2.0, PhotoCategory.id),
  PhotoSize("Wallet (2x3)", 2.0, 3.0, PhotoCategory.custom),
  PhotoSize("2.5x3.5", 2.5, 3.5, PhotoCategory.custom),
  PhotoSize("2R", 2.5, 3.5, PhotoCategory.rSeries),
  PhotoSize("3R", 3.5, 5.0, PhotoCategory.rSeries),
  PhotoSize("4R", 4.0, 6.0, PhotoCategory.rSeries),
  PhotoSize("5R", 5.0, 7.0, PhotoCategory.rSeries),
  PhotoSize("8R", 8.0, 10.0, PhotoCategory.rSeries),
  PhotoSize("A5", 5.83, 8.27, PhotoCategory.aSeries),
  PhotoSize("A4", 8.27, 11.69, PhotoCategory.aSeries),
];