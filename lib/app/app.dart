import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'routes.dart';

/// 应用根组件：统一配置主题与初始路由。
class App extends StatelessWidget {
  /// 首帧路由由启动状态预先决定，避免先渲染首页再跳转的闪屏
  final String initialRoute;

  const App({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DLauncher',
      debugShowCheckedModeBanner: false,
      themeMode: .dark,
      darkTheme: ThemeData(
        // 全局默认字体；时钟等显式指定 fontFamily 的文字不受影响
        fontFamily: 'ZCOOLQingKeHuangYou',
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: initialRoute,
      getPages: AppRoutes.pages,
    );
  }
}
