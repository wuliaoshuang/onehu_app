class Book {
  final String title;
  final String intro;
  final DateTime releaseTime;
  final String author;
  final List<String> tags;
  final String link;  // 新增字段

  Book({
    required this.title,
    required this.intro,
    required this.releaseTime,
    required this.author,
    required this.tags,
    required this.link,  // 新增字段
  });

  // 更新 fromJson 方法
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'] as String,
      intro: json['intro'] as String,
      releaseTime: DateTime.parse(json['release_time'] as String),
      author: json['author'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      link: json['link'] as String,  // 新增字段
    );
  }

  // 更新 toJson 方法
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'intro': intro,
      'release_time': releaseTime.toIso8601String(),
      'author': author,
      'tags': tags,
      'link': link,  // 新增字段
    };
  }
}