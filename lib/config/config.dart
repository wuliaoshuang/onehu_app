class AppConfig {
  // 单例模式
  static final AppConfig _instance = AppConfig._internal();

  factory AppConfig() {
    return _instance;
  }

  AppConfig._internal();

  // 应用程序名称
  final String appName = '我就是盐神';

  // API 基础 URL
  final String apiBaseUrl = 'https://onehu.xyz/';
}
