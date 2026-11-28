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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF242424),
      title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('取消')),
        TextButton(
          onPressed: () => Get.back(result: _controller.text.trim()),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
