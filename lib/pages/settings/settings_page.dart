import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/pages/settings/card_edit_page.dart';
import 'package:dlauncher/pages/settings/settings_controller.dart';

/// 桌面设置页：遥控器上下选卡片，确认键编辑，菜单键删除，配置即时保存。
class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('App 设置'),
        backgroundColor: const Color(0xFF242424),
      ),
      // 返回键不在此处理：GetX 路由会自行弹栈，重复调用 Get.back 会退两层
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Obx(() {
          // focusedIndex 若只在 itemBuilder 内部读取，会脱离 Obx 追踪范围，
          // 导致上下键改了焦点却不触发列表重建；这里先读一次建立依赖。
          final focused = controller.focusedIndex.value;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: controller.apps.length + 1,
            itemBuilder: (context, index) =>
                index < controller.apps.length
                    ? _buildAppItem(index, focused)
                    : _buildAddItem(focused),
          );
        }),
      ),
    );
  }

  Widget _buildAppItem(int index, int focused) {
    final app = controller.apps[index];
    final selected = focused == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF3A3A3A) : const Color(0xFF242424),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        spacing: 20,
        children: [
          Icon(
            Icons.smart_display,
            color: selected ? Colors.amber : Colors.white54,
            size: 28,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  app.name,
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                ),
                Text(
                  app.packageName ?? '（未设置包名）',
                  style: const TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.chevron_right, color: Colors.amber, size: 26),
        ],
      ),
    );
  }

  Widget _buildAddItem(int focused) {
    final selected = focused >= controller.apps.length;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF3A3A3A) : const Color(0xFF242424),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        spacing: 20,
        children: [
          Icon(Icons.add, color: selected ? Colors.amber : Colors.white54, size: 28),
          Text(
            '新增卡片',
            style: TextStyle(
              color: selected ? Colors.amber : Colors.white70,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _moveFocus(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _moveFocus(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        _confirm();
        return KeyEventResult.handled;
      // 设置页内菜单键改作删除卡片，长按入口只在首页生效
      case LogicalKeyboardKey.contextMenu:
        controller.deleteFocused();
        return KeyEventResult.handled;
      default:
        // 返回键交回系统，由 GetX 路由弹栈；配置已即时保存
        return KeyEventResult.ignored;
    }
  }

  /// 焦点范围含末尾的「新增」项，到头循环
  void _moveFocus(int delta) {
    final count = controller.apps.length + 1;
    controller.focusedIndex.value =
        (controller.focusedIndex.value + delta + count) % count;
  }

  Future<void> _confirm() async {
    final index = controller.focusedIndex.value;
    if (index >= controller.apps.length) {
      controller.addApp();
      return;
    }
    await Get.to(() => CardEditPage(index: index));
    // 编辑页返回后列表已由 controller 更新，Obx 自动重建
  }
}
