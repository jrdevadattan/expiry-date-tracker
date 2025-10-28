import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tracker/screens/add_item_screen.dart';
import 'package:tracker/services/openfood_api.dart';
import 'package:tracker/services/product_image_service.dart';
import 'dart:io';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  bool _loading = false;
  bool _scanned = false;
  late AnimationController _animController;
  late Animation<double> _scanLineAnimation;
  final TextRecognizer _textRecognizer = TextRecognizer();
  String _scanMode = 'barcode'; // 'barcode' or 'product'
  String? _detectedExpiry;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      detectionTimeoutMs: 500,
    );
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _captureAndAnalyze() async {
    if (_loading || _scanned) return;
    
    setState(() {
      _loading = true;
      _scanned = true;
    });

    try {
      // Stop the camera temporarily
      await _controller?.stop();
      
      // Capture image using image picker
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (photo == null) {
        setState(() {
          _loading = false;
          _scanned = false;
        });
        await _controller?.start();
        return;
      }

      // Process the image for text recognition
      final inputImage = InputImage.fromFilePath(photo.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      // Extract expiry date from recognized text
      String? expiryDate = _extractExpiryDate(recognizedText.text);
      
      // Extract product name (usually the largest text or top text)
      String productName = _extractProductName(recognizedText);
      
      // Search for product image online
      String? productImageUrl;
      try {
        final productInfo = await ProductImageService.searchProduct(productName);
        productImageUrl = productInfo?.imageUrl;
      } catch (e) {
        debugPrint('Error fetching product image: $e');
      }

      if (mounted) {
        setState(() {
          _loading = false;
          _detectedExpiry = expiryDate;
        });
        
        // Navigate to add screen with detected information
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddItemScreen(
              prefill: {
                'name': productName,
                'imagePath': photo.path,
                'imageUrl': productImageUrl,
                'expiryDate': expiryDate,
              },
            ),
          ),
        );
        
        // Reset scanner state
        if (mounted) {
          setState(() {
            _scanned = false;
            _detectedExpiry = null;
          });
          await _controller?.start();
        }
      }
    } catch (e) {
      debugPrint('Error analyzing product: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _scanned = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to analyze product: $e')),
        );
        await _controller?.start();
      }
    }
  }

  String _extractProductName(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 'Scanned Product';
    
    // Get the first few blocks (usually product name is at top)
    String productName = '';
    int maxArea = 0;
    
    for (var block in recognizedText.blocks.take(5)) {
      final text = block.text.trim();
      if (text.isEmpty) continue;
      
      // Calculate approximate area (larger text is likely the product name)
      final area = block.boundingBox.width * block.boundingBox.height;
      if (area > maxArea && text.length > 3 && text.length < 50) {
        maxArea = area.toInt();
        productName = text;
      }
    }
    
    return productName.isNotEmpty ? productName : 'Scanned Product';
  }

  String? _extractExpiryDate(String text) {
    // Common expiry date patterns
    final patterns = [
      // DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
      RegExp(r'(?:exp|best before|use by|bb|expiry)[:\s]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
      // MM/YYYY
      RegExp(r'(?:exp|best before|use by|bb|expiry)[:\s]*(\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
      // Standalone date patterns
      RegExp(r'\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\b'),
      RegExp(r'\b(\d{1,2}[\/\-\.]\d{2,4})\b'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_loading || _scanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final bar = barcodes.first.rawValue;
    if (bar == null || bar.isEmpty) return;
    
    setState(() {
      _scanned = true;
      _loading = true;
    });
    
    // Fetch product info
    final p = await OpenFoodApi.fetchProduct(bar);
    
    if (mounted) {
      setState(() {
        _loading = false;
      });
      
      // Navigate to add screen with prefilled data
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddItemScreen(
            prefill: {
              'name': p?.name ?? 'Scanned Item ($bar)',
              'imageUrl': p?.imageUrl,
              'quantity': p?.raw?['quantity'] as String? ?? '1',
              'barcode': bar,
            },
          ),
        ),
      );
      
      // Reset scanner state
      if (mounted) {
        setState(() {
          _scanned = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanAreaWidth = MediaQuery.of(context).size.width * 0.85;
    final scanAreaHeight = _scanMode == 'product' 
        ? MediaQuery.of(context).size.height * 0.6  // Larger for product scanning
        : MediaQuery.of(context).size.height * 0.4; // Smaller for barcode
    
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _scanMode == 'product' ? 'Scan Product' : 'Scan Barcode',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          // Mode toggle button
          IconButton(
            icon: Icon(
              _scanMode == 'product' ? Icons.qr_code : Icons.photo_camera,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _scanMode = _scanMode == 'barcode' ? 'product' : 'barcode';
                _scanned = false;
                _detectedExpiry = null;
              });
            },
            tooltip: _scanMode == 'product' ? 'Switch to Barcode' : 'Switch to Product Scan',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_controller != null)
            Positioned.fill(
              child: MobileScanner(
                controller: _controller!,
                onDetect: _onDetect,
                fit: BoxFit.cover,
              ),
            ),

          // Dark overlay with transparent scan area
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanOverlayPainter(
                scanAreaWidth: scanAreaWidth,
                scanAreaHeight: scanAreaHeight,
              ),
            ),
          ),

          // Scanning frame and animations
          Center(
            child: SizedBox(
              width: scanAreaWidth,
              height: scanAreaHeight,
              child: Stack(
                children: [
                  // Corner brackets
                  CustomPaint(
                    size: Size(scanAreaWidth, scanAreaHeight),
                    painter: _CornerBracketsPainter(
                      color: const Color(0xFF00C853),
                      strokeWidth: 4.0,
                      cornerLength: 40,
                    ),
                  ),
                  
                  // Animated scan line - only rebuild this part
                  if (!_loading && !_scanned)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _scanLineAnimation,
                        builder: (context, child) {
                          return Align(
                            alignment: Alignment(0, _scanLineAnimation.value * 2 - 1),
                            child: child,
                          );
                        },
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0xFF00C853),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Status indicator
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _loading 
                            ? Colors.orange.withOpacity(0.9)
                            : _scanned
                                ? const Color(0xFF00C853).withOpacity(0.9)
                                : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_loading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          else
                            Icon(
                              _scanned ? Icons.check_circle : Icons.qr_code_scanner,
                              color: Colors.white,
                              size: 18,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            _loading 
                                ? 'Fetching product...' 
                                : _scanned
                                    ? 'Scanned!'
                                    : 'Align barcode in frame',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Instructions
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Icon(
                  _scanMode == 'product' ? Icons.photo_camera : Icons.qr_code_scanner,
                  color: Colors.white70,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  _scanMode == 'product' 
                      ? 'Capture the product package'
                      : 'Point your camera at the barcode',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _scanMode == 'product'
                      ? 'Make sure expiry date is visible'
                      : 'Position the barcode within the frame',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Capture button for product mode
                if (_scanMode == 'product')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xFF00C853).withOpacity(0.4),
                        ),
                        onPressed: _loading ? null : _captureAndAnalyze,
                        icon: Icon(
                          _loading ? Icons.hourglass_empty : Icons.camera_alt,
                          size: 20,
                        ),
                        label: Text(
                          _loading ? 'Analyzing...' : 'Capture & Analyze',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                
                if (_scanMode == 'product')
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'or',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _scanMode == 'product' 
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFF00C853),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: _scanMode == 'product' ? 0 : 8,
                        shadowColor: const Color(0xFF00C853).withOpacity(0.4),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddItemScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text(
                        'Add details manually',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Dark overlay painter with transparent scan area
class _ScanOverlayPainter extends CustomPainter {
  final double scanAreaWidth;
  final double scanAreaHeight;

  _ScanOverlayPainter({
    required this.scanAreaWidth,
    required this.scanAreaHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaWidth,
      height: scanAreaHeight,
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(24)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Corner brackets painter
class _CornerBracketsPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;

  _CornerBracketsPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawLine(
      const Offset(0, 0),
      Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, cornerLength),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(0, size.height - cornerLength),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerLength),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
