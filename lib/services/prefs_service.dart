import 'package:shared_preferences/shared_preferences.dart';

/// 本地持久化服务：统一入口，进程内只初始化一次，后续读写走内存缓存。
/// 首次启动判断与之后新增的其他数据都复用这一份实例。
class PrefsService {
  static const _keyLaunched = 'launched';

  static SharedPreferences? _prefs;

  /// 预热存储：在 main 中 await 一次，之后读写均为同步内存操作
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 底层实例，供其他数据直接读写（支持 String/int/bool/double/List`<`String`>`）
  static SharedPreferences get prefs => _prefs!;

  /// 是否首次启动：无记录视为首次
  static bool get isFirstLaunch => !(_prefs?.getBool(_keyLaunched) ?? false);

  /// 标记已启动，之后不再进入启动屏幕
  static Future<bool> markLaunched() => prefs.setBool(_keyLaunched, true);
}
