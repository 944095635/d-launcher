import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:dlauncher/services/prefs_service.dart';

/// 背景展示方式：不使用背景、固定一张，或从服务器清单随机轮换
enum BackgroundMode { none, fixed, server }

/// 背景图配置服务：管理展示方式、固定图地址，以及服务器清单的拉取与缓存。
class BackgroundService {
  /// 接口地址常量
  static const String baseUrl = 'http://music.dmskin.com';

  /// 背景配置路径
  static const String configPath = '/music/dLauncher/bg/bg.json';

  static const String _cacheKey = 'background_images';
  static const String _modeKey = 'background_mode';
  static const String _fixedImageKey = 'background_fixed_image';
  static const Duration _timeout = Duration(seconds: 8);

  static const String _imageDir = 'assets/images/';
  static const String _cardImagePrefix = 'card_';

  /// 当前展示方式，默认服务器随机
  static BackgroundMode get mode => switch (PrefsService.prefs.getString(_modeKey)) {
        'none' => BackgroundMode.none,
        'fixed' => BackgroundMode.fixed,
        _ => BackgroundMode.server,
      };

  static Future<bool> saveMode(BackgroundMode mode) =>
      PrefsService.prefs.setString(_modeKey, mode.name);

  /// 固定图地址：本地 asset 路径或 http URL
  static String get fixedImage =>
      PrefsService.prefs.getString(_fixedImageKey) ?? '';

  static Future<bool> saveFixedImage(String image) =>
      PrefsService.prefs.setString(_fixedImageKey, image);

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

  /// 打包在 images 目录下的背景图，排除卡片贴图；供设置页本地选择使用
  /// 新版 Flutter 不再生成 AssetManifest.json，必须用官方 API 读清单
  static Future<List<String>> loadLocalImages() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest
        .listAssets()
        .where((path) => path.startsWith(_imageDir))
        .where(
          (path) =>
              !path.substring(_imageDir.length).startsWith(_cardImagePrefix),
        )
        .toList();
  }
}
