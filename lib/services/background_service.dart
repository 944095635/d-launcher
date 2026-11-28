import 'dart:convert';
import 'dart:io';

import 'package:dlauncher/services/prefs_service.dart';

/// 背景图配置服务：从服务器拉取背景清单，缓存到本地，供首页读取。
class BackgroundService {
  /// 接口地址常量
  static const String baseUrl = 'http://music.dmskin.com';

  /// 背景配置路径
  static const String configPath = '/music/dLauncher/bg.json';

  static const String _cacheKey = 'background_images';
  static const Duration _timeout = Duration(seconds: 8);

  /// 读取缓存的背景图地址；未缓存返回空列表
  static List<String> get cachedImages =>
      PrefsService.prefs.getStringList(_cacheKey) ?? const [];

  /// 覆盖缓存
  static Future<bool> saveImages(List<String> images) =>
      PrefsService.prefs.setStringList(_cacheKey, images);

  /// 拉取服务器配置，返回图片地址列表；失败返回 null，调用方保留原缓存
  static Future<List<String>?> fetchImages() async {
    final client = HttpClient();
    client.connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(Uri.parse('$baseUrl$configPath'));
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      final decoded = json.decode(body);
      // 兼容 { "images": [...] } 与纯数组两种写法
      final raw = decoded is Map<String, dynamic> ? decoded['images'] : decoded;
      if (raw is! List) return null;
      final images = raw
          .whereType<String>()
          .map(resolveUrl)
          .where((url) => url.isNotEmpty)
          .toList();
      return images.isEmpty ? null : images;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  /// 相对地址拼到 baseUrl，绝对地址原样返回
  static String resolveUrl(String path) {
    if (path.startsWith('http')) return path;
    final separator = path.startsWith('/') ? '' : '/';
    return '$baseUrl$separator$path';
  }
}
