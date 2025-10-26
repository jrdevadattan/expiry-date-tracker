import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// OCR service using ML Kit text recognition to extract date-like hints
/// from label images. This runs on-device and returns candidate strings
/// such as 'Best before 2025-12-31' or raw date tokens.
class OcrService {
  static final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract text-based hints from the provided image file.
  /// Returns a list of candidate strings (e.g., 'Best before 2025-12-31').
  static Future<List<String>> extractHints(File image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final result = await _recognizer.processImage(inputImage);

    final rawText = result.text;
    final found = <String>{};

    // Simple date-like patterns and label phrases
    final dateRegex = RegExp(r"\b(\d{4}-\d{2}-\d{2}|\d{2}[.\-/]\d{2}[.\-/]\d{2,4}|\d{2}[.\-/]\d{2}[.\-/]\d{4})\b");
  // Use case-insensitive flag via the RegExp constructor (Dart doesn't support inline (?i))
  final labelRegex = RegExp(r"(best before|use by|use-by|bbd|expiry|exp|mfd)[\s:\-]*([^,;\n]+)", caseSensitive: false);

    // scan lines and blocks
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        for (final m in dateRegex.allMatches(text)) {
          found.add(m.group(0)!.trim());
        }
        final lm = labelRegex.firstMatch(text);
        if (lm != null) {
          final candidate = lm.group(2)!.trim();
          if (candidate.isNotEmpty) found.add(candidate);
        }
      }
    }

    // fallback: also scan the whole recognized text
    for (final m in dateRegex.allMatches(rawText)) found.add(m.group(0)!.trim());

    return found.toList();
  }

  /// Call to release resources when app is disposed (optional).
  static Future<void> dispose() async {
    await _recognizer.close();
  }
}
