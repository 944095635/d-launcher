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
    // 每秒刷新，只更新显示文本，由 Obx 局部重建
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
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
