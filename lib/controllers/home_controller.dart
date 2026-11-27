import 'dart:async';

import 'package:get/get.dart';

/// 首页状态：实时时钟。
class HomeController extends GetxController {
  Timer? _timer;

  /// 时间，如 15:18
  final time = ''.obs;

  /// 日期，如 2026年11月27日
  final date = ''.obs;

  /// 星期，如 星期五
  final weekday = ''.obs;

  static const _weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];

  @override
  void onInit() {
    super.onInit();
    _updateClock();
    // 只显示到分钟，对齐到下一分钟边界刷新，避免无意义的每秒重建
    _scheduleNextTick();
  }

  /// 调度到下一个整分钟再刷新，保证跳分时立即更新
  void _scheduleNextTick() {
    final now = DateTime.now();
    final nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
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

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
