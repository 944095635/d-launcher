import 'dart:convert';
import 'dart:io';

import 'package:dlauncher/services/background_service.dart';
import 'package:dlauncher/services/prefs_service.dart';

/// 卡片贴图服务：从服务器 card.json 拉取可用贴图清单并缓存到本地。
/// 与背景图共用服务器地址和超时配置，只换配置路径。
class CardImageService {
  /// 贴图清单配置路径
  static const String configPath = '/music/dLauncher/card/card.json';

  static const String _cacheKey = 'card_images';
  static const Duration _timeout = Duration(seconds: 8);

  /// 读取缓存的贴图地址；未缓存返回空列表
  static List<String> get cachedImages =>
      PrefsService.prefs.getStringList(_cacheKey) ?? const [];

  /// 覆盖缓存
  static Future<bool> saveImages(List<String> images) =>
      PrefsService.prefs.setStringList(_cacheKey, images);

  /// 拉取服务器配置，返回贴图地址列表；失败返回 null，调用方保留原缓存
  static Future<List<String>?> fetchImages() async {
    final client = HttpClient();
    client.connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(Uri.parse(_url));
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      final decoded = json.decode(body);
      // 兼容 { "images": [...] } 与纯数组两种写法，和 bg.json 保持一致
      final raw = decoded is Map<String, dynamic> ? decoded['images'] : decoded;
      if (raw is! List) return null;
      final images = raw
          .whereType<String>()
          .map(_resolveUrl)
          .where((url) => url.isNotEmpty)
          .toList();
      return images.isEmpty ? null : images;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  static String get _url => '${BackgroundService.baseUrl}$configPath';

  /// 相对地址拼到共用的 baseUrl，绝对地址原样返回
  static String _resolveUrl(String path) =>
      BackgroundService.resolveUrl(path);
}
