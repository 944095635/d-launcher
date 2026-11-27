import 'package:shared_preferences/shared_preferences.dart';

/// 启动状态服务：记录是否首次启动，决定首屏路由。
class LaunchService {
  static const _keyLaunched = 'launched';
  static SharedPreferences? _prefs;

  /// 预热本地存储，全局只初始化一次，后续读写走内存缓存
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 是否首次启动：无记录视为首次
  static bool get isFirstLaunch => !(_prefs?.getBool(_keyLaunched) ?? false);

  /// 标记已启动，后续不再进入启动屏幕
  static Future<void> markLaunched() => _prefs!.setBool(_keyLaunched, true);
}
