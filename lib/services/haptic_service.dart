import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  Future<void> lightImpact() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      print('Haptic feedback error: $e');
    }
  }

  Future<void> mediumImpact() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      print('Haptic feedback error: $e');
    }
  }

  Future<void> heavyImpact() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      print('Haptic feedback error: $e');
    }
  }

  Future<void> success() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      print('Haptic feedback error: $e');
    }
  }

  Future<void> error() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(pattern: [0, 100, 100, 100]);
      }
    } catch (e) {
      print('Haptic feedback error: $e');
    }
  }
}
