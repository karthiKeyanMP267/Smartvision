import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Gemini AI Service for intelligent product recognition
/// Uses Google's Gemini Vision model for high-accuracy product identification
class GeminiAIService {
  static final GeminiAIService _instance = GeminiAIService._internal();
  factory GeminiAIService() => _instance;
  GeminiAIService._internal();

  GenerativeModel? _model;
  bool _isInitialized = false;

  // Get your API key from: https://makersuite.google.com/app/apikey
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE'; // TODO: Add your API key

  /// Initialize Gemini AI model
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        print('⚠️ Gemini API key not configured. Using ML Kit only.');
        return;
      }

      _model = GenerativeModel(
        model: 'gemini-1.5-flash', // Fast and accurate model
        apiKey: _apiKey,
      );
      _isInitialized = true;
      print('✅ Gemini AI initialized successfully');
    } catch (e) {
      print('❌ Gemini AI initialization error: $e');
      _isInitialized = false;
    }
  }

  /// Recognize product from image using Gemini Vision
  Future<Map<String, String>?> recognizeProduct(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_model == null) {
      print('⚠️ Gemini AI not available, skipping');
      return null;
    }

    try {
      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();

      // Create prompt for product recognition
      final prompt = '''
Analyze this product image and provide:
1. Product Name (the actual product name, not just brand)
2. Brand Name
3. Brief description (1 short sentence about what it is)

Return ONLY in this exact format:
NAME: [product name]
BRAND: [brand name]
DESCRIPTION: [brief description]

Example:
NAME: Real Mayonnaise
BRAND: Hellmann's
DESCRIPTION: Creamy mayonnaise made with cage-free eggs

Be concise and accurate. Focus on what the product IS, not marketing text.
''';

      // Create content with image
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      print('🤖 Analyzing product with Gemini AI...');
      
      // Generate response with timeout
      final response = await _model!.generateContent(content).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Gemini AI timeout');
        },
      );

      final text = response.text?.trim();
      
      if (text == null || text.isEmpty) {
        print('⚠️ Gemini returned empty response');
        return null;
      }

      print('✅ Gemini AI response received');
      
      // Parse response
      final result = _parseGeminiResponse(text);
      return result;
    } catch (e) {
      print('❌ Gemini AI recognition error: $e');
      return null;
    }
  }

  /// Parse Gemini response into structured data
  Map<String, String> _parseGeminiResponse(String response) {
    final result = <String, String>{};
    
    final lines = response.split('\n');
    for (final line in lines) {
      if (line.contains('NAME:')) {
        result['name'] = line.replaceFirst('NAME:', '').trim();
      } else if (line.contains('BRAND:')) {
        result['brand'] = line.replaceFirst('BRAND:', '').trim();
      } else if (line.contains('DESCRIPTION:')) {
        result['description'] = line.replaceFirst('DESCRIPTION:', '').trim();
      }
    }

    return result;
  }

  /// Quick product identification (name only)
  Future<String?> identifyProductQuick(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_model == null) {
      return null;
    }

    try {
      final imageBytes = await imageFile.readAsBytes();

      final prompt = '''
What product is this? Provide ONLY the product name and brand in format:
[Brand] [Product Name]

Example: Hellmann's Real Mayonnaise

Be brief and accurate.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model!.generateContent(content).timeout(
        const Duration(seconds: 8),
      );

      return response.text?.trim();
    } catch (e) {
      print('❌ Gemini quick identification error: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _model = null;
    _isInitialized = false;
  }
}
