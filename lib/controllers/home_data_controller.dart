import 'package:get/get.dart';
import 'package:onehu_app/config/config.dart';
import 'package:onehu_app/dto/book_dto.dart';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as html;
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart'; // 添加这行导入
import 'dart:async'; // 添加这行导入

class HomeDataController extends GetxController {
  var page = 1;
  RxInt limit = 10.obs; // 将 limit 改为 RxInt
  RxBool isLoading = false.obs;
  RxList<Book> bookList = <Book>[].obs;
  final config = Get.put(AppConfig());
  final EasyRefreshController refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );
  RxString searchQuery = ''.obs;
  final TextEditingController searchController =
      TextEditingController(); // 添加这行

  Timer? _debounce;

  RxBool isPageChanging = false.obs; // 添加这行

  @override
  void onInit() {
    super.onInit();
    getBooks(); // 在初始化时获取书籍，这将同时更新页面总数
  }

  @override
  void onClose() {
    _debounce?.cancel();
    refreshController.dispose();
    searchController.dispose(); // 添加这行
    super.onClose();
  }

  Future<void> getPageLimit() async {
    try {
      final res = await http.get(Uri.parse(config.apiBaseUrl));
      if (res.statusCode == 200) {
        var doc = parse(res.body); // 修改这里，移除 Document 类型
        List<html.Element> paginations = doc.querySelectorAll('.page-number');

        if (paginations.isNotEmpty) {
          var limitStr = paginations.last.text.trim();
          log('Extracted limit string: $limitStr');

          int? parsedLimit = int.tryParse(limitStr);
          if (parsedLimit != null) {
            limit.value = parsedLimit;
            log('Set limit to: ${limit.value}');
          } else {
            log('Failed to parse limit: $limitStr');
          }
        } else {
          log('No pagination elements found');
        }
      }
    } catch (e) {
      log('Error in getPageLimit: ${e.toString()}');
    }
  }

  Future<void> getBooks() async {
    isLoading.value = true;
    isPageChanging.value = true; // 添加这行
    update();
    try {
      await getPageLimit(); // 首先获取页面总数

      String url =
          page == 1 ? config.apiBaseUrl : '${config.apiBaseUrl}page/$page/';
      log('Fetching books from URL: $url');
      var res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        bookList.clear(); // 清空列表
        var doc = parse(res.body);
        List<html.Element> books = doc.querySelectorAll('.row.mx-auto.index-card');
        for (var book in books) {
          String title =
              book.querySelector('.index-header a')?.text.trim() ?? '';
          String intro =
              book.querySelector('.index-excerpt__noimg div')?.text.trim() ??
                  '';
          String releaseTime =
              book.querySelector('.icon-date + time')?.text.trim() ?? '';
          String author =
              book.querySelector('.category-chain-item')?.text.trim() ?? '未知作者';
          List<String> tags = book
              .querySelectorAll('.icon-tags + a')
              .map((e) => e.text.trim())
              .toList();

          DateTime parsedReleaseTime;
          try {
            parsedReleaseTime = DateTime.parse(releaseTime);
          } catch (e) {
            parsedReleaseTime = DateTime.now();
            log('Failed to parse date: $releaseTime. Using current date.');
          }

          String relativeLink =
              book.querySelector('.index-header a')?.attributes['href'] ?? '';
          String fullLink =
              Uri.parse(config.apiBaseUrl).resolve(relativeLink).toString();

          bookList.add(Book(
              title: title,
              author: author,
              intro: intro,
              releaseTime: parsedReleaseTime,
              tags: tags,
              link: fullLink));
        }
        log('Fetched ${bookList.length} books');
      } else {
        log('Failed to fetch books. Status code: ${res.statusCode}');
      }
    } catch (e) {
      log('Error in getBooks: ${e.toString()}');
    } finally {
      isLoading.value = false;
      isPageChanging.value = false; // 添加这行
      refreshController.finishRefresh(IndicatorResult.success, true);
      update();
    }
  }

  void debouncedNextPage() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (page < limit.value) {
        page++;
        getBooks();
      }
    });
  }

  void debouncedPreviousPage() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (page > 1) {
        page--;
        getBooks();
      }
    });
  }

  bool get isLimitLoaded => limit.value != 10;

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void clearSearch() {
    searchQuery.value = '';
    searchController.clear(); // 清除搜索框的内容
    // getBooks(); // 重新获取所有书籍
  }

  void performSearch() {
    if (searchQuery.isNotEmpty) {
      // 实现搜索逻辑
      // 这里你可能需要调用一个新的API或过滤现有的bookList
      log('Performing search for: ${searchQuery.value}');
      // 示例：过滤现有列表
      var filteredList = bookList
          .where((book) =>
              book.title
                  .toLowerCase()
                  .contains(searchQuery.value.toLowerCase()) ||
              book.author
                  .toLowerCase()
                  .contains(searchQuery.value.toLowerCase()))
          .toList();
      bookList.value = filteredList;
      update();
    }
  }

  void nextPage() {
    if (!isPageChanging.value && page < limit.value) {
      debouncedNextPage();
    }
  }

  void previousPage() {
    if (!isPageChanging.value && page > 1) {
      debouncedPreviousPage();
    }
  }
}
