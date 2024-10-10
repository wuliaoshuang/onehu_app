import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  var isDarkMode = false.obs;
  var currentColorScheme = 0.obs;

  final List<ColorScheme> lightColorSchemes = [
    const ColorScheme.light(primary: Colors.blue),
    const ColorScheme.light(primary: Colors.red),
    const ColorScheme.light(primary: Colors.green),
    const ColorScheme.light(primary: Colors.purple),
    const ColorScheme.light(primary: Colors.teal),
    const ColorScheme.light(primary: Colors.amber),
    const ColorScheme.light(primary: Colors.deepOrange),
    const ColorScheme.light(primary: Colors.indigo),
    const ColorScheme.light(primary: Colors.pink),
  ];

  final List<ColorScheme> darkColorSchemes = [
    const ColorScheme.dark(primary: Colors.blue, background: Color(0xFF121212)),
    const ColorScheme.dark(primary: Colors.red, background: Color(0xFF121212)),
    const ColorScheme.dark(primary: Colors.green, background: Color(0xFF121212)),
    const ColorScheme.dark(primary: Colors.purple, background: Color(0xFF121212)),
    const ColorScheme.dark(primary: Colors.teal, background: Color(0xFF121212)),
    const ColorScheme.dark(primary: Colors.amber, background: Color(0xFF121212)),
    const ColorScheme.dark(primary: Colors.deepOrange, background: Color(0xFF121212)),
    const ColorScheme.dark(primary: Colors.indigo, background: Color(0xFF121212)),
    const ColorScheme.dark(primary: Colors.pink, background: Color(0xFF121212)),
  ];

  @override
  void onInit() {
    super.onInit();
    loadThemeSettings();
  }

  Future<void> loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('isDarkMode') ?? false;
    currentColorScheme.value = prefs.getInt('currentColorScheme') ?? 0;
    _updateTheme();
  }

  Future<void> saveThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode.value);
    await prefs.setInt('currentColorScheme', currentColorScheme.value);
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _updateTheme();
    saveThemeSettings();
  }

  void changeColorScheme(int index) {
    if (index >= 0 && index < lightColorSchemes.length) {
      currentColorScheme.value = index;
      _updateTheme();
      saveThemeSettings();
    }
  }

  void _updateTheme() {
    final newTheme = _getThemeData();
    Get.changeTheme(newTheme);
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  ThemeData _getThemeData() {
    final colorScheme = isDarkMode.value
        ? darkColorSchemes[currentColorScheme.value]
        : lightColorSchemes[currentColorScheme.value];

    return ThemeData(
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
      scaffoldBackgroundColor: colorScheme.background,
    );
  }

  ThemeData get theme => _getThemeData();
}
