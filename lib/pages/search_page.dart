import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/read_controller.dart';
import 'dart:developer' as dev;
import '../pages/read_page.dart';
import '../dto/book_dto.dart';
import '../config/config.dart';

class SearchPage extends StatefulWidget {
  SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();
  final ReadController readController = Get.find<ReadController>();
  final AppConfig config = Get.find<AppConfig>();

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (searchController.text.isNotEmpty) {
      _performSearch();
    } else {
      setState(() {
        readController.clearSearchResults();
      });
    }
  }

  void _performSearch() {
    final query = searchController.text;
    if (query.isNotEmpty) {
      dev.log('执行搜索: $query');
      readController.performSearch(query);
      setState(() {}); // 触发重建
    } else {
      dev.log('搜索查询为空');
      readController.clearSearchResults();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('搜索'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: '搜索...',
                  prefixIcon: const Icon(Icons.search,
                      color: Color.fromARGB(49, 0, 0, 0)),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: Color.fromARGB(49, 0, 0, 0)),
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              readController.clearSearchResults();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() => _buildSearchResults()),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (readController.isSearching.value) {
      return Center(child: CircularProgressIndicator());
    } else if (readController.searchResults.isEmpty) {
      return Center(child: Text('没有找到相关结果'));
    } else {
      return ListView.builder(
        itemCount: readController.searchResults.length,
        itemBuilder: (context, index) {
          final result = readController.searchResults[index];
          final book = Book(
            title: result.title,
            link: Uri.parse(config.apiBaseUrl).resolve(result.url).toString(),
            intro: result.content,
            releaseTime: DateTime.now(),
            author: '未知',
            tags: [],
          );
          return Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReadPage(book: book)),
                );
                dev.log('跳转到阅读页面: ${book.link}');
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.intro,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }
}
