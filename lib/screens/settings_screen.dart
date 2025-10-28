import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tracker/providers/settings_provider.dart';
import 'package:tracker/providers/item_provider.dart';
import 'package:tracker/models/item.dart';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtr;
  late TextEditingController _addressCtr;
  late TextEditingController _mobileCtr;
  late TextEditingController _emailCtr;

  @override
  void initState() {
    super.initState();
    final s = Provider.of<SettingsProvider>(context, listen: false);
    _nameCtr = TextEditingController(text: s.name);
    _addressCtr = TextEditingController(text: s.address);
    _mobileCtr = TextEditingController(text: s.mobile);
    _emailCtr = TextEditingController(text: s.email);
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _addressCtr.dispose();
    _mobileCtr.dispose();
    _emailCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, settings, _) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Profile Section Header
              _buildSectionHeader(context, 'Profile', Icons.person),
              const SizedBox(height: 12),
              
              // Profile Image
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 400,
                      maxHeight: 400,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      settings.updateProfile(profileImagePath: image.path);
                    }
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        backgroundImage: settings.profileImagePath != null
                            ? FileImage(File(settings.profileImagePath!))
                            : null,
                        child: settings.profileImagePath == null
                            ? Text(
                                settings.name.isNotEmpty
                                    ? settings.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().substring(0, settings.name.split(' ').length > 1 ? 2 : 1).toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Profile Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(controller: _nameCtr, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline))),
                    const SizedBox(height: 12),
                    TextFormField(controller: _addressCtr, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined))),
                    const SizedBox(height: 12),
                    TextFormField(controller: _mobileCtr, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile', prefixIcon: Icon(Icons.phone_outlined))),
                    const SizedBox(height: 12),
                    TextFormField(controller: _emailCtr, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.flag),
                      title: const Text('Country'),
                      subtitle: Text(settings.countryCode),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        showCountryPicker(context: context, onSelect: (country) {
                          settings.updateProfile(countryCode: country.countryCode);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          settings.updateProfile(
                            name: _nameCtr.text,
                            address: _addressCtr.text,
                            mobile: _mobileCtr.text,
                            email: _emailCtr.text,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile saved')),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Profile'),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              
              // Preferences Section
              _buildSectionHeader(context, 'Preferences', Icons.tune),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Theme'),
                subtitle: Text(_getThemeLabel(settings.themeMode)),
                trailing: DropdownButton<ThemeMode>(
                  value: settings.themeMode,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                    DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                  ],
                  onChanged: (v) {
                    if (v != null) settings.updateTheme(v);
                  },
                ),
              ),
              
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              
              // Data Management Section
              _buildSectionHeader(context, 'Data Management', Icons.storage),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.upload_file),
                title: const Text('Export Data'),
                subtitle: const Text('Backup all items to JSON'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _exportData(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.download),
                title: const Text('Import Data'),
                subtitle: const Text('Restore items from backup'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _importData(context),
              ),
              
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              
              // About Section
              _buildSectionHeader(context, 'About', Icons.info_outline),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.apps),
                title: const Text('App Version'),
                subtitle: const Text('1.0.0+1'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description),
                title: const Text('Licenses'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showLicensePage(context: context);
                },
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    });
  }
  
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
  
  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
    }
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final items = itemProvider.items;
      
      final data = {
        'export_date': DateTime.now().toIso8601String(),
        'items': items.map((item) => item.toMap()).toList(),
      };
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/expiry_tracker_backup_$timestamp.json');
      await file.writeAsString(jsonString);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported to:\n${file.path}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    // For now, show a message that user needs to place file in documents folder
    // In a production app, you'd use file_picker package
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'To import data:\n\n'
          '1. Place your backup JSON file in the app\'s documents folder\n'
          '2. The file should be named "import.json"\n'
          '3. Tap Import below\n\n'
          'Note: This will add items to your existing data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final directory = await getApplicationDocumentsDirectory();
                final file = File('${directory.path}/import.json');
                
                if (!await file.exists()) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('import.json file not found')),
                    );
                  }
                  return;
                }
                
                final jsonString = await file.readAsString();
                final data = jsonDecode(jsonString) as Map<String, dynamic>;
                final itemsData = (data['items'] as List).cast<Map<String, dynamic>>();
                
                // Convert JSON to Item objects
                final items = itemsData.map((itemMap) => Item.fromMap(itemMap)).toList();
                
                final itemProvider = Provider.of<ItemProvider>(context, listen: false);
                final count = await itemProvider.importItems(items);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully imported $count items')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import failed: $e')),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}
