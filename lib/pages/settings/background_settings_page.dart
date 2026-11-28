import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/pages/settings/background_gallery_page.dart';
import 'package:dlauncher/services/background_service.dart';
import 'package:dlauncher/widgets/focus_scroll_helper.dart';

/// 背景设置页：随机展示服务器图片，或固定展示一张（也可选择不使用背景）。
class BackgroundSettingsPage extends StatefulWidget {
  const BackgroundSettingsPage({super.key});

  @override
  State<BackgroundSettingsPage> createState() => _BackgroundSettingsPageState();
}

class _BackgroundSettingsPageState extends State<BackgroundSettingsPage> {
  static const _items = ['随机展示', '固定展示'];

  late BackgroundMode _mode;
  String _fixedImage = '';
  int _focused = 0;

  /// 单项约 88 高（含副标题），焦点移出视野时用于定位
  late final _scroll = FocusScrollHelper(estimatedItemHeight: 88);

  @override
  void initState() {
    super.initState();
    _syncFromPrefs();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// 每次进入或子页返回都重新读取当前配置
  void _syncFromPrefs() {
    _mode = BackgroundService.mode;
    _fixedImage = BackgroundService.fixedImage;
    _focused = _mode == BackgroundMode.server ? 0 : 1;
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
        // 留白放在视口外的 Padding 里，滚动时顶部始终保留 20，不随内容滚走
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ListView.builder(
            controller: _scroll.controller,
            itemCount: _items.length,
            itemBuilder: (context, index) => _buildItem(index),
          ),
        ),
      ),
    );
  }

  String _subtitleOf(int index) {
    if (index == 0) return '随机展示服务器图片清单';
    if (_mode == BackgroundMode.none) return '不使用背景';
    // 图片地址通常是长 URL，菜单里只提示是否已选，避免挤占整行
    return _fixedImage.isEmpty ? '未设置图片' : '已选择';
  }

  Widget _buildItem(int index) {
    final selected = _focused == index;
    final active = index == 0
        ? _mode == BackgroundMode.server
        : _mode != BackgroundMode.server;
    return GestureDetector(
      // 电视遥控器之外，鼠标/触摸点整行也能进入对应设置
      onTap: () => _confirmAt(index),
      child: AnimatedContainer(
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
                    _subtitleOf(index),
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
      ),
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        if (_focused > 0) {
          setState(() => _focused--);
          _scroll.ensureVisible(_focused);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (_focused < _items.length - 1) {
          setState(() => _focused++);
          _scroll.ensureVisible(_focused);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        _confirmAt(_focused);
        return KeyEventResult.handled;
      default:
        // 返回键交回系统，由 GetX 路由弹栈
        return KeyEventResult.ignored;
    }
  }

  Future<void> _confirmAt(int index) async {
    if (index == 0) {
      await BackgroundService.saveMode(BackgroundMode.server);
    } else {
      final picked = await Get.to<String>(
        () => BackgroundGalleryPage(initialImage: _fixedImage),
      );
      // 取消选择：返回 null，不改任何配置
      if (picked == null) return;
      await BackgroundService.saveFixedImage(picked);
      await BackgroundService.saveMode(
        picked.isEmpty ? BackgroundMode.none : BackgroundMode.fixed,
      );
    }
    if (!mounted) return;
    setState(_syncFromPrefs);
  }
}
