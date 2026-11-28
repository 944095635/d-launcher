import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// 通用文本输入弹窗：控制器由弹窗自持，卸载时才释放。
/// Get.dialog 的 Future 在 pop 瞬间返回，若外层立即 dispose 控制器，
/// 仍在淡出动画中的 TextField 会访问已释放对象而报错。
class TextInputDialog extends StatefulWidget {
  const TextInputDialog({
    super.key,
    required this.title,
    required this.hint,
    this.initial = '',
  });

  final String title;
  final String hint;
  final String initial;

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late final TextEditingController _controller;

  // 三个控件各持显式焦点节点，遥控器才能在输入框与两个按钮之间切换
  final _fieldFocus = FocusNode();
  final _cancelFocus = FocusNode();
  final _okFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _fieldFocus.dispose();
    _cancelFocus.dispose();
    _okFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// 输入框内的遥控器按键：只负责把焦点从输入框挪走。
  /// 确认键不提交内容——保存只由「确定」按钮自己被确认时触发。
  KeyEventResult _onFieldKey(FocusNode node, KeyEvent event) {
    if (!_fieldFocus.hasFocus) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.arrowRight:
        // 焦点先落到「取消」：用户需自己用左右键移到「确定」再确认，
        // 避免按一次确认就误保存
        _fieldFocus.unfocus();
        _cancelFocus.requestFocus();
        return KeyEventResult.handled;
      default:
        // 文字输入、上下/左右微调光标等交回输入框自身处理
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF242424),
      title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      content: Focus(
        onKeyEvent: _onFieldKey,
        child: TextField(
          controller: _controller,
          focusNode: _fieldFocus,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: widget.hint),
        ),
      ),
      actions: [
        TextButton(
          focusNode: _cancelFocus,
          onPressed: () => Get.back(),
          child: const Text('取消'),
        ),
        TextButton(
          focusNode: _okFocus,
          onPressed: () => Get.back(result: _controller.text.trim()),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
