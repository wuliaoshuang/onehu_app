import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'dart:developer' as dev;
import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;
import '../controllers/theme_controller.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';
import 'package:xml/xml.dart' as xml;
import 'package:shared_preferences/shared_preferences.dart';

class ReadController extends GetxController {
  final fontSize = 18.0.obs;
  final backgroundColor = Colors.white.obs;
  final textColor = Colors.black.obs;
  final showControls = true.obs;
  final ScrollController scrollController = ScrollController();
  final FlutterTts flutterTts = FlutterTts();
  var isSpeaking = false.obs;
  var currentParagraphIndex = 0.obs;
  var currentWordIndex = 0.obs;
  var totalWords = 0.obs;

  var title = ''.obs;
  var content = ''.obs;
  var publishTime = ''.obs;
  var wordCount = ''.obs;
  var viewCount = ''.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  final ThemeController themeController = Get.find<ThemeController>();

  var currentCharIndex = 0.obs;
  var totalChars = 0.obs;
  var progressValue = 0.0.obs;

  static const platform = MethodChannel('com.yourcompany.yourapp/tts');

  // 添加一個變量來保存當前正在播放的文本
  String currentText = '';

  static const int maxChunkSize = 3000; // 每个块的最大字符数
  int currentChunkIndex = 0;
  List<String> textChunks = [];

  // 添加新的属性
  var currentChapter = ''.obs;
  var totalChapters = 0.obs;

  // 添加通知相关的属性
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  var searchResults = <SearchResult>[].obs;
  var isSearching = false.obs;
  var isDataLoaded = false.obs;
  List<SearchResult> allEntries = [];

  var initializationStatus = '正在初始化...'.obs;
  var initializationProgress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    dev.log('ReadController onInit called');
    updateColors();
    ever(themeController.isDarkMode, (_) => updateColors());
    scrollController.addListener(_scrollListener);
    initTts();
    _initNotifications();
  }

  void _scrollListener() {
    if (scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      showControls.value = true;
    } else if (scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      showControls.value = false;
    }
  }

  void toggleControls() {
    showControls.value = !showControls.value;
    update(); // 确保UI更新
  }

  void increaseFontSize() {
    if (fontSize.value < 24) {
      fontSize.value += 2;
      update(); // 添加这行
    }
  }

  void decreaseFontSize() {
    if (fontSize.value > 12) {
      fontSize.value -= 2;
      update(); // 添加这行
    }
  }

  void updateColors() {
    if (themeController.isDarkMode.value) {
      backgroundColor.value = Colors.black;
      textColor.value = Colors.white;
    } else {
      backgroundColor.value = Colors.white;
      textColor.value = Colors.black;
    }
  }

  void setBackgroundColor(Color color) {
    backgroundColor.value = color;
    textColor.value =
        color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    flutterTts.stop();
    super.onClose();
  }

  Future<void> fetchContent(String url) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      dev.log('Fetching content from URL: $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var document = parse(response.body);

        var titleElement = document.querySelector('#subtitle');
        if (titleElement != null) {
          title.value = titleElement.text.trim();
          dev.log('Title found: ${title.value}');
        } else {
          dev.log('Title element not found');
        }

        var timeElement = document.querySelector('.icon-date-fill + time');
        if (timeElement != null) {
          publishTime.value = timeElement.text.trim();
          dev.log('Publish time found: ${publishTime.value}');
        }

        var wordCountElement = document.querySelector('.mt-1 .post-meta');
        if (wordCountElement != null) {
          wordCount.value = wordCountElement.text.trim();
          dev.log('Word count found: ${wordCount.value}');
        }

        var articleContent = document.querySelector('.markdown-body');
        if (articleContent != null) {
          articleContent
              .querySelectorAll('script, style, .post-copyright, #post-nav')
              .forEach((element) => element.remove());

          // 将内容分段
          contentParagraphs.value = articleContent.innerHtml
              .split('<p>')
              .where((element) => element.trim().isNotEmpty)
              .map((e) => '<p>$e')
              .toList();

          dev.log(
              'Content fetched successfully. Paragraphs: ${contentParagraphs.length}');
        } else {
          dev.log('Article content element not found');
          contentParagraphs.value = ['无法获取内容，请检查网页结构'];
          errorMessage.value = '无法找到文章内容元素';
        }

        await fetchViewCount(url);
      } else {
        dev.log('Failed to fetch content. Status code: ${response.statusCode}');
        contentParagraphs.value = ['获取内容失败，状态码: ${response.statusCode}'];
        errorMessage.value = '服务器返回错误状态码: ${response.statusCode}';
      }
    } catch (e) {
      dev.log('Error fetching content: $e');
      contentParagraphs.value = ['发生错误: $e'];
      errorMessage.value = '获取内容时发生错误: $e';
    } finally {
      isLoading.value = false;
      update(); // 添加这行来确保UI更新
    }
  }

  Future<void> fetchViewCount(String url) async {
    try {
      final callbackName =
          'BusuanziCallback_${(Random().nextDouble() * 1099511627776).floor()}';
      final busuanziUrl =
          'https://busuanzi.ibruce.info/busuanzi?jsonpCallback=$callbackName';

      final response = await http.get(
        Uri.parse(busuanziUrl),
        headers: {
          'Referer': url,
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
      );

      if (response.statusCode == 200) {
        // 提取JSON部分
        final match = RegExp(r'\((.*?)\)').firstMatch(response.body);
        if (match != null && match.groupCount >= 1) {
          final jsonStr = match.group(1);
          if (jsonStr != null) {
            final jsonData = json.decode(jsonStr);

            // 使用page_pv作为浏览量
            viewCount.value = jsonData['page_pv'].toString();
            dev.log('View count fetched: ${viewCount.value}');
          } else {
            throw Exception('Invalid JSON data');
          }
        } else {
          throw Exception('Failed to extract JSON data from response');
        }
      } else {
        throw Exception(
            'Failed to fetch view count. Status code: ${response.statusCode}');
      }
    } catch (e) {
      dev.log('Error fetching view count: $e');
      viewCount.value = 'Error';
    }
  }

  // 定义 infoTitle 变量
  final infoTitle = ''.obs;

  void setInfoTitle(String newTitle) {
    infoTitle.value = newTitle;
  }

  RxList<String> contentParagraphs = <String>[].obs;

  void initTts() async {
    try {
      dev.log('Initializing TTS');
      await flutterTts.setLanguage("zh-CN");
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);

      flutterTts.setCompletionHandler(() {
        dev.log('TTS completion handler called');
        if (isSpeaking.value) {
          currentChunkIndex++;
          _speakNextChunk();
        }
      });

      dev.log('TTS initialization completed');
    } catch (e) {
      dev.log('Error initializing TTS: $e');
      Get.snackbar('錯誤', '初始化語音功能時出現問題：$e');
    }
  }

  int currentPosition = 0;

  void toggleSpeaking() async {
    try {
      dev.log('toggleSpeaking called, current isSpeaking: ${isSpeaking.value}');
      if (isSpeaking.value) {
        await stopSpeaking();
      } else {
        await startSpeaking();
      }
    } catch (e) {
      dev.log('Error in toggleSpeaking: $e');
      Get.snackbar('錯誤', '語音功能出現問題：$e');
    }
  }

  Future<void> startSpeaking() async {
    if (contentParagraphs.isEmpty) {
      dev.log('No content to speak');
      Get.snackbar('錯誤', '沒有可朗讀的內容');
      return;
    }

    String fullText = contentParagraphs
        .map((paragraph) => parse(paragraph).documentElement?.text ?? '')
        .where((text) => text.trim().isNotEmpty)
        .join(" ");

    textChunks = _splitTextIntoChunks(fullText);
    currentChunkIndex = 0;

    isSpeaking.value = true;
    await _speakNextChunk();
    await showTtsNotification();
  }

  List<String> _splitTextIntoChunks(String text) {
    List<String> chunks = [];
    while (text.isNotEmpty) {
      if (text.length <= maxChunkSize) {
        chunks.add(text);
        break;
      }
      int endIndex = text.lastIndexOf(' ', maxChunkSize);
      if (endIndex == -1) endIndex = maxChunkSize;
      chunks.add(text.substring(0, endIndex));
      text = text.substring(endIndex).trim();
    }
    return chunks;
  }

  Future<void> _speakNextChunk() async {
    if (currentChunkIndex < textChunks.length) {
      String chunkToSpeak = textChunks[currentChunkIndex];
      dev.log(
          'Speaking chunk ${currentChunkIndex + 1} of ${textChunks.length}');

      var result = await flutterTts.speak(chunkToSpeak);
      dev.log('TTS speak result: $result');
      if (result == 1) {
        isSpeaking.value = true;
      } else {
        dev.log('TTS failed to start speaking chunk');
        Get.snackbar('錯誤', '無法開始朗讀');
        isSpeaking.value = false;
      }
    } else {
      isSpeaking.value = false;
      Get.snackbar('提示', '語音播放完成');
      await showTtsNotification();
    }
  }

  Future<void> stopSpeaking() async {
    var result = await flutterTts.stop();
    dev.log('Stop TTS result: $result');
    if (result == 1) {
      isSpeaking.value = false;
      currentChunkIndex = 0;
      Get.snackbar('提示', '語音播放已停止');
      await showTtsNotification();
    }
  }

  void testTts() async {
    try {
      dev.log('Testing TTS');
      String testText = "這是一個測試語音功能。";
      var result = await flutterTts.speak(testText);
      dev.log('Test TTS result: $result');
      if (result == 1) {
        Get.snackbar('成功', '語音測試成功');
      } else {
        Get.snackbar('錯誤', '語音測試失敗');
      }
    } catch (e) {
      dev.log('Error in testTts: $e');
      Get.snackbar('錯誤', '測試語音功能時出現問題：$e');
    }
  }

  Future<void> checkTtsStatus() async {
    try {
      var languages = await flutterTts.getLanguages;
      dev.log('TTS Languages: $languages');
      var engines = await flutterTts.getEngines;
      dev.log('TTS Engines: $engines');
      var defaultEngine = await flutterTts.getDefaultEngine;
      dev.log('TTS Default Engine: $defaultEngine');
      var defaultVoice = await flutterTts.getDefaultVoice;
      dev.log('TTS Default Voice: $defaultVoice');
    } catch (e) {
      dev.log('Error checking TTS status: $e');
    }
  }

  Future<void> startTts(String text) async {
    try {
      await platform.invokeMethod('startTtsService', {'text': text});
    } on PlatformException catch (e) {
      print("Failed to start TTS: '${e.message}'.");
    }
  }

  Future<void> stopTtsService() async {
    try {
      await platform.invokeMethod('stopTtsService');
    } on PlatformException catch (e) {
      print("Failed to stop TTS service: '${e.message}'.");
    }
  }

  Future<void> pauseTtsService() async {
    try {
      await platform.invokeMethod('pauseTtsService');
    } on PlatformException catch (e) {
      print("Failed to pause TTS service: '${e.message}'.");
    }
  }

  Future<void> resumeTtsService() async {
    try {
      await platform.invokeMethod('resumeTtsService');
    } on PlatformException catch (e) {
      print("Failed to resume TTS service: '${e.message}'.");
    }
  }

  // 在开始阅读时调用
  void speakInChunks() async {
    if (contentParagraphs.isEmpty) {
      dev.log('No content to speak');
      Get.snackbar('錯誤', '沒有可朗讀的內容');
      return;
    }

    isSpeaking.value = true;
    await showTtsNotification(); // 移除了参数

    String textToSpeak = contentParagraphs
        .map((paragraph) => parse(paragraph).documentElement?.text ?? '')
        .join(" ");

    textChunks = _splitTextIntoChunks(textToSpeak);
    currentChunkIndex = 0;

    await _speakNextChunk();

    updateProgressBar();
  }

  void updateProgressBar() {
    if (totalChars.value > 0) {
      int charsBefore = contentParagraphs
          .sublist(0, currentParagraphIndex.value)
          .fold(0, (sum, paragraph) {
        return sum + (parse(paragraph).documentElement?.text ?? '').length;
      });
      double progress =
          (charsBefore + currentCharIndex.value) / totalChars.value;
      progressValue.value = progress.clamp(0.0, 1.0);
      dev.log('Progress updated: ${progressValue.value}');
    } else {
      progressValue.value = 0.0;
    }
  }

  void setReadingProgress(double progress) {
    if (totalChars.value == 0) return;

    int targetChar = (progress * totalChars.value).round();
    int charCount = 0;

    for (int i = 0; i < contentParagraphs.length; i++) {
      String paragraphText =
          parse(contentParagraphs[i]).documentElement?.text ?? '';
      if (charCount + paragraphText.length > targetChar) {
        currentParagraphIndex.value = i;
        currentCharIndex.value = targetChar - charCount;
        break;
      }
      charCount += paragraphText.length;
    }

    updateProgressBar();

    // 如果正在播放，停止当前播放并从新位置开始
    if (isSpeaking.value) {
      stopSpeaking();
      speakInChunks();
    }
  }

  void _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );
  }

  Future<void> _onSelectNotification(NotificationResponse response) async {
    switch (response.actionId) {
      case 'play_pause':
        toggleSpeaking();
        break;
      case 'previous':
        // 实现上一章功能
        break;
      case 'next':
        // 实现下一章功能
        break;
    }
  }

  Future<void> showTtsNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'tts_playback_channel',
      'TTS Playback Controls',
      channelDescription: 'Controls for TTS playback',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('previous', '上一章'),
        AndroidNotificationAction('play_pause', '播放/暂停'),
        AndroidNotificationAction('next', '下一章'),
      ],
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      '热门小说大全 • ${currentChapter.value}',
      title.value,
      platformChannelSpecifics,
      payload: 'tts_notification',
    );
  }

  // 辅助函数
  int min(int a, int b) => a < b ? a : b;

  Future<void> initializeSearchData() async {
    try {
      initializationStatus.value = '检查本地数据...';
      initializationProgress.value = 0.1;
      await Future.delayed(Duration(milliseconds: 500)); // 添加延迟以显示进度

      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('search_data');

      if (storedData != null) {
        initializationStatus.value = '加载本地数据...';
        initializationProgress.value = 0.3;
        await Future.delayed(Duration(milliseconds: 500)); // 添加延迟以显示进度
        
        await _parseAndStoreData(storedData);
        
        initializationStatus.value = '本地数据加载完成';
        initializationProgress.value = 1.0;
      } else {
        initializationStatus.value = '从网络获取数据...';
        initializationProgress.value = 0.2;
        await Future.delayed(Duration(milliseconds: 500)); // 添加延迟以显示进度
        
        await _fetchAndStoreData();
      }
    } catch (e) {
      initializationStatus.value = '初始化失败: $e';
      initializationProgress.value = 0.0;
      print('Error initializing search data: $e');
    }
  }

  Future<void> _fetchAndStoreData() async {
    try {
      final response = await http.get(Uri.parse('https://onehu.xyz/local-search.xml'));
      if (response.statusCode == 200) {
        initializationStatus.value = '解析数据...';
        initializationProgress.value = 0.6;
        await Future.delayed(Duration(milliseconds: 500)); // 添加延迟以显示进度
        
        final xmlString = utf8.decode(response.bodyBytes);
        await _parseAndStoreData(xmlString);
        
        initializationStatus.value = '保存数据...';
        initializationProgress.value = 0.8;
        await Future.delayed(Duration(milliseconds: 500)); // 添加延迟以显示进度
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('search_data', xmlString);

        initializationStatus.value = '初始化完成';
        initializationProgress.value = 1.0;
      } else {
        throw Exception('Failed to load search data');
      }
    } catch (e) {
      print('Error fetching and storing data: $e');
      rethrow;
    }
  }

  Future<void> _parseAndStoreData(String xmlString) async {
    try {
      final document = xml.XmlDocument.parse(xmlString);
      final entries = document.findAllElements('entry');

      allEntries = entries.map((entry) {
        return SearchResult(
          title: entry.findElements('title').single.text,
          url: entry.findElements('url').single.text,
          content: entry.findElements('content').single.text,
        );
      }).toList();

      isDataLoaded.value = true;
    } catch (e) {
      print('Error parsing and storing data: $e');
      rethrow;
    }
  }

  Future<void> performSearch(String query) async {
    dev.log('performSearch called with query: $query');
    isSearching.value = true;

    if (!isDataLoaded.value) {
      await initializeSearchData();
    }

    searchResults.clear();

    try {
      final lowercaseQuery = query.toLowerCase();
      searchResults.value = allEntries.where((entry) {
        return entry.title.toLowerCase().contains(lowercaseQuery) ||
               entry.content.toLowerCase().contains(lowercaseQuery);
      }).toList();

      dev.log('Search completed. Found ${searchResults.length} results.');
    } catch (e) {
      dev.log('Error performing search: $e');
      Get.snackbar('錯誤', '搜索時出現問題：$e');
    } finally {
      isSearching.value = false;
    }
  }

  void clearSearchResults() {
    searchResults.clear();
  }
}

class SearchResult {
  final String title;
  final String url;
  final String content;

  SearchResult({required this.title, required this.url, required this.content});
}