import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'app/routes.dart';
import 'services/launch_service.dart';

/// 应用入口：先完成启动状态判断，让首帧直接落在目标页面，避免闪屏。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 预热本地存储，后续读取走内存缓存
  await LaunchService.init();
  // 首帧直接落在启动屏或首页，跳过中间跳转
  final initialRoute =
      LaunchService.isFirstLaunch ? AppRoutes.splash : AppRoutes.home;
  runApp(App(initialRoute: initialRoute));
}
