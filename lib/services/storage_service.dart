import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _recentScansKey = 'recent_scans';
  static const String _speechRateKey = 'speech_rate';
  static const String _languageKey = 'language';
  static const int _maxRecentScans = 10;

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Save a scanned product
  Future<void> saveProduct(Product product) async {
    if (_prefs == null) await initialize();

    try {
      final List<String> recentScans = _prefs!.getStringList(_recentScansKey) ?? [];
      
      // Add new product to the beginning
      recentScans.insert(0, jsonEncode(product.toJson()));
      
      // Keep only the last 10 scans
      if (recentScans.length > _maxRecentScans) {
        recentScans.removeRange(_maxRecentScans, recentScans.length);
      }
      
      await _prefs!.setStringList(_recentScansKey, recentScans);
    } catch (e) {
      print('Error saving product: $e');
    }
  }

  // Get recent scans
  Future<List<Product>> getRecentScans() async {
    if (_prefs == null) await initialize();

    try {
      final List<String> recentScans = _prefs!.getStringList(_recentScansKey) ?? [];
      
      return recentScans.map((scanJson) {
        try {
          return Product.fromJson(jsonDecode(scanJson));
        } catch (e) {
          print('Error parsing product: $e');
          return null;
        }
      }).whereType<Product>().toList();
    } catch (e) {
      print('Error getting recent scans: $e');
      return [];
    }
  }

  // Clear recent scans
  Future<void> clearRecentScans() async {
    if (_prefs == null) await initialize();
    await _prefs!.remove(_recentScansKey);
  }

  // Speech rate settings
  Future<void> setSpeechRate(double rate) async {
    if (_prefs == null) await initialize();
    await _prefs!.setDouble(_speechRateKey, rate);
  }

  Future<double> getSpeechRate() async {
    if (_prefs == null) await initialize();
    return _prefs!.getDouble(_speechRateKey) ?? 0.5;
  }

  // Language settings
  Future<void> setLanguage(String language) async {
    if (_prefs == null) await initialize();
    await _prefs!.setString(_languageKey, language);
  }

  Future<String> getLanguage() async {
    if (_prefs == null) await initialize();
    return _prefs!.getString(_languageKey) ?? 'en-US';
  }
}
