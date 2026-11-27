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
    this.logoAsset,
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

  /// 卡片背景色，未指定时卡片用默认白色
  final Color? backgroundColor;

  /// 卡面贴图：http(s) 开头的网络地址或本地资源路径，未指定时只显示纯色卡面
  final String? imageAsset;

  /// 卡片中心区域显示的 logo，保持原始比例，未指定则不显示
  final String? logoAsset;

  /// 卡片文字颜色，默认白，适配深色系卡面
  final Color textColor;
}
