import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tracker/screens/add_item_screen.dart';
import 'package:tracker/services/openfood_api.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String? _barcode;
  OpenFoodProduct? _product;
  bool _loading = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_loading) return;
    final bar = capture.barcodes.first.rawValue;
    if (bar == null) return;
    setState(() {
      _loading = true;
      _barcode = bar;
    });
    final p = await OpenFoodApi.fetchProduct(bar);
    setState(() {
      _product = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(''),
      ),
      body: Stack(children: [
        // camera preview
        Positioned.fill(child: MobileScanner(onDetect: _onDetect, fit: BoxFit.cover)),

        // overlay frame and scanning UI
        Positioned.fill(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Expanded(child: Container()),
            // framed scanning area
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.78,
                height: MediaQuery.of(context).size.height * 0.56,
                child: Stack(children: [
                  // rounded frame
                  CustomPaint(
                    size: Size.infinite,
                    painter: _ScannerFramePainter(color: Colors.white.withOpacity(0.9), stroke: 6.0),
                  ),
                  // scanning pill
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(30)),
                      child: Text(_loading ? 'Scanning...' : 'Scanning...', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ),
            ),
            Expanded(child: Container()),
          ]),
        ),

        // bottom controls: 'or' and add manually button
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('or', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)), elevation: 6),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddItemScreen())),
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text('Add details manually', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ]),
        ),

        // loading indicator overlay
        if (_loading) const Positioned(top: 120, left: 0, right: 0, child: Center(child: CircularProgressIndicator(color: Colors.white))),
      ]),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  final Color color;
  final double stroke;
  _ScannerFramePainter({required this.color, this.stroke = 6.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final r = Rect.fromLTWH(0 + stroke / 2, 0 + stroke / 2, size.width - stroke, size.height - stroke);
    final radius = Radius.circular(28);
    final rrect = RRect.fromRectAndRadius(r, radius);
    canvas.drawRRect(rrect, paint);

    // draw small corner gaps (simulate decorative rounded corners)
    // here we just draw short arcs at each corner to mimic style
    final gapPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    // nothing more complex required for now
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
