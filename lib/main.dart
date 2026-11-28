import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/app/app.dart';
import 'package:dlauncher/services/prefs_service.dart';

/// 应用入口：预热本地存储后直接进入首页。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefsService.init();
  runApp(const App());
}
