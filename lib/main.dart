import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/app/app.dart';
import 'package:dlauncher/app/routes.dart';
import 'package:dlauncher/services/prefs_service.dart';

/// 应用入口：先预热本地存储，首帧直接落在启动页或首页，避免闪屏。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefsService.init();
  final initialRoute =
      PrefsService.isFirstLaunch ? AppRoutes.splash : AppRoutes.home;
  runApp(App(initialRoute: initialRoute));
}
