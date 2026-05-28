import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

final ocrServiceProvider = Provider<OCRService>((ref) {
  return OCRService();
});

class OCRService {
  final ImagePicker _picker = ImagePicker();

  // Capture from camera or gallery
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print("Error picking image: $e");
      throw Exception("Rasm tanlashda xatolik yuz berdi: $e");
    }
  }

  // Perform text extraction using Google ML Kit on-device
  Future<String> extractText(File imageFile) async {
    final InputImage inputImage = InputImage.fromFile(imageFile);
    final TextRecognizer textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      String extractedText = recognizedText.text;
      
      // Clean up resources
      await textRecognizer.close();

      if (extractedText.trim().isEmpty) {
        throw Exception("Rasmda hech qanday matn topilmadi. Iltimos, aniqroq rasm oling.");
      }

      return extractedText;
    } catch (e) {
      await textRecognizer.close();
      print("OCR process failed: $e");
      throw Exception("Matnni aniqlashda xatolik yuz berdi: ${e.toString().split('\n').first}");
    }
  }
}
