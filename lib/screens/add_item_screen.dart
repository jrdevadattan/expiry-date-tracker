import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tracker/models/item.dart';
import 'package:tracker/providers/item_provider.dart';
// removed OCR-from-URL helpers and related imports to keep UI minimal as per mock

class AddItemScreen extends StatefulWidget {
  final Map<String, dynamic>? prefill;

  const AddItemScreen({super.key, this.prefill});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  // form key removed; simplified UI uses dialogs for edits
  final _nameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  String _type = 'Food';
  DateTime _purchased = DateTime.now();
  DateTime _expiry = DateTime.now().add(const Duration(days: 7));
  XFile? _image;
  String? _networkImageUrl;
  int? _editingId;

  // Available item types with icons
  static const List<Map<String, dynamic>> _itemTypes = [
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Beverage', 'icon': Icons.local_drink},
    {'name': 'Dairy', 'icon': Icons.icecream},
    {'name': 'Snacks', 'icon': Icons.cookie},
    {'name': 'Medicine', 'icon': Icons.medical_services},
    {'name': 'Cosmetics', 'icon': Icons.face_retouching_natural},
    {'name': 'Baby Products', 'icon': Icons.child_care},
    {'name': 'Supplements', 'icon': Icons.vaccines},
    {'name': 'Other', 'icon': Icons.category},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final p = ImagePicker();
    final file = await p.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60, // Reduce quality for better performance
      maxWidth: 800,    // Limit image size
      maxHeight: 800,
    );
    if (file != null) setState(() => _image = file);
  }

  


  @override
  void initState() {
    super.initState();
    final pre = widget.prefill;
    if (pre != null) {
      if (pre['name'] != null) _nameCtrl.text = pre['name'] as String;
      if (pre['id'] != null) _editingId = pre['id'] as int;
      if (pre['quantity'] != null) _quantityCtrl.text = pre['quantity'] as String;
      if (pre['type'] != null) _type = pre['type'] as String;
      if (pre['imageUrl'] != null) _networkImageUrl = pre['imageUrl'] as String;
      if (pre['purchased'] != null && pre['purchased'] is DateTime) _purchased = pre['purchased'] as DateTime;
      if (pre['expiry'] != null && pre['expiry'] is DateTime) _expiry = pre['expiry'] as DateTime;
      // parse raw product map for date-like hints
      // no raw-product date extraction in this simplified UI
    }
  }

  Future<void> _pickDate({required bool expiry}) async {
    final initial = expiry ? _expiry : _purchased;
    final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null) setState(() => expiry ? _expiry = picked : _purchased = picked);
  }

  Future<void> _save() async {
    // ensure name is present; if not, prompt user to enter one
    if (_nameCtrl.text.trim().isEmpty) {
      await _editNameDialog();
      if (_nameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a name')));
        return;
      }
    }

    final newItem = Item(
      id: _editingId,
      name: _nameCtrl.text.trim(),
      itemType: _type,
      quantity: _quantityCtrl.text.trim().isNotEmpty ? _quantityCtrl.text.trim() : '1',
      purchased: _purchased,
      expiry: _expiry,
      imagePath: _image?.path ?? _networkImageUrl,
    );
    try {
      if (_editingId != null) {
        await Provider.of<ItemProvider>(context, listen: false).updateItem(newItem);
      } else {
        await Provider.of<ItemProvider>(context, listen: false).addItem(newItem);
      }
    } catch (e, st) {
      // protect against unexpected runtime errors during save and report back
      debugPrint('Failed to save item: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save item: $e')));
      return;
    }
    // schedule a notification one day before expiry when possible
    // Notifications are currently disabled in this build; re-enable when plugin
    // compatibility is addressed.
    Navigator.of(context).pop();
  }

  Future<void> _editNameDialog() async {
    final ctrl = TextEditingController(text: _nameCtrl.text);
    final res = await showDialog<String?>(context: context, builder: (ctx) => AlertDialog(title: const Text('Name'), content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Enter product name')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('OK'))]));
    if (res != null) setState(() => _nameCtrl.text = res);
  }

  @override
  Widget build(BuildContext context) {
    // Build UI that matches the provided mock exactly: minimal controls, product header,
    // details cards and a single large green add button.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add new item'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18),
        child: Column(
          children: [
            // Header with thumbnail and title
            _buildHeader(),
            const SizedBox(height: 18),
            // Details label
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Details',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            // Cards - extract to separate methods to avoid rebuilding all
            _buildTypeCard(),
            const SizedBox(height: 12),
            _buildQuantityCard(),
            const SizedBox(height: 12),
            _buildPurchasedCard(),
            const SizedBox(height: 12),
            _buildExpiryCard(),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '*Please confirm or change the expiry date as mentioned on the item!',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            const Spacer(),
            // Large centered green pill button
            _buildSaveButton(),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
      final thumb = _image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_image!.path),
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                cacheWidth: 128, // Cache at reasonable size
                cacheHeight: 128,
              ),
            )
          : (_networkImageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _networkImageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    cacheWidth: 128,
                    cacheHeight: 128,
                  ),
                )
              : Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image, size: 28, color: Colors.grey),
                ));

      final title = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Unnamed item';

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(onTap: _pickImage, child: thumb),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: _editNameDialog,
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                // subtle underline below title
                Container(height: 1, color: Colors.grey[300]),
              ],
            ),
          )
        ],
      );
    }

  Widget _buildTypeCard() {
    return _detailCard(
      label: 'Item type',
      value: _type,
      onTap: () async {
        final res = await showModalBottomSheet<String>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Select Item Type',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: _itemTypes.map((type) {
                      final isSelected = type['name'] == _type;
                      return ListTile(
                        leading: Icon(
                          type['icon'] as IconData,
                          color: isSelected ? const Color(0xFF10B981) : null,
                        ),
                        title: Text(
                          type['name'] as String,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? const Color(0xFF10B981) : null,
                          ),
                        ),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF10B981)) : null,
                        onTap: () => Navigator.of(ctx).pop(type['name'] as String),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
        if (res != null) setState(() => _type = res);
      },
    );
  }

  Widget _buildQuantityCard() {
    return _detailCard(
      label: 'Quantity',
      value: _quantityCtrl.text.isNotEmpty ? _quantityCtrl.text : '1',
      onTap: () async {
        final v = await showDialog<String?>(
          context: context,
          builder: (ctx) {
            final c = TextEditingController(text: _quantityCtrl.text);
            return AlertDialog(
              title: const Text('Quantity'),
              content: TextField(controller: c, keyboardType: TextInputType.text),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('OK')),
              ],
            );
          },
        );
        if (v != null) setState(() => _quantityCtrl.text = v);
      },
    );
  }

  Widget _buildPurchasedCard() {
    return _detailCard(
      label: 'Purchased',
      value: _fmtPurchased(_purchased),
      onTap: () => _pickDate(expiry: false),
    );
  }

  Widget _buildExpiryCard() {
    return _detailCard(
      label: 'Expires on',
      value: _fmtDate(_expiry),
      onTap: () => _pickDate(expiry: true),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.check, size: 20),
        label: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14.0),
          child: Text('Add this item', style: TextStyle(fontSize: 16)),
        ),
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          backgroundColor: const Color(0xFF10B981),
          elevation: 6,
          shadowColor: Colors.black45,
        ),
      ),
    );
  }

  Widget _detailCard({required String label, required String value, VoidCallback? onTap}) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
        ),
      );
    }

  String _fmtDate(DateTime d) {
      // e.g. 01 Jan 2022
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final dd = d.day.toString().padLeft(2, '0');
      final mm = months[d.month - 1];
      final yy = d.year.toString();
      return '$dd $mm $yy';
    }

  String _fmtPurchased(DateTime d) {
      final now = DateTime.now();
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        final mon = '${d.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.year}';
        return 'Today ($mon)';
      }
      return '${d.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.year}';
    }

  // OCR-from-URL helper removed; kept the minimal screen per mock

  // removed OCR/date parsing helpers; the simplified Add screen does not expose OCR UI
}
