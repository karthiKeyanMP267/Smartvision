import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../models/product_model.dart';
import 'product_catalog_service.dart';
import 'online_product_service.dart';

class RecognitionService {
  static final RecognitionService _instance = RecognitionService._internal();
  factory RecognitionService() => _instance;
  RecognitionService._internal();

  final ImageLabeler _imageLabeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.6),
  );
  
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  // Removed slow services: GeminiAIService and TesseractOCRService for speed

  Future<Product?> recognizeProduct(File imageFile) async {
    try {
      // Use fast ML Kit recognition only (skip slow Tesseract and Gemini)
      print('⚡ Fast recognition using ML Kit...');
      final inputImage = InputImage.fromFile(imageFile);
      
      // Run all recognition tasks in parallel
      final results = await Future.wait([
        _recognizeLabels(inputImage),
        _recognizeText(inputImage),
        _scanBarcode(inputImage),
      ]).timeout(
        const Duration(seconds: 5), // 5 second timeout for everything
        onTimeout: () => [<String>[], '', null],
      );

      final labels = results[0] as List<String>;
      final text = results[1] as String;
      final barcode = results[2] as String?;

      // Create product from recognition results
      if (labels.isEmpty && text.isEmpty && barcode == null) {
        return null;
      }

      // Use online API for intelligent product identification (with shorter timeout)
      final onlineService = OnlineProductService();
      final productInfo = await onlineService.identifyProduct(
        barcode: barcode,
        text: text,
        labels: labels,
      ).timeout(
        const Duration(seconds: 3), // Faster timeout for online service
        onTimeout: () => null,
      );

      if (productInfo != null) {
        return _createProduct(labels, text, barcode,
            forcedName: productInfo.toString(),
            forcedDescription: productInfo.category ?? productInfo.description);
      }

      // Fallback: Prefer catalog matches (by barcode or text)
      final catalog = await ProductCatalogService().load();
      final matchedByBarcode = barcode != null
          ? catalog.getByBarcode(barcode)
          : null;

      if (matchedByBarcode != null) {
        return _createProduct(labels, text, barcode,
            forcedName: matchedByBarcode['name'],
            forcedDescription: matchedByBarcode['description']);
      }

      // Try canonical inference from text + labels
      final inferred = ProductCatalogService.inferCanonicalName(text, labels);

      return _createProduct(labels, text, barcode,
          forcedName: inferred);
    } catch (e) {
      print('Recognition error: $e');
      return null;
    }
  }

  Future<List<String>> _recognizeLabels(InputImage image) async {
    try {
      final labels = await _imageLabeler.processImage(image);
      return labels
          .where((label) => label.confidence > 0.7) // Increased confidence threshold for better quality
          .map((label) => label.label)
          .toList();
    } catch (e) {
      print('Label recognition error: $e');
      return [];
    }
  }

  Future<String> _recognizeText(InputImage image) async {
    try {
      // Fast ML Kit Text Recognition only
      print('📱 Using ML Kit Text Recognition with Latin Script');
      final recognizedText = await _textRecognizer.processImage(image);
      
      // Extract text with better structure and filtering
      final allText = StringBuffer();
      
      // Process text blocks with confidence filtering
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          // Filter by confidence (only include high-confidence text)
          if (line.confidence != null && line.confidence! > 0.6) {
            allText.writeln(line.text);
          } else if (line.confidence == null) {
            // If confidence not available, include all text
            allText.writeln(line.text);
          }
        }
      }
      
      return allText.toString().trim();
    } catch (e) {
      print('Text recognition error: $e');
      return '';
    }
  }

  Future<String?> _scanBarcode(InputImage image) async {
    try {
      final barcodes = await _barcodeScanner.processImage(image);
      if (barcodes.isNotEmpty) {
        return barcodes.first.displayValue;
      }
      return null;
    } catch (e) {
      print('Barcode scanning error: $e');
      return null;
    }
  }

  Product _createProduct(List<String> labels, String text, String? barcode,
      {String? forcedName, String? forcedDescription}) {
    // Extract product name from labels or text
    String productName = forcedName ?? 'Unknown Product';
    String description = '';

    if (labels.isNotEmpty && forcedDescription == null) {
      productName = labels.first;
      // Removed "Detected as:" prefix
      description = labels.length > 1 
          ? labels.sublist(0, labels.length > 3 ? 3 : labels.length).join(", ")
          : labels.first;
    }

    // Try to extract brand or product name from text
    if (text.isNotEmpty) {
      final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
      if (lines.isNotEmpty) {
        // Use first significant line as product name if labels didn't provide one
        if (productName == 'Unknown Product') {
          productName = lines.first.trim();
        }
        
        // Add text info to description (removed "Text found:" prefix)
        if (lines.length > 1 && description.isEmpty) {
          description = lines.take(3).join(", ");
        }
      }
    }

    // Override with canonical info if provided
    if (forcedName != null && forcedName.isNotEmpty) {
      productName = forcedName;
    }
    if (forcedDescription != null && forcedDescription.isNotEmpty) {
      description = forcedDescription + (description.isNotEmpty ? '\n$description' : '');
    }

    if (barcode != null) {
      description += '\nBarcode: $barcode';
    }

    return Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: productName,
      description: description.isNotEmpty 
          ? description 
          : 'No additional information available',
      barcode: barcode,
      labels: labels,
      scannedAt: DateTime.now(),
    );
  }

  void dispose() {
    _imageLabeler.close();
    _textRecognizer.close();
    _barcodeScanner.close();
  }
}
