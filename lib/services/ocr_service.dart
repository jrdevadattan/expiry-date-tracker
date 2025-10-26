import 'dart:io';

/// OCR service stub. Full implementation would use ML Kit text recognition
/// (e.g. google_mlkit_text_recognition) to extract text from a label image
/// and return candidate date-like strings. This stub preserves the API for
/// later wiring and currently returns an empty list.
class OcrService {
  /// Extract text-based hints from the provided image file.
  /// Returns a list of candidate strings (e.g., 'Best before 2025-12-31').
  static Future<List<String>> extractHints(File image) async {
    // TODO: implement using google_mlkit_text_recognition
    return <String>[];
  }
}
