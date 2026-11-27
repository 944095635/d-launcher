import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/models/app_info.dart';
import 'package:dlauncher/services/platform_service.dart';

/// 首页状态：实时时钟 + 桌面 App 列表。
class HomeController extends GetxController {
  Timer? _timer;

  /// 时间，如 15:18
  final time = ''.obs;

  /// 日期，如 2026年11月27日
  final date = ''.obs;

  /// 星期，如 星期五
  final weekday = ''.obs;

  /// 桌面卡片对应的 App 列表，最多 4 个
  final apps = <AppInfo>[].obs;

  /// 当前获得焦点的卡片索引，遥控器左右键切换
  final focusedIndex = 0.obs;

  /// 首页背景图路径，定时从 images 目录随机切换
  final backgroundImage = ''.obs;

  static const _weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
  static const _maxApps = 4;
  static const _backgroundInterval = Duration(minutes: 30);
  static const _imageDir = 'assets/images/';
  /// 卡片贴图不参与背景轮换，避免背景与卡片撞图
  static const _cardImagePrefix = 'card_';

  Timer? _backgroundTimer;
  /// 背景候选图，供定时轮换与手动刷新共用
  List<String> _backgroundImages = const [];
  final _random = Random();

  @override
  void onInit() {
    super.onInit();
    _updateClock();
    // 只显示到分钟，对齐到下一分钟边界刷新，避免无意义的每秒重建
    _scheduleNextTick();
    _initApps();
    _startBackgroundRotation();
  }

  /// 添加 App，超出上限则忽略，保证卡片不超过 4 张
  void addApp(AppInfo app) {
    if (apps.length >= _maxApps) return;
    apps.add(app);
  }

  /// 遥控器左右移动焦点：到头循环到另一端，保持光标始终锁在卡片区
  void moveFocus(int delta) {
    final count = apps.length;
    if (count == 0) return;
    focusedIndex.value = (focusedIndex.value + delta + count) % count;
  }

  /// 确认键：拉起当前焦点卡片；配了组件走显式 Intent，否则按包名拉起
  Future<void> openFocusedApp() async {
    if (apps.isEmpty) return;
    final app = apps[focusedIndex.value];
    final component = app.launchComponent;
    if (component != null && component.isNotEmpty) {
      await PlatformService.launchIntent(
        action: app.launchAction,
        component: component,
        intExtras: app.launchIntExtras,
      );
      return;
    }
    final packageName = app.packageName;
    if (packageName == null || packageName.isEmpty) return;
    await PlatformService.launchApp(packageName);
  }

  /// 调度到下一个整分钟再刷新，保证跳分时立即更新
  void _scheduleNextTick() {
    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    _timer = Timer(nextMinute.difference(now), () {
      _updateClock();
      _scheduleNextTick();
    });
  }

  /// 读取当前时间并格式化，仅值变化时触发刷新
  void _updateClock() {
    final now = DateTime.now();
    time.value =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    date.value = '${now.year}年${now.month}月${now.day}日';
    weekday.value = _weekdays[now.weekday - 1];
  }

  /// 启动背景轮换：先随机选一张，之后每 30 分钟换一次
  Future<void> _startBackgroundRotation() async {
    _backgroundImages = await _loadBackgroundImages();
    if (_backgroundImages.isEmpty) return;
    _rotateBackground();
    _backgroundTimer = Timer.periodic(
      _backgroundInterval,
      (_) => _rotateBackground(),
    );
  }

  /// 手动换一张背景（遥控器后退键触发），不重置 30 分钟定时器
  void refreshBackground() => _rotateBackground();

  /// 从打包清单读取 images 目录下的图片路径，排除卡片贴图
  /// 新版 Flutter 不再生成 AssetManifest.json，必须用官方 API 读清单
  Future<List<String>> _loadBackgroundImages() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest.listAssets()
        .where((path) => path.startsWith(_imageDir))
        .where(
          (path) => !path
              .substring(_imageDir.length)
              .startsWith(_cardImagePrefix),
        )
        .toList();
  }

  /// 随机挑一张作为背景；只有一张时不重复赋值，避免无意义重建
  void _rotateBackground() {
    final images = _backgroundImages;
    if (images.isEmpty) return;
    if (images.length == 1) {
      if (backgroundImage.value != images.first) {
        backgroundImage.value = images.first;
      }
      return;
    }
    // 避开当前这张，保证每次轮换视觉上确实变化
    final candidates = images.where((p) => p != backgroundImage.value).toList();
    backgroundImage.value = candidates[_random.nextInt(candidates.length)];
  }

  @override
  void onClose() {
    _timer?.cancel();
    _backgroundTimer?.cancel();
    super.onClose();
  }

  /// 初始化桌面 App；后续从原生层读取安装列表时替换这里
  void _initApps() {
    apps.addAll(const [
      // 哔哩哔哩：品牌色 #FF6182 做底色，配一张本地插画贴图
      AppInfo(
        name: '哔哩哔哩',
        textColor: Color(0xFFFF6182),
        packageName: 'com.xiaodianshi.tv.yst',
        backgroundColor: Color(0xFFFF6182),
        imageAsset: 'assets/images/card_1.jpg',
      ),
      // 飞牛：品牌蓝底色 + 品牌蓝文字，配一张本地插画贴图
      AppInfo(
        name: '飞牛',
        packageName: 'com.trim.tv',
        textColor: Color(0xFF2D78F9),
        backgroundColor: Color(0xFF2D78F9),
        imageAsset: 'assets/images/card_2.jpg',
      ),
      // PC：小米播放器无标准 LAUNCHER 入口，用显式 Intent 直接切到 HDMI3
      AppInfo(
        name: '电脑',
        packageName: 'com.xiaomi.mitv.tvplayer',
        textColor: Color.fromARGB(255, 2, 176, 219),
        imageAsset: 'assets/images/card_3.jpg',
        launchAction: 'com.xiaomi.mitv.tvplayer.EXTSRC_PLAY',
        launchComponent: 'com.xiaomi.mitv.tvplayer/.ExternalSourceActivity',
        launchIntExtras: {'input': 25},
      ),
      // 月光：Moonlight Android 版包名，主 Activity 带 LEANBACK_LAUNCHER，电视可直接拉起
      AppInfo(
        name: '月光',
        packageName: 'com.limelight',
        textColor: Colors.grey,
        imageAsset: 'assets/images/card_4.jpg',
      ),
    ]);
  }
}
