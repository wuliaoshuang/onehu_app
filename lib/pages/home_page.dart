import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onehu_app/config/config.dart';
import 'package:onehu_app/controllers/read_controller.dart';
import 'package:onehu_app/pages/search_page.dart';
import '../controllers/home_data_controller.dart';
import '../controllers/theme_controller.dart';
import 'package:easy_refresh/easy_refresh.dart';
import '../widget/pagination_controls.dart';
import '../widget/book_list_item.dart';
import '../widget/custom_progress_indicator.dart';
import '../widget/lottie_header.dart';

class HomePage extends GetView<HomeDataController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final AppConfig config = Get.find<AppConfig>();

    return Scaffold(
      appBar: AppBar(
        title: Text(config.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Get.to(() => SearchPage())?.then((_) {
                Get.find<ReadController>().clearSearchResults();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showThemeMenu(context, themeController),
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        color: Theme.of(context).colorScheme.background,
        child: Column(
          children: [
            Expanded(
              child: EasyRefresh(
                controller: controller.refreshController,
                header: const LottieHeader(
                  assetName: 'assets/lottie/refresh_animation.json',
                  triggerOffset: 140,
                ),
                onRefresh: () async {
                  await controller.getBooks();
                  return IndicatorResult.success;
                },
                refreshOnStart: true,
                child: Column(
                  children: [
                    Expanded(
                      child: Obx(() => controller.isLoading.value
                          ? _buildLoadingList()
                          : _buildBookList()),
                    ),
                    PaginationControls(controller: controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          title: const CustomProgressIndicator(),
          subtitle: const CustomProgressIndicator(),
        );
      },
    );
  }

  Widget _buildBookList() {
    return ListView.builder(
      itemCount: controller.bookList.length,
      itemBuilder: (context, index) {
        final book = controller.bookList[index];
        return BookListItem(book: book);
      },
    );
  }

  void _showThemeMenu(BuildContext context, ThemeController themeController) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(1000.0, 0.0, 0.0, 0.0),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: Icon(themeController.isDarkMode.value
                ? Icons.light_mode
                : Icons.dark_mode),
            title:
                Text(themeController.isDarkMode.value ? '切换到浅色模式' : '切换到深色模式'),
            onTap: () {
              themeController.toggleTheme();
              Navigator.pop(context);
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('选择主题色'),
            onTap: () {
              Navigator.pop(context);
              _showThemeColorPicker(context, themeController);
            },
          ),
        ),
      ],
    );
  }

  void _showThemeColorPicker(
      BuildContext context, ThemeController themeController) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Wrap(
            children: <Widget>[
              const ListTile(
                leading: Icon(Icons.format_paint),
                title: Text('选择主题色'),
              ),
              Obx(() => Wrap(
                    children: List.generate(
                      themeController.lightColorSchemes.length,
                      (index) => GestureDetector(
                        onTap: () {
                          themeController.changeColorScheme(index);
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: themeController.isDarkMode.value
                                ? themeController
                                    .darkColorSchemes[index].primary
                                : themeController
                                    .lightColorSchemes[index].primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: index ==
                                      themeController.currentColorScheme.value
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}
