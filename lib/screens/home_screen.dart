import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../services/haptic_service.dart';
import '../services/voice_command_service.dart';
import 'scan_screen.dart';
import 'recent_scans_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TTSService _ttsService = TTSService();
  final HapticService _hapticService = HapticService();
  final VoiceCommandService _voiceService = VoiceCommandService();
  bool _isVoiceListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVoiceCommands();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _welcomeUser();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Resume listening when app comes back to foreground
    if (state == AppLifecycleState.resumed && _isVoiceListening) {
      _voiceService.startListening();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Don't dispose the singleton voice service, just stop listening
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _initializeVoiceCommands() async {
    await _voiceService.initialize();
    _voiceService.setCommandCallbacks(
      onCamera: _navigateToScan,
      onScan: _navigateToScan,
      onRecentScans: _navigateToRecentScans,
      onSettings: _navigateToSettings,
      onHome: () {}, // Already on home
      onHelp: _handleScreenTap,
      onStopListening: () {
        setState(() {
          _isVoiceListening = false;
        });
      },
    );
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
      await _ttsService.speak('Listening for commands. Say "help" for available commands.');
      setState(() {
        _isVoiceListening = true;
      });
    }
  }

  Future<void> _welcomeUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _ttsService.speak(
      'Welcome to SmartVision. Your voice product assistant. Tap the screen to hear instructions, or use the scan button to identify products.'
    );
  }

  Future<void> _handleScreenTap() async {
    await _hapticService.lightImpact();
    await _ttsService.speak(
      'SmartVision helps you identify products. '
      'Tap the yellow Scan Product button to take a photo. '
      'Tap Recent Scans to hear your last scanned products. '
      'Tap Settings to change voice speed or other options.'
    );
  }

  Future<void> _navigateToScan() async {
    await _hapticService.mediumImpact();
    await _ttsService.speak('Opening camera for product scan');
    
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanScreen()),
    );
  }

  Future<void> _navigateToRecentScans() async {
    await _hapticService.mediumImpact();
    await _ttsService.speak('Opening recent scans');
    
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecentScansScreen()),
    );
  }

  Future<void> _navigateToSettings() async {
    await _hapticService.mediumImpact();
    await _ttsService.speak('Opening settings');
    
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _handleScreenTap,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Title
                const Text(
                  '👁️ SmartVision',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Voice Product Assistant',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 80),

                // Scan Product Button (Primary Action)
                ElevatedButton.icon(
                  onPressed: _navigateToScan,
                  icon: const Icon(Icons.camera_alt, size: 40),
                  label: const Text('SCAN PRODUCT'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 100),
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // Recent Scans Button
                ElevatedButton.icon(
                  onPressed: _navigateToRecentScans,
                  icon: const Icon(Icons.history, size: 36),
                  label: const Text('RECENT SCANS'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 80),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // Settings Button
                ElevatedButton.icon(
                  onPressed: _navigateToSettings,
                  icon: const Icon(Icons.settings, size: 36),
                  label: const Text('SETTINGS'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 80),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 40),

                // Instruction hint
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.yellow, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Tap anywhere on screen to hear instructions\n\nOr tap the microphone button for voice commands',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.yellow,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _toggleVoiceCommands,
        backgroundColor: _isVoiceListening ? Colors.red : Colors.yellow,
        child: Icon(
          _isVoiceListening ? Icons.mic : Icons.mic_none,
          size: 40,
          color: Colors.black,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
