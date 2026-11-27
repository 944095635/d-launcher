import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../pages/home_page.dart';

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
  /// 首页路由名
  static const home = '/';

  /// 路由表
  static final pages = [
    GetPage(
      name: home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
  ];
}
