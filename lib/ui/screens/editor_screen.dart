// lib/ui/screens/editor_screen.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // Required for 'compute'
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../core/photo_standards.dart';
import '../../services/segmentation_services.dart';
import '../../services/id_photo_gen.dart';
import '../../services/package_gen.dart';
import '../../services/storage.dart';

class EditorScreen extends StatefulWidget {
  final String imagePath;
  const EditorScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  _EditorScreenState createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  // Services
  final _segService = SegmentationService();
  final _idGen = IdPhotoGenerator();
  // Note: PackageGenerator is now instantiated inside the background thread, not here.
  final _storage = StorageService();

  // State Variables
  bool isLoading = true;
  img.Image? personCutout;
  Map<String, img.Image> previews = {};
  List<PhotoSize> cart = []; 

  @override
  void initState() {
    super.initState();
    _processImage();
  }

// 1. REMOVE BACKGROUND & OPTIMIZE
  Future<void> _processImage() async {
    // A. Run segmentation
    img.Image? cutout = await _segService.removeBackground(widget.imagePath);
    
    if (cutout != null) {
      // --- OPTIMIZATION START ---
      // B. Smart Resize: If the image is huge (e.g. 4000px from camera), 
      // shrink it to a reasonable size (e.g. 1200px).
      // This makes generating previews and saving INSTANT without losing visible quality.
      if (cutout.height > 1200) {
        cutout = img.copyResize(cutout, height: 1200, interpolation: img.Interpolation.average);
      }
      // --- OPTIMIZATION END ---

      // C. Generate previews (Now fast enough to run on main thread!)
      final generated = _idGen.generateAllPreviews(cutout);
      
      setState(() {
        personCutout = cutout;
        previews = generated;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      _showError("Could not detect a person. Please try a different photo.");
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("OK")
          )
        ],
      ),
    );
  }

  // 2. ADD TO CART
  void _addToCart(String label) {
    final sizeObj = availableSizes.firstWhere((s) => s.label == label);
    setState(() {
      cart.add(sizeObj);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Added $label to package"), 
        duration: Duration(milliseconds: 500)
      ),
    );
  }

  // 3. SAVE PACKAGE (FIXED: Runs in Background to prevent freezing)
  Future<void> _savePackage() async {
    if (cart.isEmpty || personCutout == null) return;

    setState(() => isLoading = true);

    try {
      // --- BACKGROUND WORK START ---
      // We send the heavy data (Image + Cart) to a separate thread
      final sheet = await compute(
        _generateSheetInBackground, 
        GenerateArgs(personCutout!, cart)
      );
      // --- BACKGROUND WORK END ---

      // Now back on the Main UI thread, we save to Gallery
      final success = await _storage.saveToGallery(sheet);

      setState(() => isLoading = false);
      
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(success ? "Success!" : "Failed"),
          content: Text(success 
            ? "Your photo package has been saved to your Gallery." 
            : "Could not save photo to device storage."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text("OK")
            )
          ],
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      print("Error generating package: $e");
      _showError("An error occurred while generating the package.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Processing... This may take a moment."),
            ],
          ),
        )
      );
    }

    if (personCutout == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Error")),
        body: Center(child: Text("Could not process image.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Create Package"),
        actions: [
          Center(
            child: Text(
              "Items: ${cart.length}  ", 
              style: TextStyle(fontWeight: FontWeight.bold)
            )
          ),
          IconButton(
            icon: Icon(Icons.save_alt),
            onPressed: cart.isEmpty ? null : _savePackage,
          )
        ],
      ),
      body: Column(
        children: [
          // Instructions
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Tap '+' to add photos to your printable sheet.",
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
            ),
          ),
          // Grid of Sizes
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: previews.length,
              itemBuilder: (context, index) {
                String label = previews.keys.elementAt(index);
                img.Image raw = previews.values.elementAt(index);
                
                // Display: Encode to JPG for Flutter UI
                Uint8List bytes = Uint8List.fromList(img.encodeJpg(raw));

                return Card(
                  elevation: 4,
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.memory(bytes, fit: BoxFit.contain),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          label, 
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.add_circle, color: Colors.blue),
                          onPressed: () => _addToCart(label),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- BACKGROUND ISOLATION HELPERS ---
// These must be TOP-LEVEL functions (outside any class)

class GenerateArgs {
  final img.Image person;
  final List<PhotoSize> cart;
  GenerateArgs(this.person, this.cart);
}

img.Image _generateSheetInBackground(GenerateArgs args) {
  // 1. Create a NEW instance of the generator inside this new thread
  final generator = PackageGenerator();
  
  // 2. Run the heavy logic (Sorting, resizing, pasting)
  return generator.generatePrintableSheet(args.person, args.cart);
}