import 'package:get/get.dart';

import 'package:dlauncher/models/app_info.dart';
import 'package:dlauncher/models/installed_app.dart';
import 'package:dlauncher/services/app_config_service.dart';
import 'package:dlauncher/services/platform_service.dart';

/// 设置页状态：维护一份配置副本，每次变更即时落盘。
class SettingsController extends GetxController {
  /// 编辑中的配置副本，变更即写回本地配置
  final apps = <AppInfo>[].obs;

  /// 列表当前焦点索引
  final focusedIndex = 0.obs;

  /// 已安装应用，进入包名选择时按需加载
  final installedApps = <InstalledApp>[].obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    apps.assignAll(await AppConfigService.loadApps());
  }

  /// 配置变更即时落盘：返回键交给系统路由处理，不能依赖「离开页面时保存」
  void _persist() => AppConfigService.saveApps(apps);

  /// 新增一张空白卡片，数量不限
  void addApp() {
    apps.add(const AppInfo(name: '新应用'));
    focusedIndex.value = apps.length - 1;
    _persist();
  }

  /// 删除当前焦点卡片；焦点在「新增」项时忽略
  void deleteFocused() => deleteAt(focusedIndex.value);

  /// 删除指定索引的卡片，供编辑页的删除入口调用
  void deleteAt(int index) {
    if (index < 0 || index >= apps.length) return;
    apps.removeAt(index);
    if (focusedIndex.value >= apps.length) {
      focusedIndex.value = apps.isEmpty ? 0 : apps.length - 1;
    }
    _persist();
  }

  /// 用编辑结果替换指定位置的卡片
  void updateApp(int index, AppInfo app) {
    if (index < 0 || index >= apps.length) return;
    apps[index] = app;
    _persist();
  }

  /// 加载可拉起的应用列表，供包名点选
  Future<void> loadInstalledApps() async {
    if (installedApps.isNotEmpty) return;
    installedApps.assignAll(await PlatformService.getInstalledApps());
  }

  /// 恢复默认配置并立即生效
  Future<void> resetToDefault() async {
    await AppConfigService.resetToDefault();
    apps.assignAll(await AppConfigService.loadApps());
    focusedIndex.value = 0;
  }
}
