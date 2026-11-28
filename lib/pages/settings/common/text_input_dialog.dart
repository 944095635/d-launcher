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

  /// 输入框：确认/下/右把焦点交给「取消」，不提交内容——
  /// 保存只由「确定」按钮自己被确认时触发。
  KeyEventResult _onFieldKey(FocusNode node, KeyEvent event) {
    if (!_fieldFocus.hasFocus) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.arrowRight:
        _cancelFocus.requestFocus();
        return KeyEventResult.handled;
      default:
        // 文字输入、上下/左右微调光标等交回输入框自身处理
        return KeyEventResult.ignored;
    }
  }

  /// 取消按钮：上键回到输入框，右键到「确定」，左键已到边界吞掉。
  /// 确认键不处理，交回 TextButton 自身触发取消。
  KeyEventResult _onCancelKey(FocusNode node, KeyEvent event) {
    if (!_cancelFocus.hasFocus) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _fieldFocus.requestFocus();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _okFocus.requestFocus();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  /// 确定按钮：上键回到输入框，左键到「取消」，右键已到边界吞掉。
  /// 确认键不处理，交回 TextButton 自身触发保存。
  KeyEventResult _onOkKey(FocusNode node, KeyEvent event) {
    if (!_okFocus.hasFocus) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _fieldFocus.requestFocus();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _cancelFocus.requestFocus();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        return KeyEventResult.handled;
      default:
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
        Focus(
          onKeyEvent: _onCancelKey,
          child: TextButton(
            focusNode: _cancelFocus,
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
        ),
        Focus(
          onKeyEvent: _onOkKey,
          child: TextButton(
            focusNode: _okFocus,
            onPressed: () => Get.back(result: _controller.text.trim()),
            child: const Text('确定'),
          ),
        ),
      ],
    );
  }
}
