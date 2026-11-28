import 'package:shared_preferences/shared_preferences.dart';

/// 本地持久化服务：统一入口，进程内只初始化一次，后续读写走内存缓存。
class PrefsService {
  static SharedPreferences? _prefs;

  /// 预热存储：在 main 中 await 一次，之后读写均为同步内存操作
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 底层实例，供其他数据直接读写（支持 String/int/bool/double/List`<`String`>`）
  static SharedPreferences get prefs => _prefs!;
}
