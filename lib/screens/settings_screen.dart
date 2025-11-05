import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/haptic_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final TTSService _ttsService = TTSService();
  final HapticService _hapticService = HapticService();

  double _speechRate = 0.5;
  String _selectedLanguage = 'en-US';

  final Map<String, String> _languages = {
    'en-US': 'English (US)',
    'en-GB': 'English (UK)',
    'es-ES': 'Spanish',
    'fr-FR': 'French',
    'de-DE': 'German',
    'it-IT': 'Italian',
    'pt-BR': 'Portuguese',
    'hi-IN': 'Hindi',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final rate = await _storageService.getSpeechRate();
    final language = await _storageService.getLanguage();
    
    setState(() {
      _speechRate = rate;
      _selectedLanguage = language;
    });

    await _ttsService.speak('Settings. Adjust voice speed and language preferences.');
  }

  Future<void> _updateSpeechRate(double value) async {
    setState(() {
      _speechRate = value;
    });
    
    await _storageService.setSpeechRate(value);
    await _ttsService.setSpeechRate(value);
    await _hapticService.lightImpact();
  }

  Future<void> _testSpeech() async {
    await _hapticService.mediumImpact();
    await _ttsService.speak(
      'This is a test of the voice settings. The speed is currently set to ${(_speechRate * 100).toInt()} percent.'
    );
  }

  Future<void> _updateLanguage(String? language) async {
    if (language == null) return;
    
    setState(() {
      _selectedLanguage = language;
    });
    
    await _storageService.setLanguage(language);
    await _ttsService.setLanguage(language);
    await _hapticService.lightImpact();
    await _ttsService.speak('Language changed to ${_languages[language]}');
  }

  String _getSpeechRateLabel() {
    if (_speechRate < 0.3) return 'Very Slow';
    if (_speechRate < 0.5) return 'Slow';
    if (_speechRate < 0.7) return 'Normal';
    if (_speechRate < 0.9) return 'Fast';
    return 'Very Fast';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Settings',
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Voice Speed Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.yellow, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.speed, color: Colors.yellow, size: 32),
                          SizedBox(width: 12),
                          Text(
                            'Voice Speed',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _getSpeechRateLabel(),
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: Colors.yellow,
                          inactiveTrackColor: Colors.grey[700],
                          thumbColor: Colors.yellow,
                          overlayColor: Colors.yellow.withOpacity(0.3),
                          trackHeight: 8,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 16,
                          ),
                        ),
                        child: Slider(
                          value: _speechRate,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          onChanged: _updateSpeechRate,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _testSpeech,
                        icon: const Icon(Icons.play_arrow, size: 28),
                        label: const Text('TEST VOICE'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 60),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Language Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.yellow, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.language, color: Colors.yellow, size: 32),
                          SizedBox(width: 12),
                          Text(
                            'Language',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.yellow),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLanguage,
                            isExpanded: true,
                            dropdownColor: Colors.grey[900],
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.yellow,
                              size: 32,
                            ),
                            items: _languages.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                            onChanged: _updateLanguage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // About Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white54, size: 40),
                      SizedBox(height: 12),
                      Text(
                        'SmartVision v1.0.0',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Voice Product Assistant for Visually Impaired Users',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
