import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import 'package:tracker/providers/settings_provider.dart';

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
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(controller: _nameCtr, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                TextFormField(controller: _addressCtr, decoration: const InputDecoration(labelText: 'Address')),
                const SizedBox(height: 8),
                TextFormField(controller: _mobileCtr, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile')),
                const SizedBox(height: 8),
                TextFormField(controller: _emailCtr, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                ListTile(
                  title: Text('Country: ${settings.countryCode}'),
                  trailing: const Icon(Icons.map),
                  onTap: () {
                    showCountryPicker(context: context, onSelect: (country) {
                      settings.updateProfile(countryCode: country.countryCode);
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(children: [
                  const Text('Theme'),
                  const Spacer(),
                  DropdownButton<ThemeMode>(
                    value: settings.themeMode,
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                    ],
                    onChanged: (v) {
                      if (v != null) settings.updateTheme(v);
                    },
                  )
                ]),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    settings.updateProfile(name: _nameCtr.text, address: _addressCtr.text, mobile: _mobileCtr.text, email: _emailCtr.text);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
                  },
                  child: const Text('Save'),
                )
              ],
            ),
          ),
        ),
      );
    });
  }
}
