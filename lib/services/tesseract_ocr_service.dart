import 'dart:io';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Tesseract OCR Service with ImageMagick-style preprocessing
/// Provides high-accuracy text extraction with image enhancement
class TesseractOCRService {
  static final TesseractOCRService _instance = TesseractOCRService._internal();
  factory TesseractOCRService() => _instance;
  TesseractOCRService._internal();

  bool _isInitialized = false;

  /// Initialize Tesseract OCR
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _isInitialized = true;
      print('✅ Tesseract OCR initialized');
    } catch (e) {
      print('❌ Tesseract OCR initialization error: $e');
      _isInitialized = false;
    }
  }

  /// Extract text from image with preprocessing (ImageMagick-style)
  Future<String> extractText(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      print('🔧 Preprocessing image with ImageMagick-style enhancements...');
      
      // Preprocess image for better OCR accuracy
      final processedImage = await _preprocessImage(imageFile);
      
      print('📖 Running Tesseract OCR...');
      
      // Run Tesseract OCR with optimized settings
      final text = await FlutterTesseractOcr.extractText(
        processedImage.path,
        language: 'eng', // English language
        args: {
          "psm": "6", // Assume uniform block of text
          "preserve_interword_spaces": "1",
        },
      );

      // Clean up temporary processed image
      if (processedImage.path != imageFile.path) {
        await processedImage.delete();
      }

      print('✅ Tesseract extracted ${text.split('\n').length} lines');
      
      return text.trim();
    } catch (e) {
      print('❌ Tesseract OCR error: $e');
      return '';
    }
  }

  /// Preprocess image using ImageMagick-style techniques
  /// - Increase contrast
  /// - Sharpen edges
  /// - Denoise
  /// - Adjust brightness
  /// - Convert to grayscale
  Future<File> _preprocessImage(File imageFile) async {
    try {
      // Read image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        print('⚠️ Could not decode image, using original');
        return imageFile;
      }

      print('📐 Original: ${image.width}x${image.height}');

      // 1. Convert to grayscale (improves OCR accuracy)
      image = img.grayscale(image);
      
      // 2. Increase contrast (makes text stand out)
      image = img.contrast(image, contrast: 120);
      
      // 3. Adjust brightness using adjustColor
      image = img.adjustColor(image, brightness: 1.1);
      
      // 4. Apply smooth filter for noise reduction and edge enhancement
      image = img.smooth(image, weight: 0.5);
      
      // 5. Denoise (removes artifacts)
      image = img.gaussianBlur(image, radius: 1);
      
      // 6. Resize if too large (improves processing speed)
      if (image.width > 2000 || image.height > 2000) {
        final scale = 2000 / image.width.toDouble();
        image = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
          interpolation: img.Interpolation.linear,
        );
      }

      print('✨ Processed: ${image.width}x${image.height}');

      // Save processed image to temporary file
      final tempDir = await getTemporaryDirectory();
      final processedPath = path.join(
        tempDir.path,
        'processed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      final processedFile = File(processedPath);
      await processedFile.writeAsBytes(img.encodeJpg(image, quality: 95));
      
      print('💾 Saved preprocessed image');
      
      return processedFile;
    } catch (e) {
      print('⚠️ Image preprocessing failed, using original: $e');
      return imageFile;
    }
  }

  /// Extract text with different PSM modes (Page Segmentation Mode)
  /// PSM modes:
  /// - 3: Fully automatic page segmentation (default)
  /// - 6: Assume a uniform block of text
  /// - 7: Treat the image as a single text line
  /// - 11: Sparse text. Find as much text as possible
  Future<String> extractTextWithMode(File imageFile, String psmMode) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final processedImage = await _preprocessImage(imageFile);
      
      final text = await FlutterTesseractOcr.extractText(
        processedImage.path,
        language: 'eng',
        args: {
          "psm": psmMode,
          "preserve_interword_spaces": "1",
        },
      );

      if (processedImage.path != imageFile.path) {
        await processedImage.delete();
      }

      return text.trim();
    } catch (e) {
      print('❌ Tesseract OCR (PSM $psmMode) error: $e');
      return '';
    }
  }

  /// Extract text with best mode auto-detection
  /// Tries multiple PSM modes and returns the best result
  Future<String> extractTextSmart(File imageFile) async {
    print('🎯 Using smart extraction (trying multiple modes)...');
    
    // Try different PSM modes
    final results = await Future.wait([
      extractTextWithMode(imageFile, "6"), // Uniform block
      extractTextWithMode(imageFile, "11"), // Sparse text
      extractTextWithMode(imageFile, "3"), // Automatic
    ]);

    // Return the longest result (usually the most accurate)
    final best = results.reduce((a, b) => a.length > b.length ? a : b);
    
    print('✅ Best result: ${best.split('\n').length} lines');
    
    return best;
  }

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
  }
}
