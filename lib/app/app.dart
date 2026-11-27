import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'routes.dart';

/// 应用根组件：统一配置主题与初始路由。
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DLauncher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      initialRoute: AppRoutes.home,
      getPages: AppRoutes.pages,
    );
  }
}
