import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/haptic_service.dart';

class RecentScansScreen extends StatefulWidget {
  const RecentScansScreen({super.key});

  @override
  State<RecentScansScreen> createState() => _RecentScansScreenState();
}

class _RecentScansScreenState extends State<RecentScansScreen> {
  final StorageService _storageService = StorageService();
  final TTSService _ttsService = TTSService();
  final HapticService _hapticService = HapticService();

  List<Product> _recentScans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentScans();
  }

  Future<void> _loadRecentScans() async {
    final scans = await _storageService.getRecentScans();
    
    setState(() {
      _recentScans = scans;
      _isLoading = false;
    });

    if (scans.isEmpty) {
      await _ttsService.speak('No recent scans found. Scan a product to get started.');
    } else {
      await _ttsService.speak('You have ${scans.length} recent scans. Tap on any item to hear details.');
    }
  }

  Future<void> _speakProductDetails(Product product) async {
    await _hapticService.lightImpact();
    
    String announcement = 'Product: ${product.name}. ${product.description}';
    
    if (product.barcode != null) {
      announcement += ' Barcode: ${product.barcode}';
    }
    
    final scanTime = '${product.scannedAt.month}/${product.scannedAt.day} at ${product.scannedAt.hour}:${product.scannedAt.minute.toString().padLeft(2, '0')}';
    announcement += ' Scanned on $scanTime';
    
    await _ttsService.speak(announcement);
  }

  Future<void> _clearHistory() async {
    await _hapticService.mediumImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Clear History?',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
        content: const Text(
          'This will delete all recent scans.',
          style: TextStyle(fontSize: 18, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _ttsService.speak('Cancelled');
            },
            child: const Text(
              'CANCEL',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _storageService.clearRecentScans();
              Navigator.pop(context);
              await _ttsService.speak('History cleared');
              _loadRecentScans();
            },
            child: const Text(
              'CLEAR',
              style: TextStyle(fontSize: 20, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Recent Scans',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: () {
            _ttsService.speak('Going back');
            Navigator.pop(context);
          },
        ),
        actions: [
          if (_recentScans.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, size: 32),
              onPressed: _clearHistory,
              tooltip: 'Clear History',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            )
          : _recentScans.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 120,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'No Recent Scans',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Scan a product to see it here',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _recentScans.length,
                  itemBuilder: (context, index) {
                    final product = _recentScans[index];
                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _speakProductDetails(product),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.yellow,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.shopping_bag,
                                      size: 32,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${product.scannedAt.month}/${product.scannedAt.day} ${product.scannedAt.hour}:${product.scannedAt.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.volume_up,
                                    color: Colors.yellow,
                                    size: 32,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                product.description,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
