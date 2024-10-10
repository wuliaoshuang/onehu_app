import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/read_controller.dart';
import '../dto/book_dto.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tts/flutter_tts.dart'; // 添加这行

class ReadPage extends StatelessWidget {
  final Book book;

  ReadPage({Key? key, required this.book}) : super(key: key);

  final ReadController controller = Get.put(ReadController());

  @override
  Widget build(BuildContext context) {
    controller.fetchContent(book.link);
    controller.setInfoTitle(book.title);

    return Scaffold(
      body: SafeArea(
        child: GetBuilder<ReadController>(
          builder: (controller) {
            if (controller.isLoading.value) {
              return Center(child: CircularProgressIndicator());
            } else if (controller.errorMessage.value.isNotEmpty) {
              return Center(child: Text(controller.errorMessage.value));
            } else if (controller.contentParagraphs.isEmpty) {
              return Center(child: Text('No content available'));
            } else {
              return GestureDetector(
                onTap: controller.toggleControls,
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: controller.scrollController,
                      itemCount: controller.contentParagraphs.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildHeader();
                        } else {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Html(
                              data: controller.contentParagraphs[index - 1],
                              style: {
                                "body": Style(
                                  fontSize: FontSize(controller.fontSize.value),
                                  color: controller.textColor.value,
                                  lineHeight: const LineHeight(1.2),
                                ),
                                "p": Style(
                                  margin: Margins(bottom: Margin(8)),
                                ),
                              },
                            ),
                          );
                        }
                      },
                    ),
                    if (controller.showControls.value) ...[
                      _buildTopBar(),
                      _buildBottomBar(),
                    ],
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 16),
          Text(
            controller.title.value,
            style: TextStyle(
              fontSize: controller.fontSize.value + 4,
              fontWeight: FontWeight.bold,
              color: controller.textColor.value,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            controller.infoTitle.value,
            style: TextStyle(
              fontSize: controller.fontSize.value + 2,
              fontWeight: FontWeight.bold,
              color: controller.textColor.value,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoItem(Icons.access_time, controller.publishTime.value),
              SizedBox(width: 16),
              _buildInfoItem(
                  Icons.format_list_numbered, controller.wordCount.value),
              SizedBox(width: 16),
              _buildInfoItem(Icons.remove_red_eye, controller.viewCount.value),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: controller.textColor.value.withOpacity(0.7),
        ),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: controller.fontSize.value - 2,
            color: controller.textColor.value.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: controller.showControls.value ? 1.0 : 0.0,
        duration: Duration(milliseconds: 200),
        child: Container(
          height: 56,
          color: Colors.black.withOpacity(0.5),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
              Expanded(
                child: Text(
                  book.title,
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: Icon(Icons.settings, color: Colors.white),
                onPressed: () => _showSettingsDialog(Get.context!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: controller.showControls.value ? 1.0 : 0.0,
        duration: Duration(milliseconds: 200),
        child: Container(
          height: 100,
          color: Colors.black.withOpacity(0.5),
          child: Column(
            children: [
              _buildProgressBar(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  Text(
                    '${controller.wordCount.value}',
                    style: TextStyle(color: Colors.white),
                  ),
                  Obx(() => IconButton(
                        icon: Icon(
                          controller.isSpeaking.value
                              ? Icons.stop
                              : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          dev.log('Play/Stop button pressed');
                          controller.toggleSpeaking();
                        },
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('阅读设置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('字体大小'),
                trailing: Obx(() => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: controller.decreaseFontSize,
                        ),
                        Text('${controller.fontSize.value.toInt()}'),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: controller.increaseFontSize,
                        ),
                      ],
                    )),
              ),
              ListTile(
                title: Text('背景颜色'),
                trailing: Obx(() => DropdownButton<Color>(
                      value: controller.backgroundColor.value,
                      onChanged: (Color? newValue) {
                        if (newValue != null) {
                          controller.setBackgroundColor(newValue);
                        }
                      },
                      items: [
                        DropdownMenuItem(
                            value: Colors.white, child: Text('白色')),
                        DropdownMenuItem(
                            value: Colors.black, child: Text('黑色')),
                        DropdownMenuItem(
                            value: Color(0xFFF4ECD8), child: const Text('褐色')),
                      ],
                    )),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('关闭'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return Obx(() => Slider(
          value: controller.progressValue.value,
          min: 0.0,
          max: 1.0,
          onChanged: (double value) {
            controller.setReadingProgress(value);
          },
          onChangeStart: (double value) {
            if (controller.isSpeaking.value) {
              controller.flutterTts.stop();
            }
          },
          onChangeEnd: (double value) {
            if (controller.isSpeaking.value) {
              controller.speakInChunks();
            }
          },
        ));
  }
}
