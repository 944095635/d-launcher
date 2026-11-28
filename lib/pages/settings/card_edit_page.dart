import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/models/app_info.dart';
import 'package:dlauncher/models/installed_app.dart';
import 'package:dlauncher/pages/settings/app_picker_page.dart';
import 'package:dlauncher/pages/settings/settings_controller.dart';
import 'package:dlauncher/pages/settings/text_input_dialog.dart';

/// 单张卡片编辑页：上下切字段，确认键修改，返回键保存当前卡片。
class CardEditPage extends StatefulWidget {
  const CardEditPage({super.key, required this.index});

  /// 正在编辑的卡片在配置列表中的索引
  final int index;

  @override
  State<CardEditPage> createState() => _CardEditPageState();
}

class _CardEditPageState extends State<CardEditPage> {
  /// 预设文字/背景色，确认键在其中循环，避免电视上取色
  static const _palette = [
    '#FFFFFFFF',
    '#FF9E9E9E',
    '#FFFF6182',
    '#FF2D78F9',
    '#FF02B0DB',
    '#FF000000',
  ];

  /// 预设卡面贴图，与打包资源对应
  static const _images = [
    'assets/images/card_1.jpg',
    'assets/images/card_2.jpg',
    'assets/images/card_3.jpg',
    'assets/images/card_4.jpg',
  ];

  static const _fields = ['名称', '包名', '卡面贴图', '文字颜色', '背景颜色'];

  late AppInfo _app;
  int _focused = 0;

  @override
  void initState() {
    super.initState();
    _app = Get.find<SettingsController>().apps[widget.index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('编辑卡片'),
        backgroundColor: const Color(0xFF242424),
      ),
      // 返回键不在此处理：GetX 路由会自行弹栈，重复调用 Get.back 会退两层
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: _fields.length,
          itemBuilder: (context, index) => _buildField(index),
        ),
      ),
    );
  }

  Widget _buildField(int index) {
    final selected = _focused == index;
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
          SizedBox(
            width: 120,
            child: Text(
              _fields[index],
              style: const TextStyle(color: Colors.white70, fontSize: 20),
            ),
          ),
          Expanded(
            child: Text(
              _fieldValue(index),
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          if (selected)
            const Icon(Icons.chevron_right, color: Colors.amber, size: 26),
        ],
      ),
    );
  }

  String _fieldValue(int index) {
    switch (index) {
      case 0:
        return _app.name;
      case 1:
        return _app.packageName ?? '（未设置）';
      case 2:
        return _app.imageAsset ?? '（无贴图）';
      case 3:
        return _colorLabel(_app.textColor.toARGB32());
      case 4:
        return _app.backgroundColor == null
            ? '（默认黑）'
            : _colorLabel(_app.backgroundColor!.toARGB32());
      default:
        return '';
    }
  }

  String _colorLabel(int argb) =>
      '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        if (_focused > 0) setState(() => _focused--);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (_focused < _fields.length - 1) setState(() => _focused++);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        _editFocused();
        return KeyEventResult.handled;
      default:
        // 返回键交回系统，由 GetX 路由弹栈
        return KeyEventResult.ignored;
    }
  }

  /// 确认键：按字段类型采用不同编辑方式
  Future<void> _editFocused() async {
    switch (_focused) {
      case 0:
        await _editName();
      case 1:
        await _pickPackage();
      case 2:
        _cycleImage();
      case 3:
        _cycleColor(text: true);
      case 4:
        _cycleColor(text: false);
    }
    // 每次修改即时写回 controller（内部落盘），返回键不再承担保存职责
    Get.find<SettingsController>().updateApp(widget.index, _app);
    setState(() {});
  }

  /// 名称用对话框输入，电视上可外接键盘或用软键盘
  Future<void> _editName() async {
    // 控制器交给弹窗自持并在其 dispose 时释放，避免返回时淡出动画访问已释放对象
    final value = await Get.dialog<String>(
      TextInputDialog(title: '输入名称', hint: '卡片显示名称', initial: _app.name),
      barrierDismissible: false,
    );
    if (value != null && value.isNotEmpty) {
      _app = _copyWith(name: value);
    }
  }

  Future<void> _pickPackage() async {
    final controller = Get.find<SettingsController>();
    await controller.loadInstalledApps();
    final picked = await Get.to<InstalledApp>(() => const AppPickerPage());
    if (picked != null) {
      // 点选普通应用后走包名拉起，显式组件配置不再需要，直接构造新对象清掉
      _app = AppInfo(
        name: _app.name,
        packageName: picked.packageName,
        textColor: _app.textColor,
        backgroundColor: _app.backgroundColor,
        imageAsset: _app.imageAsset,
      );
    }
  }

  void _cycleImage() {
    final current = _app.imageAsset;
    final index = _images.indexOf(current ?? '');
    final next = _images[(index + 1) % _images.length];
    _app = _copyWith(imageAsset: next);
  }

  void _cycleColor({required bool text}) {
    final current = text
        ? _colorLabel(_app.textColor.toARGB32())
        : (_app.backgroundColor == null
            ? null
            : _colorLabel(_app.backgroundColor!.toARGB32()));
    final index = current == null ? -1 : _palette.indexOf(current);
    final next = _palette[(index + 1) % _palette.length];
    final color = Color(int.parse(next.substring(1), radix: 16));
    _app = text ? _copyWith(textColor: color) : _copyWith(backgroundColor: color);
  }

  /// 基于当前值生成新 AppInfo，只覆盖传入字段
  AppInfo _copyWith({
    String? name,
    String? packageName,
    String? launchAction,
    String? launchComponent,
    Map<String, int>? launchIntExtras,
    Color? textColor,
    Color? backgroundColor,
    String? imageAsset,
  }) {
    return AppInfo(
      name: name ?? _app.name,
      packageName: packageName ?? _app.packageName,
      launchAction: launchAction ?? _app.launchAction,
      launchComponent: launchComponent ?? _app.launchComponent,
      launchIntExtras: launchIntExtras ?? _app.launchIntExtras,
      textColor: textColor ?? _app.textColor,
      backgroundColor: backgroundColor ?? _app.backgroundColor,
      imageAsset: imageAsset ?? _app.imageAsset,
    );
  }

}
