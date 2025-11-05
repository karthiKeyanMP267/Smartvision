import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/tts_service.dart';
import '../services/haptic_service.dart';

class ResultScreen extends StatefulWidget {
  final Product product;
  final String imagePath;

  const ResultScreen({
    super.key,
    required this.product,
    required this.imagePath,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final TTSService _ttsService = TTSService();
  final HapticService _hapticService = HapticService();

  @override
  void initState() {
    super.initState();
    _announceResult();
  }

  Future<void> _announceResult() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    String announcement = 'Product detected. ${widget.product.name}. ';
    
    if (widget.product.description.isNotEmpty) {
      announcement += widget.product.description;
    }
    
    if (widget.product.barcode != null) {
      announcement += ' Barcode: ${widget.product.barcode}';
    }

    await _ttsService.speak(announcement);
  }

  Future<void> _repeatAnnouncement() async {
    await _hapticService.lightImpact();
    await _announceResult();
  }

  Future<void> _goBack() async {
    await _hapticService.mediumImpact();
    await _ttsService.speak('Going back to home');
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _scanAgain() async {
    await _hapticService.mediumImpact();
    await _ttsService.speak('Ready to scan another product');
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Product Details',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: _goBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Image
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.yellow, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Success Icon
                const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),

                // Product Name
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Product Description
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.product.description,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Barcode (if available)
                if (widget.product.barcode != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code, color: Colors.white, size: 32),
                        const SizedBox(width: 12),
                        Text(
                          'Barcode: ${widget.product.barcode}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Repeat Button
                ElevatedButton.icon(
                  onPressed: _repeatAnnouncement,
                  icon: const Icon(Icons.volume_up, size: 36),
                  label: const Text('REPEAT'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 80),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Scan Again Button
                ElevatedButton.icon(
                  onPressed: _scanAgain,
                  icon: const Icon(Icons.camera_alt, size: 36),
                  label: const Text('SCAN AGAIN'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 80),
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),

                // Back to Home Button
                ElevatedButton.icon(
                  onPressed: _goBack,
                  icon: const Icon(Icons.home, size: 36),
                  label: const Text('BACK TO HOME'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 80),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
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
