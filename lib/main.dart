import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onehu_app/config/config.dart';
import 'controllers/home_data_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/counter_controller.dart';
import 'controllers/read_controller.dart';
import 'pages/splash_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知插件
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final DarwinInitializationSettings initializationSettingsDarwin =
      const DarwinInitializationSettings();
  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // 初始化控制器
  Get.put(ThemeController());
  Get.put(CounterController());
  Get.put(HomeDataController());
  Get.put(AppConfig());
  Get.put(ReadController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final AppConfig config = Get.find<AppConfig>();

    return Obx(() => GetMaterialApp(
          title: config.appName,
          theme: themeController.theme,
          themeMode: themeController.isDarkMode.value
              ? ThemeMode.dark
              : ThemeMode.light,
          home: SplashScreen(),
        ));
  }
}
