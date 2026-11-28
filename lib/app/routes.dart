import 'package:get/get.dart';

import 'package:dlauncher/pages/home_controller.dart';
import 'package:dlauncher/pages/home_page.dart';
import 'package:dlauncher/pages/splash_page.dart';

/// 首页依赖绑定：控制器随路由注册，生命周期由 GetX 管理。
class HomeBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.lazyPut<HomeController>(() => HomeController()),
    ];
  }
}

/// 路由集中管理：新增页面只需在这里登记。
class AppRoutes {
  /// 启动屏幕路由名
  static const splash = '/splash';

  /// 首页路由名
  static const home = '/';

  /// 路由表
  static final pages = [
    GetPage(
      name: splash,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
  ];
}
