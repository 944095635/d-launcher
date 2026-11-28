import 'package:material_ui/material_ui.dart';

/// 桌面 App 信息：卡片展示与后续拉起应用的数据载体。
class AppInfo {
  const AppInfo({
    required this.name,
    this.packageName,
    this.launchAction,
    this.launchComponent,
    this.launchIntExtras,
    this.backgroundColor,
    this.imageAsset,
    this.textColor = Colors.white,
  });

  /// 卡片上显示的名称，如「哔哩哔哩」
  final String name;

  /// 应用包名，普通应用通过原生层按包名拉起
  final String? packageName;

  /// 显式 Intent 的 action；配合 launchComponent 用于信号源切换等特殊入口
  final String? launchAction;

  /// 显式组件名（格式：包名/.Activity）；配置了就走组件直启，不再按包名拉起
  final String? launchComponent;

  /// 显式 Intent 携带的 int 参数，如 HDMI3 对应 input=25
  final Map<String, int>? launchIntExtras;

  /// 卡片背景色，未指定时卡片用默认黑色；有贴图时不绘制底色
  final Color? backgroundColor;

  /// 卡面贴图：http(s) 开头的网络地址或本地资源路径，未指定时只显示纯色卡面
  final String? imageAsset;

  /// 卡片文字颜色，默认白，适配深色系卡面
  final Color textColor;

  /// 从 JSON 还原；颜色用 #AARRGGBB 字符串，缺省时按构造函数的默认值处理
  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      name: json['name'] as String? ?? '',
      packageName: json['packageName'] as String?,
      launchAction: json['launchAction'] as String?,
      launchComponent: json['launchComponent'] as String?,
      launchIntExtras: (json['launchIntExtras'] as Map<dynamic, dynamic>?)?.map(
        (key, value) => MapEntry(key as String, value as int),
      ),
      backgroundColor: _parseColor(json['backgroundColor'] as String?),
      imageAsset: json['imageAsset'] as String?,
      textColor: _parseColor(json['textColor'] as String?) ?? Colors.white,
    );
  }

  /// 序列化为可存 JSON 的 Map，颜色转成 #AARRGGBB
  Map<String, dynamic> toJson() => {
        'name': name,
        'packageName': packageName,
        'launchAction': launchAction,
        'launchComponent': launchComponent,
        'launchIntExtras': launchIntExtras,
        'backgroundColor': _colorToString(backgroundColor),
        'imageAsset': imageAsset,
        'textColor': _colorToString(textColor),
      };

  /// #AARRGGBB → Color，格式不对返回 null，交给字段默认值兜底
  static Color? _parseColor(String? value) {
    if (value == null || value.length != 9 || !value.startsWith('#')) {
      return null;
    }
    final argb = int.tryParse(value.substring(1), radix: 16);
    return argb == null ? null : Color(argb);
  }

  static String? _colorToString(Color? color) =>
      color == null ? null : '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
}
