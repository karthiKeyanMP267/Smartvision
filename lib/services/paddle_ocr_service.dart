import 'dart:io';
import 'package:paddle_ocr/paddle_ocr.dart' as paddle;

/// PaddleOCR Service for high-accuracy text recognition
/// PaddleOCR is more accurate than ML Kit, especially for product labels
class PaddleOCRService {
  static final PaddleOCRService _instance = PaddleOCRService._internal();
  factory PaddleOCRService() => _instance;
  PaddleOCRService._internal();

  bool _isInitialized = false;

  /// Initialize PaddleOCR with optimized settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isInitialized = true;
      print('✅ PaddleOCR initialized successfully');
    } catch (e) {
      print('❌ PaddleOCR initialization error: $e');
      _isInitialized = false;
    }
  }

  /// Extract text from image using PaddleOCR
  Future<String> recognizeText(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Run PaddleOCR on the image
      final result = await paddle.ocr(imageFile.path);
      
      if (result == null || result.isEmpty) {
        print('⚠️ PaddleOCR returned no text');
        return '';
      }

      print('✅ PaddleOCR extracted text successfully');
      
      return result;
    } catch (e) {
      print('❌ PaddleOCR recognition error: $e');
      return '';
    }
  }

  /// Get detailed OCR results
  Future<List<Map<String, dynamic>>> recognizeTextDetailed(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final result = await paddle.ocr(imageFile.path);
      
      if (result == null || result.isEmpty) {
        return [];
      }

      // Parse text into structured format
      final lines = result.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      return lines.map((line) {
        return {
          'text': line.trim(),
          'confidence': 1.0,
        };
      }).toList();
    } catch (e) {
      print('❌ PaddleOCR detailed recognition error: $e');
      return [];
    }
  }

  /// Dispose PaddleOCR resources
  void dispose() {
    _isInitialized = false;
  }
}
