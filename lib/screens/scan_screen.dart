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
      appBar: AppBar(title: const Text('Scan product')),
      body: Column(children: [
        Expanded(
          child: Stack(children: [
            MobileScanner(onDetect: _onDetect),
            if (_loading) const Center(child: CircularProgressIndicator()),
          ]),
        ),
        if (_barcode != null)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Barcode: $_barcode'),
              const SizedBox(height: 8),
              if (_product != null) ...[
                Text('Product: ${_product!.name ?? "(unknown)"}'),
                const SizedBox(height: 8),
                if (_product!.imageUrl != null)
                  SizedBox(height: 120, child: Image.network(_product!.imageUrl!, fit: BoxFit.contain)),
                const SizedBox(height: 8),
                Row(children: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddItemScreen(prefill: {
                              'name': _product!.name,
                              'imageUrl': _product!.imageUrl,
                              'raw': _product!.raw,
                            })));
                      },
                      child: const Text('Add this item')),
                  const SizedBox(width: 12),
                  TextButton(onPressed: () => setState(() => _product = null), child: const Text('Scan again'))
                ])
              ] else ...[
                TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddItemScreen())), child: const Text('Add manually'))
              ]
            ]),
          )
      ]),
    );
  }
}
