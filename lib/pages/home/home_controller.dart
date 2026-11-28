import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/app/route_names.dart';
import 'package:dlauncher/models/app_info.dart';
import 'package:dlauncher/services/app_config_service.dart';
import 'package:dlauncher/services/background_service.dart';
import 'package:dlauncher/services/platform_service.dart';
import 'package:dlauncher/services/weather_service.dart';

/// 首页状态：实时时钟 + 桌面 App 列表。
class HomeController extends GetxController with WidgetsBindingObserver {
  Timer? _timer;

  /// 缓存上次显示的时间，只有分钟变化才写 obs，避免无关重建
  String _lastTime = '';

  /// 时间，如 15:18
  final time = ''.obs;

  /// 日期，如 2026年11月27日
  final date = ''.obs;

  /// 星期，如 星期五
  final weekday = ''.obs;

  /// 天气摘要，如「成都 晴 最高17° AQI59」；启动拉取一次，失败保留占位文案
  final weatherText = ''.obs;

  /// 桌面卡片对应的 App 列表，数量不限
  final apps = <AppInfo>[].obs;

  /// 当前获得焦点的卡片索引，遥控器左右键切换
  final focusedIndex = 0.obs;

  /// 首页背景图路径，定时从 images 目录随机切换
  final backgroundImage = ''.obs;

  static const _weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];

  /// 首页固定展示的卡片数量，焦点走到第 5 张时窗口整体左移一张
  static const visibleCardCount = 4;

  /// 时钟检查间隔：30 秒足够，回前台会另行立即校正
  static const _clockInterval = Duration(seconds: 30);
  static const _backgroundInterval = Duration(minutes: 30);

  Timer? _backgroundTimer;

  /// 背景候选图，供定时轮换与手动刷新共用
  List<String> _backgroundImages = const [];
  final _random = Random();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _updateClock();
    // 周期性检查而非单次对齐：App 退到后台时 Timer 会被冻结，
    // 单次定时器错过触发点后回前台会一次性跳到当前时间；周期检查回前台即自动校正
    // 间隔 30 秒即可，跳分最多延迟半分钟，换取更少的定时唤醒
    _timer = Timer.periodic(_clockInterval, (_) => _updateClock());
    _loadApps();
    _startBackgroundRotation();
    // 天气只在启动时拉一次，不随后台轮换或时钟刷新
    _loadWeather();
  }

  /// 启动时拉取一次天气，失败则保留页面上的占位文字
  Future<void> _loadWeather() async {
    final info = await WeatherService.fetch();
    if (info != null) weatherText.value = info.toString();
  }

  /// 从后台回到前台立即校正，避免等下一次周期检查才刷新
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _updateClock();
  }

  /// 遥控器左右移动焦点：到头不循环，停在当前端
  void moveFocus(int delta) {
    final next = focusedIndex.value + delta;
    if (next < 0 || next >= apps.length) return;
    focusedIndex.value = next;
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

  /// 读取当前时间并格式化，只有显示值变化时才写 obs，避免每次检查都无意义重建
  void _updateClock() {
    final now = DateTime.now();
    final nextTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    if (nextTime == _lastTime) return;
    _lastTime = nextTime;
    time.value = nextTime;
    date.value = '${now.year}年${now.month}月${now.day}日';
    weekday.value = _weekdays[now.weekday - 1];
  }

  /// 按设置加载背景：固定模式直接用设定图，不轮换；
  /// 服务器模式缓存优先立即显示，再异步拉配置覆盖，都拿不到才用本地图兜底。
  Future<void> _startBackgroundRotation() async {
    if (BackgroundService.mode == BackgroundMode.fixed) {
      final fixed = BackgroundService.fixedImage;
      if (fixed.isNotEmpty) {
        _backgroundTimer?.cancel();
        _backgroundTimer = null;
        _backgroundImages = [fixed];
        backgroundImage.value = fixed;
        return;
      }
    }

    final cached = BackgroundService.cachedImages;
    if (cached.isNotEmpty) _applyBackgrounds(cached);

    final remote = await BackgroundService.fetchImages();
    if (remote != null && remote.isNotEmpty) {
      await BackgroundService.saveImages(remote);
      _applyBackgrounds(remote);
    } else if (cached.isEmpty) {
      _applyBackgrounds(await BackgroundService.loadLocalImages());
    }
  }

  /// 应用一组背景并启动轮换；定时器只建一次，列表变化才重选图片。
  void _applyBackgrounds(List<String> images) {
    if (images.isEmpty) return;
    final changed = images.length != _backgroundImages.length ||
        images.asMap().entries.any(
              (entry) => entry.value != _backgroundImages[entry.key],
            );
    _backgroundImages = images;
    if (changed) _rotateBackground();
    _backgroundTimer ??= Timer.periodic(
      _backgroundInterval,
      (_) => _rotateBackground(),
    );
  }

  /// 手动换一张背景（遥控器后退键触发），不重置 30 分钟定时器
  void refreshBackground() => _rotateBackground();

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
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _backgroundTimer?.cancel();
    super.onClose();
  }

  /// 上键：打开桌面设置页，返回后刷新卡片与背景
  void openSettingsPage() {
    Get.toNamed(RouteNames.settings)?.then((_) {
      reloadApps();
      _startBackgroundRotation();
    });
  }

  /// 从本地配置加载全部卡片；设置页保存后也走这里刷新
  Future<void> _loadApps() async {
    apps.assignAll(await AppConfigService.loadApps());
    // 配置数量变化后焦点可能越界，夹回合法范围
    if (focusedIndex.value >= apps.length) {
      focusedIndex.value = apps.isEmpty ? 0 : apps.length - 1;
    }
  }

  /// 设置页保存后调用，重新读取配置刷新首页卡片
  Future<void> reloadApps() => _loadApps();
}
