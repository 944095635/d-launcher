import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/services/background_service.dart';
import 'package:dlauncher/widgets/focus_scroll_helper.dart';

/// 本地背景图点选页：列出打包图片，遥控器上下选择、确认键回填地址。
class LocalImagePickerPage extends StatefulWidget {
  const LocalImagePickerPage({super.key});

  @override
  State<LocalImagePickerPage> createState() => _LocalImagePickerPageState();
}

class _LocalImagePickerPageState extends State<LocalImagePickerPage> {
  final _images = <String>[].obs;
  int _focused = 0;

  /// 单项约 60 高，焦点移出视野时用于定位
  late final _scroll = FocusScrollHelper(estimatedItemHeight: 60);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _images.assignAll(await BackgroundService.loadLocalImages());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('选择本地图片'),
        backgroundColor: const Color(0xFF242424),
      ),
      // 返回键不在此处理：GetX 路由会自行弹栈，重复调用 Get.back 会退两层
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Obx(() {
          if (_images.isEmpty) {
            return const Center(
              child: Text(
                '未找到本地背景图（assets/images 下排除 card_ 的图片）',
                textAlign: .center,
                style: TextStyle(color: Colors.white70, fontSize: 20),
              ),
            );
          }
          // 留白放在视口外的 Padding 里，滚动时顶部始终保留 20，不随内容滚走
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ListView.builder(
              controller: _scroll.controller,
              itemCount: _images.length,
              itemBuilder: (context, index) {
                final selected = _focused == index;
                return AnimatedContainer(
                  key: _scroll.keyOf(index),
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
                        child: Text(
                          _images[index].split('/').last,
                          style: const TextStyle(color: Colors.white, fontSize: 22),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
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
        if (_focused < _images.length - 1) {
          setState(() => _focused++);
          _scroll.ensureVisible(_focused);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        if (_images.isNotEmpty) Get.back<String>(result: _images[_focused]);
        return KeyEventResult.handled;
      default:
        // 返回键交回系统，由 GetX 路由弹栈
        return KeyEventResult.ignored;
    }
  }
}
