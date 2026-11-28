import 'package:material_ui/material_ui.dart';

/// 卡片启动类型：普通应用，或小米电视的三个 HDMI 信号源。
/// HDMI 的 action/component/input 是固定组合，用户选类型即可，不必手填参数。
enum AppType {
  app(label: '普通 App', input: null),
  hdmi1(label: 'HDMI 1', input: 23),
  hdmi2(label: 'HDMI 2', input: 24),
  hdmi3(label: 'HDMI 3', input: 25);

  const AppType({required this.label, required this.input});

  /// 编辑页显示的名字
  final String label;

  /// 信号源对应的 input 值；普通应用为 null
  final int? input;

  bool get isHdmi => input != null;

  /// 小米电视播放器包名和信号源入口，三个 HDMI 类型共用
  static const hdmiPackage = 'com.xiaomi.mitv.tvplayer';
  static const hdmiAction = 'com.xiaomi.mitv.tvplayer.EXTSRC_PLAY';
  static const hdmiComponent = 'com.xiaomi.mitv.tvplayer/.ExternalSourceActivity';
}

/// 卡面底部蒙版颜色：只支持黑白两色，垫在名称下提升文字可读性。
enum CardMaskColor {
  black(label: '黑色', color: Colors.black),
  white(label: '白色', color: Colors.white);

  const CardMaskColor({required this.label, required this.color});

  /// 编辑页显示的名字
  final String label;

  /// 渐变蒙版实际使用的颜色
  final Color color;
}

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
    this.maskColor = CardMaskColor.black,
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

  /// 卡面底部渐变蒙版颜色，默认黑；与 textColor 搭配使用（白字配黑蒙版）
  final CardMaskColor maskColor;

  /// 由底层启动参数反推类型，兼容旧配置：配了显式组件就是信号源，按 input 值区分
  AppType get appType {
    if (launchComponent == null || launchComponent!.isEmpty) return AppType.app;
    final input = launchIntExtras?['input'];
    return AppType.values.firstWhere(
      (type) => type.isHdmi && type.input == input,
      orElse: () => AppType.hdmi3,
    );
  }

  /// 切换类型：信号源写入固定的 action/component/input，普通 App 则清掉这些参数
  AppInfo withAppType(AppType type) {
    if (type.isHdmi) {
      return AppInfo(
        name: name,
        packageName: AppType.hdmiPackage,
        launchAction: AppType.hdmiAction,
        launchComponent: AppType.hdmiComponent,
        launchIntExtras: {'input': type.input!},
        backgroundColor: backgroundColor,
        imageAsset: imageAsset,
        textColor: textColor,
        maskColor: maskColor,
      );
    }
    return AppInfo(
      name: name,
      packageName: packageName,
      backgroundColor: backgroundColor,
      imageAsset: imageAsset,
      textColor: textColor,
      maskColor: maskColor,
    );
  }

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
      // 旧配置没有这个字段，按默认的黑蒙版处理
      maskColor: _parseMaskColor(json['maskColor'] as String?),
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
        'maskColor': maskColor.name,
      };

  /// #AARRGGBB → Color，格式不对返回 null，交给字段默认值兜底
  static Color? _parseColor(String? value) {
    if (value == null || value.length != 9 || !value.startsWith('#')) {
      return null;
    }
    final argb = int.tryParse(value.substring(1), radix: 16);
    return argb == null ? null : Color(argb);
  }

  /// 非法取值回落到黑蒙版，避免脏配置导致渲染异常
  static CardMaskColor _parseMaskColor(String? value) =>
      CardMaskColor.values.firstWhere(
        (color) => color.name == value,
        orElse: () => CardMaskColor.black,
      );

  static String? _colorToString(Color? color) =>
      color == null ? null : '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
}
