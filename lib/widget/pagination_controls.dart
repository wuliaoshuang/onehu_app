import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_data_controller.dart';

class PaginationControls extends StatelessWidget {
  final HomeDataController controller;

  const PaginationControls({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: (controller.page > 1 && !controller.isPageChanging.value)
                  ? controller.previousPage
                  : null,
              child: const Text('上一页'),
              style: _getButtonStyle(context),
            ),
            Text('第 ${controller.page} 页，共 ${controller.limit} 页'),
            ElevatedButton(
              onPressed: (controller.page < controller.limit.value && !controller.isPageChanging.value)
                  ? controller.nextPage
                  : null,
              child: const Text('下一页'),
              style: _getButtonStyle(context),
            ),
          ],
        )),
      ),
    );
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surface
          : Colors.grey[300],
      disabledForegroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.38)
          : Colors.grey[600],
    );
  }
}