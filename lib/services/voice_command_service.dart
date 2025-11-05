import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';
import 'tts_service.dart';

/// Voice Command Service for hands-free app control
/// Supports commands like "open camera", "capture", "go back", etc.
class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;
  VoiceCommandService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final TTSService _tts = TTSService();
  
  bool _isInitialized = false;
  bool _isListening = false;
  bool _shouldKeepListening = false;
  String _lastWords = '';
  
  VoidCallback? _onCameraCommand;
  VoidCallback? _onCaptureCommand;
  VoidCallback? _onBackCommand;
  VoidCallback? _onHomeCommand;
  VoidCallback? _onScanCommand;
  VoidCallback? _onSettingsCommand;
  VoidCallback? _onRecentScansCommand;
  VoidCallback? _onHelpCommand;
  VoidCallback? _onStopListeningCommand;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get lastWords => _lastWords;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('🎤 Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            // Automatically restart listening if it should keep listening
            if (_shouldKeepListening) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_shouldKeepListening) {
                  startListening();
                }
              });
            }
          }
        },
        onError: (error) {
          debugPrint('❌ Speech error: $error');
          _isListening = false;
          // Automatically restart listening on error if it should keep listening
          if (_shouldKeepListening) {
            Future.delayed(const Duration(seconds: 1), () {
              if (_shouldKeepListening) {
                startListening();
              }
            });
          }
        },
      );
      
      if (_isInitialized) {
        debugPrint('✅ Voice commands initialized');
        await _tts.speak('Voice commands ready. Say "help" for available commands.');
      } else {
        debugPrint('❌ Voice commands initialization failed');
      }
      
      return _isInitialized;
    } catch (e) {
      debugPrint('❌ Voice command initialization error: $e');
      return false;
    }
  }

  /// Set command callbacks
  void setCommandCallbacks({
    VoidCallback? onCamera,
    VoidCallback? onCapture,
    VoidCallback? onBack,
    VoidCallback? onHome,
    VoidCallback? onScan,
    VoidCallback? onSettings,
    VoidCallback? onRecentScans,
    VoidCallback? onHelp,
    VoidCallback? onStopListening,
  }) {
    _onCameraCommand = onCamera;
    _onCaptureCommand = onCapture;
    _onBackCommand = onBack;
    _onHomeCommand = onHome;
    _onScanCommand = onScan;
    _onSettingsCommand = onSettings;
    _onRecentScansCommand = onRecentScans;
    _onHelpCommand = onHelp;
    _onStopListeningCommand = onStopListening;
  }

  /// Start listening for voice commands
  Future<void> startListening() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (!_isInitialized || _isListening) return;
    
    try {
      _isListening = true;
      _shouldKeepListening = true;
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords.toLowerCase();
          debugPrint('🎤 Heard: $_lastWords');
          
          if (result.finalResult) {
            _processCommand(_lastWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      debugPrint('❌ Start listening error: $e');
      _isListening = false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      _shouldKeepListening = false;
      await _speech.stop();
      _isListening = false;
      debugPrint('🛑 Stopped listening');
    } catch (e) {
      debugPrint('❌ Stop listening error: $e');
    }
  }

  /// Process voice command
  void _processCommand(String command) {
    debugPrint('🎯 Processing command: $command');
    
    // Camera commands
    if (_containsAny(command, ['open camera', 'camera', 'open cam', 'start camera'])) {
      _tts.speak('Opening camera');
      _onCameraCommand?.call();
    }
    // Capture commands
    else if (_containsAny(command, ['capture', 'take photo', 'take picture', 'snap', 'click', 'shoot'])) {
      _tts.speak('Capturing');
      _onCaptureCommand?.call();
    }
    // Scan commands
    else if (_containsAny(command, ['scan', 'scan product', 'identify', 'recognize', 'what is this'])) {
      _tts.speak('Starting scan');
      _onScanCommand?.call();
    }
    // Navigation - Back
    else if (_containsAny(command, ['go back', 'back', 'previous', 'return'])) {
      _tts.speak('Going back');
      _onBackCommand?.call();
    }
    // Navigation - Home
    else if (_containsAny(command, ['go home', 'home', 'main menu', 'start'])) {
      _tts.speak('Going to home');
      _onHomeCommand?.call();
    }
    // Recent scans
    else if (_containsAny(command, ['recent scans', 'recent', 'history', 'show history'])) {
      _tts.speak('Opening recent scans');
      _onRecentScansCommand?.call();
    }
    // Settings
    else if (_containsAny(command, ['settings', 'preferences', 'options'])) {
      _tts.speak('Opening settings');
      _onSettingsCommand?.call();
    }
    // Help
    else if (_containsAny(command, ['help', 'what can you do', 'commands', 'instructions'])) {
      _tts.speak('Available commands: Open camera, Capture, Scan, Go back, Go home, Recent scans, Settings, Stop listening.');
      _onHelpCommand?.call();
    }
    // Stop listening
    else if (_containsAny(command, ['stop listening', 'stop', 'cancel', 'close'])) {
      _tts.speak('Stopped listening');
      stopListening();
      _onStopListeningCommand?.call();
    }
    // Unknown command
    else {
      _tts.speak('Command not recognized. Say "help" for available commands.');
    }
  }

  /// Check if command contains any of the keywords
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Toggle listening state
  Future<void> toggleListening() async {
    if (_isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  /// Cancel listening
  Future<void> cancel() async {
    await _speech.cancel();
    _isListening = false;
  }

  /// Dispose resources
  void dispose() {
    _shouldKeepListening = false;
    _speech.stop();
    _isListening = false;
  }
}
