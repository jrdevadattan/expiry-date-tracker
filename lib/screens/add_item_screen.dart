import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tracker/models/item.dart';
import 'package:tracker/providers/item_provider.dart';
import 'package:tracker/services/ocr_service.dart';

class AddItemScreen extends StatefulWidget {
  final Map<String, dynamic>? prefill;

  const AddItemScreen({super.key, this.prefill});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  String _type = 'Food';
  DateTime _purchased = DateTime.now();
  DateTime _expiry = DateTime.now().add(const Duration(days: 7));
  XFile? _image;
  String? _networkImageUrl;
  List<String> _dateHints = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final p = ImagePicker();
    final file = await p.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (file != null) setState(() => _image = file);
  }

  Future<void> _captureImage() async {
    final p = ImagePicker();
    final file = await p.pickImage(source: ImageSource.camera, imageQuality: 75);
    if (file != null) setState(() => _image = file);
  }

  Future<void> _scanLabelWithOcr() async {
    // Ensure an image is available; if not, capture one first
    if (_image == null) {
      await _captureImage();
      if (_image == null) return;
    }
    final f = File(_image!.path);
    final hints = await OcrService.extractHints(f);
    // Merge new hints with existing and update UI
    setState(() {
      for (final h in hints) {
        if (!_dateHints.contains(h)) _dateHints.add(h);
      }
    });
  }

  Future<void> _enterImageUrl() async {
    final ctrl = TextEditingController(text: _networkImageUrl);
    final res = await showDialog<String?>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Enter image URL'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'https://...')),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('OK'))],
    ));
    if (res != null && res.isNotEmpty) setState(() => _networkImageUrl = res);
  }

  @override
  void initState() {
    super.initState();
    final pre = widget.prefill;
    if (pre != null) {
      if (pre['name'] != null) _nameCtrl.text = pre['name'] as String;
      if (pre['quantity'] != null) _quantityCtrl.text = pre['quantity'] as String;
      if (pre['type'] != null) _type = pre['type'] as String;
      if (pre['imageUrl'] != null) _networkImageUrl = pre['imageUrl'] as String;
      if (pre['purchased'] != null && pre['purchased'] is DateTime) _purchased = pre['purchased'] as DateTime;
      if (pre['expiry'] != null && pre['expiry'] is DateTime) _expiry = pre['expiry'] as DateTime;
      // parse raw product map for date-like hints
      if (pre['raw'] != null && pre['raw'] is Map<String, dynamic>) {
        _dateHints = _extractDateHints(pre['raw'] as Map<String, dynamic>);
      }
    }
  }

  List<String> _extractDateHints(Map<String, dynamic> raw) {
    final seen = <String>{};
    final candidates = <String>[];
    final dateRegex = RegExp(r"\b(\d{4}-\d{2}-\d{2}|\d{2}[.\-/]\d{2}[.\-/]\d{2,4}|\d{2}[.\-/]\d{2}[.\-/]\d{4})\b");
    void scanValue(dynamic v) {
      if (v is String) {
        for (final m in dateRegex.allMatches(v)) {
          final s = m.group(0)!.trim();
          if (seen.add(s)) candidates.add(s);
        }
        // look for 'best before' or 'best before end' phrases
        final lb = RegExp(r"(?i)(best before|best before end|bbd|use by|expiry|exp|mfd)[\s:\-]*([^,;\n]+)");
        final m = lb.firstMatch(v);
        if (m != null) {
          final s = m.group(2)!.trim();
          if (seen.add(s)) candidates.add(s);
        }
      } else if (v is Map) {
        v.values.forEach(scanValue);
      } else if (v is Iterable) {
        v.forEach(scanValue);
      }
    }

    scanValue(raw);
    return candidates;
  }

  Future<void> _pickDate({required bool expiry}) async {
    final initial = expiry ? _expiry : _purchased;
    final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null) setState(() => expiry ? _expiry = picked : _purchased = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final newItem = Item(
      name: _nameCtrl.text.trim(),
      itemType: _type,
      quantity: _quantityCtrl.text.trim(),
      purchased: _purchased,
      expiry: _expiry,
      imagePath: _image?.path ?? _networkImageUrl,
    );
    await Provider.of<ItemProvider>(context, listen: false).addItem(newItem);
    // schedule a notification one day before expiry when possible
    // Notifications are currently disabled in this build; re-enable when plugin
    // compatibility is addressed.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add new item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Column(children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: _image != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_image!.path), width: 120, height: 120, fit: BoxFit.cover))
                        : (_networkImageUrl != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_networkImageUrl!, width: 120, height: 120, fit: BoxFit.cover))
                            : Container(width: 120, height: 120, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.camera_alt, size: 40))),
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    ElevatedButton.icon(onPressed: _captureImage, icon: const Icon(Icons.camera), label: const Text('Camera')),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo_library), label: const Text('Gallery')),
                    const SizedBox(width: 8),
                    TextButton(onPressed: _enterImageUrl, child: const Text('Image URL')),
                    const SizedBox(width: 8),
                    TextButton.icon(onPressed: _scanLabelWithOcr, icon: const Icon(Icons.text_snippet), label: const Text('Scan label (OCR)')),
                  ])
                ]),
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v == null || v.isEmpty ? 'Enter a name' : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(value: _type, items: ['Food', 'Drink', 'Other'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _type = v ?? 'Food'), decoration: const InputDecoration(labelText: 'Item type')),
              const SizedBox(height: 12),
              TextFormField(controller: _quantityCtrl, decoration: const InputDecoration(labelText: 'Quantity (e.g. 1L, 500g)'), validator: (v) => v == null || v.isEmpty ? 'Enter quantity' : null),
              const SizedBox(height: 12),
              ListTile(title: const Text('Purchased'), subtitle: Text('${_purchased.toLocal()}'.split(' ')[0]), trailing: IconButton(icon: const Icon(Icons.calendar_month), onPressed: () => _pickDate(expiry: false))),
              ListTile(title: const Text('Expires on'), subtitle: Text('${_expiry.toLocal()}'.split(' ')[0]), trailing: IconButton(icon: const Icon(Icons.calendar_month), onPressed: () => _pickDate(expiry: true))),
              if (_dateHints.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Detected label hints:', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _dateHints.map((h) => ActionChip(label: Text(h), onPressed: () {
                        final parsed = _parseDateFromString(h);
                        if (parsed != null) setState(() => _expiry = parsed);
                      })).toList(),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.check), label: const Text('Add this item')),
            ],
          ),
        ),
      ),
    );
  }

  DateTime? _parseDateFromString(String s) {
    // Try ISO first
    try {
      final iso = DateTime.parse(s);
      return iso;
    } catch (_) {}
    // Try common formats
    final fmts = [
      RegExp(r'^(\d{2})[.\-/](\d{2})[.\-/](\d{4})$'), // dd-mm-yyyy
      RegExp(r'^(\d{2})[.\-/](\d{2})[.\-/](\d{2})$'), // dd-mm-yy
      RegExp(r'^(\d{4})[.\-/](\d{2})[.\-/](\d{2})$'), // yyyy-mm-dd
    ];
    for (final r in fmts) {
      final m = r.firstMatch(s);
      if (m != null) {
        try {
          if (r.pattern.startsWith(r'^(\d{2})')) {
            final d = int.parse(m.group(1)!);
            final mm = int.parse(m.group(2)!);
            var y = int.parse(m.group(3)!);
            if (y < 100) y += 2000;
            return DateTime(y, mm, d);
          } else {
            final y = int.parse(m.group(1)!);
            final mm = int.parse(m.group(2)!);
            final d = int.parse(m.group(3)!);
            return DateTime(y, mm, d);
          }
        } catch (_) {}
      }
    }
    return null;
  }
}
