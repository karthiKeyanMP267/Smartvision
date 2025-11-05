import 'dart:io';
import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import '../services/recognition_service.dart';
import '../services/tts_service.dart';
import '../services/haptic_service.dart';
import '../services/storage_service.dart';
import '../services/voice_command_service.dart';
import '../models/product_model.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final RecognitionService _recognitionService = RecognitionService();
  final TTSService _ttsService = TTSService();
  final HapticService _hapticService = HapticService();
  final StorageService _storageService = StorageService();
  final VoiceCommandService _voiceService = VoiceCommandService();

  bool _isProcessing = false;
  bool _isVoiceListening = false;
  String _statusMessage = 'Ready to scan';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _initializeVoiceCommands();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Resume listening when app comes back to foreground
    if (state == AppLifecycleState.resumed && _isVoiceListening) {
      _voiceService.startListening();
    }
  }

  Future<void> _initializeCamera() async {
    await _ttsService.speak('Camera ready. Tap the capture button or say "capture" to scan a product.');
  }

  Future<void> _initializeVoiceCommands() async {
    await _voiceService.initialize();
    _voiceService.setCommandCallbacks(
      onCapture: _captureAndRecognize,
      onBack: () {
        if (mounted) Navigator.pop(context);
      },
      onStopListening: () {
        setState(() {
          _isVoiceListening = false;
        });
      },
    );
    // Auto-start listening
    _startVoiceListening();
  }

  Future<void> _startVoiceListening() async {
    await _voiceService.startListening();
    setState(() {
      _isVoiceListening = true;
    });
  }

  Future<void> _toggleVoiceCommands() async {
    await _hapticService.lightImpact();
    
    if (_isVoiceListening) {
      await _voiceService.stopListening();
      await _ttsService.speak('Voice commands stopped');
      setState(() {
        _isVoiceListening = false;
      });
    } else {
      await _voiceService.startListening();
      await _ttsService.speak('Listening. Say "capture" to take photo.');
      setState(() {
        _isVoiceListening = true;
      });
    }
  }

  Future<void> _captureAndRecognize() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Capturing image...';
    });

    await _hapticService.mediumImpact();
    await _ttsService.speak('Hold steady. Capturing image.');

    try {
      // Capture image
      final File? imageFile = await _cameraService.captureImage();

      if (imageFile == null) {
        await _hapticService.error();
        await _ttsService.speak('Failed to capture image. Please try again.');
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Capture failed';
        });
        return;
      }

      setState(() {
        _statusMessage = 'Analyzing product...';
      });
      await _ttsService.speak('Processing image. Please wait.');

      // Recognize product
      final Product? product = await _recognitionService.recognizeProduct(imageFile);

      if (product == null) {
        await _hapticService.error();
        await _ttsService.speak('Could not recognize the product. Please try again with better lighting.');
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Recognition failed';
        });
        return;
      }

      // Save to recent scans
      await _storageService.saveProduct(product);

      // Success feedback
      await _hapticService.success();

      // Navigate to result screen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(product: product, imagePath: imageFile.path),
        ),
      );
    } catch (e) {
      await _hapticService.error();
      await _ttsService.speak('An error occurred. Please try again.');
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Don't dispose the singleton voice service, just stop listening
    _voiceService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Scan Product',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: () {
            _ttsService.speak('Going back');
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Camera Preview Area
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.grey[900],
                child: Center(
                  child: _isProcessing
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.yellow,
                              strokeWidth: 6,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _statusMessage,
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 120,
                              color: Colors.white54,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Point camera at product',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            // Bottom Section with Capture Button
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.black,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status Message
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Capture Button
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _captureAndRecognize,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 100),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera, size: 40),
                                SizedBox(width: 16),
                                Text(
                                  'CAPTURE',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleVoiceCommands,
        backgroundColor: _isVoiceListening ? Colors.red : Colors.yellow,
        child: Icon(
          _isVoiceListening ? Icons.mic : Icons.mic_none,
          size: 30,
          color: Colors.black,
        ),
      ),
    );
  }
}
