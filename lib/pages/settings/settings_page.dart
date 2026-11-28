import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/pages/settings/card_edit_page.dart';
import 'package:dlauncher/pages/settings/settings_controller.dart';
import 'package:dlauncher/widgets/focus_scroll_helper.dart';

/// 桌面设置页：遥控器上下选卡片，确认键进编辑页（可改可删），配置即时保存。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// 保留原有 controller 访问方式，避免改动下方业务代码
  SettingsController get controller => Get.find<SettingsController>();

  /// 单项约 88 高（含副标题），焦点移出视野时用于定位
  late final _scroll = FocusScrollHelper(estimatedItemHeight: 88);

  /// 恢复初始是破坏性操作，首次按确认键只武装，再按一次才执行
  bool _resetArmed = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

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
          // 末尾固定两项：新增卡片、恢复初始
          final addIndex = controller.apps.length;
          return ListView.builder(
            controller: _scroll.controller,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: addIndex + 2,
            itemBuilder: (context, index) {
              if (index < addIndex) return _buildAppItem(index, focused);
              if (index == addIndex) return _buildAddItem(focused);
              return _buildResetItem(focused);
            },
          );
        }),
      ),
    );
  }

  Widget _buildAppItem(int index, int focused) {
    final app = controller.apps[index];
    final selected = focused == index;
    return AnimatedContainer(
      key: _scroll.keyOf(index),
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
          // 明确写出编辑页里有删除能力，避免菜单键是唯一入口却无从发现
          if (selected) ...[
            const Text(
              '编辑 / 删除',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Icon(Icons.chevron_right, color: Colors.amber, size: 26),
          ],
        ],
      ),
    );
  }

  Widget _buildAddItem(int focused) {
    final selected = focused == controller.apps.length;
    return AnimatedContainer(
      key: _scroll.keyOf(controller.apps.length),
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

  Widget _buildResetItem(int focused) {
    final index = controller.apps.length + 1;
    final selected = focused == index;
    return AnimatedContainer(
      key: _scroll.keyOf(index),
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
            Icons.restore,
            color: selected ? Colors.amber : Colors.white54,
            size: 28,
          ),
          Expanded(
            child: Text(
              _resetArmed ? '再按一次确认恢复初始' : '恢复初始配置',
              style: TextStyle(
                color: _resetArmed && selected ? Colors.orangeAccent : Colors.white70,
                fontSize: 22,
              ),
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
        _scroll.ensureVisible(controller.focusedIndex.value);
        return KeyEventResult.handled;
      default:
        // 返回键交回系统，由 GetX 路由弹栈；配置已即时保存
        return KeyEventResult.ignored;
    }
  }

  /// 焦点范围覆盖卡片、新增、恢复三项，到头循环；离开恢复项撤销武装
  void _moveFocus(int delta) {
    final count = controller.apps.length + 2;
    final next = (controller.focusedIndex.value + delta + count) % count;
    controller.focusedIndex.value = next;
    _resetArmed = false;
    setState(() {});
    _scroll.ensureVisible(next);
  }

  Future<void> _confirm() async {
    final index = controller.focusedIndex.value;
    if (index == controller.apps.length) {
      // 新增项：卡片追加到末尾，焦点跟着落到新增项，滚到底部保证可见
      controller.addApp();
      _scroll.ensureVisible(controller.apps.length);
      return;
    }
    if (index > controller.apps.length) {
      // 恢复项：二次确认后清本地缓存、重读 apps.json
      if (!_resetArmed) {
        setState(() => _resetArmed = true);
        return;
      }
      await controller.resetToDefault();
      _resetArmed = false;
      setState(() {});
      _scroll.ensureVisible(0);
      return;
    }
    await Get.to(() => CardEditPage(index: index));
    // 编辑页返回后列表已由 controller 更新，Obx 自动重建
  }
}
