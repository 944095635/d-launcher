import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/pages/settings/local_image_picker_page.dart';
import 'package:dlauncher/pages/settings/text_input_dialog.dart';
import 'package:dlauncher/services/background_service.dart';
import 'package:dlauncher/widgets/focus_scroll_helper.dart';

/// 固定背景来源：从本地打包图片点选，或手动输入图片地址（asset 路径 / URL）。
class FixedBackgroundPage extends StatefulWidget {
  const FixedBackgroundPage({super.key});

  @override
  State<FixedBackgroundPage> createState() => _FixedBackgroundPageState();
}

class _FixedBackgroundPageState extends State<FixedBackgroundPage> {
  static const _items = ['选择本地图片', '输入图片地址'];

  int _focused = 0;

  /// 单项约 72 高，焦点移出视野时用于定位
  late final _scroll = FocusScrollHelper(estimatedItemHeight: 72);

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
        title: const Text('固定设置'),
        backgroundColor: const Color(0xFF242424),
      ),
      // 返回键不在此处理：GetX 路由会自行弹栈，重复调用 Get.back 会退两层
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: ListView.builder(
          controller: _scroll.controller,
          padding: const EdgeInsets.symmetric(vertical: 20),
          itemCount: _items.length,
          itemBuilder: (context, index) => _buildItem(index),
        ),
      ),
    );
  }

  Widget _buildItem(int index) {
    final selected = _focused == index;
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
            index == 0 ? Icons.photo_library : Icons.link,
            color: selected ? Colors.amber : Colors.white54,
            size: 28,
          ),
          Expanded(
            child: Text(
              _items[index],
              style: const TextStyle(color: Colors.white, fontSize: 22),
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
        _confirm();
        return KeyEventResult.handled;
      default:
        // 返回键交回系统，由 GetX 路由弹栈
        return KeyEventResult.ignored;
    }
  }

  Future<void> _confirm() async {
    if (_focused == 0) {
      final picked = await Get.to<String>(() => const LocalImagePickerPage());
      if (picked != null) await _apply(picked);
      return;
    }
    await _inputUrl();
  }

  /// 输入框填地址，电视上可外接键盘或用软键盘
  Future<void> _inputUrl() async {
    // 控制器交给弹窗自身管理：Get.dialog 的 Future 在 pop 瞬间就返回，
    // 此处立即 dispose 会让仍在淡出动画中的 TextField 访问已释放的控制器而报错。
    final value = await Get.dialog<String>(
      TextInputDialog(
        title: '输入图片地址',
        hint: 'http://... 或 assets/images/...',
        initial: BackgroundService.fixedImage,
      ),
      barrierDismissible: false,
    );
    if (value != null && value.isNotEmpty) await _apply(value);
  }

  /// 保存固定图并切到固定模式，返回上级页
  Future<void> _apply(String image) async {
    await BackgroundService.saveFixedImage(image);
    await BackgroundService.saveMode(BackgroundMode.fixed);
    Get.back(result: true);
  }
}
