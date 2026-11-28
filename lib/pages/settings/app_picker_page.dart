import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/models/installed_app.dart';
import 'package:dlauncher/pages/settings/settings_controller.dart';

/// 包名点选页：列出可拉起的应用，遥控器上下选择、确认键回填。
class AppPickerPage extends StatefulWidget {
  const AppPickerPage({super.key});

  @override
  State<AppPickerPage> createState() => _AppPickerPageState();
}

class _AppPickerPageState extends State<AppPickerPage> {
  int _focused = 0;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('选择应用'),
        backgroundColor: const Color(0xFF242424),
      ),
      // 返回键不在此处理：GetX 路由会自行弹栈，重复调用 Get.back 会退两层
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) => _onKeyEvent(node, event, controller),
        child: Obx(() {
          if (controller.installedApps.isEmpty) {
            return const Center(
              child: Text(
                '未找到可拉起的应用',
                style: TextStyle(color: Colors.white70, fontSize: 24),
              ),
            );
          }
          return ListView.builder(
            itemCount: controller.installedApps.length,
            itemBuilder: (context, index) {
              final app = controller.installedApps[index];
              final selected = _focused == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF3A3A3A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  spacing: 20,
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected ? Colors.amber : Colors.white54,
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
                            app.packageName,
                            style: const TextStyle(color: Colors.white54, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }

  KeyEventResult _onKeyEvent(
    FocusNode node,
    KeyEvent event,
    SettingsController controller,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        if (_focused > 0) setState(() => _focused--);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (_focused < controller.installedApps.length - 1) {
          setState(() => _focused++);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        if (controller.installedApps.isNotEmpty) {
          Get.back<InstalledApp>(
            result: controller.installedApps[_focused],
          );
        }
        return KeyEventResult.handled;
      default:
        // 返回键交回系统，由 GetX 路由弹栈
        return KeyEventResult.ignored;
    }
  }
}
