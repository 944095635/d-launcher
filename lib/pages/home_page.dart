import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/home_controller.dart';

/// 桌面首页。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 控制器由路由 binding 注册，这里只取用
    final controller = Get.find<HomeController>();

    return Scaffold(
      body: Center(
        child: Obx(() => Text('DLauncher · ${controller.greeting.value}')),
      ),
    );
  }
}
