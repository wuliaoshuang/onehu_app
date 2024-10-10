import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/theme_controller.dart';

class SecondPage extends StatelessWidget {
  const SecondPage({super.key, required book});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Page'),
        actions: [
          IconButton(
            icon: Obx(() => Icon(themeController.isDarkMode.value ? Icons.light_mode : Icons.dark_mode)),
            onPressed: themeController.toggleTheme,
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Go back'),
          onPressed: () => Get.back(),
        ),
      ),
    );
  }
}