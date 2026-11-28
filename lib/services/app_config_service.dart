import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:dlauncher/models/app_info.dart';
import 'package:dlauncher/services/prefs_service.dart';

/// 桌面 App 配置服务：以打包的 apps.json 为默认，编辑结果存本地缓存。
class AppConfigService {
  static const String _configAsset = 'assets/config/apps.json';
  static const String _cacheKey = 'desktop_apps';

  /// 读取当前配置：有本地缓存（用户编辑过）就用，否则回退到打包的默认配置
  static Future<List<AppInfo>> loadApps() async {
    final cached = PrefsService.prefs.getString(_cacheKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        return _decode(cached);
      } catch (_) {
        // 缓存损坏时丢掉，退回默认配置，避免设置页进不去
      }
    }
    return _loadDefault();
  }

  /// 保存编辑后的配置
  static Future<void> saveApps(List<AppInfo> apps) {
    return PrefsService.prefs.setString(
      _cacheKey,
      json.encode({'apps': apps.map((app) => app.toJson()).toList()}),
    );
  }

  /// 恢复默认配置：清掉本地缓存，下次读取回到打包的 apps.json
  static Future<void> resetToDefault() =>
      PrefsService.prefs.remove(_cacheKey);

  /// 读取打包的默认配置
  static Future<List<AppInfo>> _loadDefault() async {
    try {
      final body = await rootBundle.loadString(_configAsset);
      return _decode(body);
    } catch (_) {
      return const [];
    }
  }

  static List<AppInfo> _decode(String body) {
    final decoded = json.decode(body);
    final raw = decoded is Map<String, dynamic> ? decoded['apps'] : decoded;
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AppInfo.fromJson)
        .where((app) => app.name.isNotEmpty)
        .toList();
  }
}
