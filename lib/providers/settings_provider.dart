import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  String name = '';
  String address = '';
  String mobile = '';
  String email = '';
  String countryCode = 'US';
  String? profileImagePath;
  ThemeMode themeMode = ThemeMode.system;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    name = prefs.getString('user_name') ?? '';
    address = prefs.getString('user_address') ?? '';
    mobile = prefs.getString('user_mobile') ?? '';
    email = prefs.getString('user_email') ?? '';
    countryCode = prefs.getString('user_country') ?? 'US';
    profileImagePath = prefs.getString('user_profile_image');
    final theme = prefs.getString('user_theme') ?? 'system';
    themeMode = theme == 'light' ? ThemeMode.light : theme == 'dark' ? ThemeMode.dark : ThemeMode.system;
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_address', address);
    await prefs.setString('user_mobile', mobile);
    await prefs.setString('user_email', email);
    await prefs.setString('user_country', countryCode);
    if (profileImagePath != null) {
      await prefs.setString('user_profile_image', profileImagePath!);
    }
    final theme = themeMode == ThemeMode.light ? 'light' : themeMode == ThemeMode.dark ? 'dark' : 'system';
    await prefs.setString('user_theme', theme);
  }

  void updateProfile({String? name, String? address, String? mobile, String? email, String? countryCode, String? profileImagePath}) {
    if (name != null) this.name = name;
    if (address != null) this.address = address;
    if (mobile != null) this.mobile = mobile;
    if (email != null) this.email = email;
    if (countryCode != null) this.countryCode = countryCode;
    if (profileImagePath != null) this.profileImagePath = profileImagePath;
    notifyListeners();
    save();
  }

  void updateTheme(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
    save();
  }
}
