import 'package:flutter/services.dart';

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
}
