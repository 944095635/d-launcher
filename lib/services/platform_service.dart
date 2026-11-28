import 'package:flutter/services.dart';

import 'package:dlauncher/models/installed_app.dart';

/// Flutter 与原生 Android 通信的通道，系统能力统一从这里桥接。
class PlatformService {
  static const MethodChannel _channel = MethodChannel('com.dlauncher/platform');

  /// 调用原生方法，method 为原生侧约定的方法名
  static Future<T?> invoke<T>(String method, [dynamic arguments]) {
    return _channel.invokeMethod<T>(method, arguments);
  }

  /// 按包名拉起应用，返回原生是否成功发起
  static Future<bool> launchApp(String packageName) async {
    final result = await invoke<bool>('launchApp', {'packageName': packageName});
    return result ?? false;
  }

  /// 用显式 Intent 拉起组件（如切换 HDMI 信号源），返回原生是否成功发起
  static Future<bool> launchIntent({
    String? action,
    required String component,
    Map<String, int>? intExtras,
  }) async {
    final result = await invoke<bool>('launchIntent', {
      'action': action,
      'component': component,
      'intExtras': intExtras,
    });
    return result ?? false;
  }

  /// 打开系统设置页面（遥控器菜单键），返回原生是否成功发起
  /// 电视裁剪了设置入口时会失败，这里吞掉异常避免红屏
  static Future<bool> openSettings({String? packageName}) async {
    try {
      final result = await invoke<bool>('openSettings', {
        'packageName': packageName,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 列出可拉起的已安装应用，供设置页点选包名；失败返回空列表
  static Future<List<InstalledApp>> getInstalledApps() async {
    try {
      final result = await invoke<List<dynamic>>('getInstalledApps');
      if (result == null) return const [];
      return result
          .whereType<Map<dynamic, dynamic>>()
          .map(InstalledApp.fromJson)
          .toList();
    } on PlatformException {
      return const [];
    }
  }
}
