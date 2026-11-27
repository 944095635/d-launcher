import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/app/routes.dart';

/// 应用根组件：统一配置主题与首页路由。
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DLauncher',
      debugShowCheckedModeBanner: false,
      themeMode: .dark,
      darkTheme: ThemeData(
        fontFamily: 'ZCOOLQingKeHuangYou',
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: AppRoutes.home,
      getPages: AppRoutes.pages,
    );
  }
}
