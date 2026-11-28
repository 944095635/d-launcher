import 'package:get/get.dart';

import 'package:dlauncher/app/route_names.dart';
import 'package:dlauncher/pages/home/home_controller.dart';
import 'package:dlauncher/pages/home/home_page.dart';
import 'package:dlauncher/pages/settings/apps/settings_controller.dart';
import 'package:dlauncher/pages/settings/apps/settings_page.dart';
import 'package:dlauncher/pages/settings/background/background_settings_page.dart';
import 'package:dlauncher/pages/settings/settings_menu_page.dart';

/// 首页依赖绑定：控制器随路由注册，生命周期由 GetX 管理。
class HomeBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.lazyPut<HomeController>(() => HomeController()),
    ];
  }
}

/// 设置页依赖绑定
class SettingsBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.lazyPut<SettingsController>(() => SettingsController()),
    ];
  }
}

/// 路由集中管理：新增页面只需在这里登记。
class AppRoutes {
  /// 首页路由名
  static const home = RouteNames.home;

  /// 设置一级菜单路由名
  static const settings = RouteNames.settings;

  /// 背景设置路由名
  static const settingsBackground = RouteNames.settingsBackground;

  /// App 设置路由名
  static const settingsApps = RouteNames.settingsApps;

  /// 路由表
  static final pages = [
    GetPage(
      name: home,
       transition: .fadeIn,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: settings,
      page: () => const SettingsMenuPage(),
    ),
    GetPage(
      name: settingsBackground,
      page: () => const BackgroundSettingsPage(),
    ),
    GetPage(
      name: settingsApps,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
    ),
  ];
}
