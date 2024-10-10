import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/read_controller.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ReadController controller = Get.find<ReadController>();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    try {
      await controller.initializeSearchData();
      Get.off(() => HomePage());
    } catch (e) {
      print('Error initializing data: $e');
      // 显示错误消息给用户
      Get.snackbar('错误', '初始化数据时出现问题，请重试。');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon.png', width: 100, height: 100),
            SizedBox(height: 20),
            Text('我就是盐神',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Obx(() => Text(controller.initializationStatus.value)),
            SizedBox(height: 20),
            Obx(() => CircularProgressIndicator(
                  value: controller.initializationProgress.value,
                )),
          ],
        ),
      ),
    );
  }
}
