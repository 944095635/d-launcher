import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/app/routes.dart';
import 'package:dlauncher/services/prefs_service.dart';

/// 启动屏幕：仅首次启动展示，停留片刻后进入首页。
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  /// 停留时长，给电视系统服务留出就绪时间
  static const _duration = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _enterHome();
  }

  /// 先写入启动标记，再延时进首页；offNamed 避免返回键退回启动页
  Future<void> _enterHome() async {
    await PrefsService.markLaunched();
    await Future.delayed(_duration);
    Get.offNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('DLauncher')),
    );
  }
}
