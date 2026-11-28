import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/pages/settings/fixed_background_page.dart';
import 'package:dlauncher/services/background_service.dart';

/// 背景设置页：固定一张（本地/地址）或从服务器清单随机展示。
class BackgroundSettingsPage extends StatefulWidget {
  const BackgroundSettingsPage({super.key});

  @override
  State<BackgroundSettingsPage> createState() => _BackgroundSettingsPageState();
}

class _BackgroundSettingsPageState extends State<BackgroundSettingsPage> {
  static const _items = ['固定设置', '从服务器获取（随机展示）'];

  late BackgroundMode _mode;
  String _fixedImage = '';
  int _focused = 0;

  @override
  void initState() {
    super.initState();
    _syncFromPrefs();
  }

  /// 每次进入或子页返回都重新读取当前配置
  void _syncFromPrefs() {
    _mode = BackgroundService.mode;
    _fixedImage = BackgroundService.fixedImage;
    _focused = _mode == BackgroundMode.fixed ? 0 : 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('背景设置'),
        backgroundColor: const Color(0xFF242424),
      ),
      // 返回键不在此处理：GetX 路由会自行弹栈，重复调用 Get.back 会退两层
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: _items.length,
          itemBuilder: (context, index) => _buildItem(index),
        ),
      ),
    );
  }

  Widget _buildItem(int index) {
    final selected = _focused == index;
    final active = index == 0
        ? _mode == BackgroundMode.fixed
        : _mode == BackgroundMode.server;
    final subtitle = index == 0
        ? (_fixedImage.isEmpty ? '未设置图片' : _fixedImage)
        : '随机展示服务器图片清单';
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
            active ? Icons.check_circle : Icons.radio_button_unchecked,
            color: active ? Colors.amber : Colors.white54,
            size: 28,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  _items[index],
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        if (_focused > 0) setState(() => _focused--);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (_focused < _items.length - 1) setState(() => _focused++);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        _confirm();
        return KeyEventResult.handled;
      default:
        // 返回键交回系统，由 GetX 路由弹栈
        return KeyEventResult.ignored;
    }
  }

  Future<void> _confirm() async {
    if (_focused == 0) {
      // 固定设置还需再选来源，进入子页；返回后重新读取配置刷新勾选状态
      await Get.to(() => const FixedBackgroundPage());
      if (!mounted) return;
      setState(_syncFromPrefs);
      return;
    }
    await BackgroundService.saveMode(BackgroundMode.server);
    if (!mounted) return;
    setState(_syncFromPrefs);
    // 切到服务器模式后返回菜单，最终回首页时按新模式重新加载背景
    Get.back(result: true);
  }
}
