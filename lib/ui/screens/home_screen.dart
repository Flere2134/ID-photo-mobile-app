import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'editor_screen.dart';

class HomeScreen extends StatelessWidget {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(BuildContext context) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditorScreen(imagePath: image.path)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ID Photo Magic")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_enhance, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pickImage(context),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text("Select Photo to Start"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}