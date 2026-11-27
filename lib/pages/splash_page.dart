import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../app/routes.dart';
import '../services/launch_service.dart';

/// 启动屏幕：仅首次启动展示，短暂展示后进入首页。
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _enterHome();
  }

  /// 先记录启动状态，再延时进入首页；用 offNamed 避免返回键退回启动屏
  Future<void> _enterHome() async {
    await LaunchService.markLaunched();
    await Future.delayed(const Duration(seconds: 12));
    Get.offNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('DLauncher')),
    );
  }
}
