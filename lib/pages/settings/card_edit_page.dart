import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/models/app_info.dart';
import 'package:dlauncher/models/installed_app.dart';
import 'package:dlauncher/pages/settings/app_picker_page.dart';
import 'package:dlauncher/pages/settings/card_gallery_page.dart';
import 'package:dlauncher/pages/settings/settings_controller.dart';
import 'package:dlauncher/pages/settings/text_input_dialog.dart';
import 'package:dlauncher/widgets/character_card.dart';
import 'package:dlauncher/widgets/focus_scroll_helper.dart';

/// 单张卡片编辑页：左侧实时预览卡片，右侧菜单上下切字段并修改，最后一项可删除。
class CardEditPage extends StatefulWidget {
  const CardEditPage({super.key, required this.index});

  /// 正在编辑的卡片在配置列表中的索引
  final int index;

  @override
  State<CardEditPage> createState() => _CardEditPageState();
}

class _CardEditPageState extends State<CardEditPage> {
  /// 预设文字/背景色，确认键在其中循环，避免电视上取色。
  /// 前 6 种为原有配色，后面追加红橙黄绿紫、深灰。
  static const _palette = [
    '#FFFFFFFF',
    '#FF9E9E9E',
    '#FFFF6182',
    '#FF2D78F9',
    '#FF02B0DB',
    '#FF000000',
    '#FFF44336',
    '#FFFF9800',
    '#FFFFEB3B',
    '#FF4CAF50',
    '#FF9C27B0',
    '#FF424242',
  ];

  static const _fields = [
    '名称',
    '类型',
    '包名',
    '卡面贴图',
    '文字颜色',
    '背景颜色',
    '蒙版颜色',
    '删除卡片',
  ];

  late AppInfo _app;
  int _focused = 0;
  /// 删除是二次确认操作：首次按确认键只武装，再按一次才真正删除
  bool _deleteArmed = false;

  /// 单项约 72 高，焦点移出视野时用于定位
  late final _scroll = FocusScrollHelper(estimatedItemHeight: 72);

  @override
  void initState() {
    super.initState();
    _app = Get.find<SettingsController>().apps[widget.index];
  }

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
        title: const Text('编辑卡片'),
        backgroundColor: const Color(0xFF242424),
      ),
      // 返回键不在此处理：GetX 路由会自行弹栈，重复调用 Get.back 会退两层
      body: Row(
        crossAxisAlignment: .stretch,
        children: [
          // 左侧 1 份实时预览卡片，右侧 3 份是编辑菜单
          Expanded(flex: 2, child: _buildPreview()),
          Expanded(
            flex: 5,
            child: Focus(
              autofocus: true,
              onKeyEvent: _onKeyEvent,
              child: ListView.builder(
                controller: _scroll.controller,
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: _fields.length,
                itemBuilder: (context, index) => _buildField(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 按当前编辑值渲染卡片，改颜色/贴图/名称后 setState 即时反映到这里。
  /// 点击预览卡进入贴图选择页。
  Widget _buildPreview() {
    return GestureDetector(
      // 整块预览区域都可点击，不受 CharacterCard 实际尺寸限制
      behavior: HitTestBehavior.opaque,
      onTap: _pickImage,
      child: FittedBox(
        fit: .none,
        child: CharacterCard(
          name: _app.name,
          backgroundColor: _app.backgroundColor ?? Colors.black,
          imageAsset: _app.imageAsset,
          textColor: _app.textColor,
          maskColor: _app.maskColor,
          // 预览态固定高亮，和首页聚焦卡片的样子一致
          isFocused: true,
        ),
      ),
    );
  }

  Widget _buildField(int index) {
    final selected = _focused == index;
    final isDelete = index == _fields.length - 1;
    // 删除项整行用红色区分，和普通字段一眼可分
    final accent = isDelete ? Colors.redAccent : Colors.white;
    final field = AnimatedContainer(
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
          SizedBox(
            width: 120,
            child: Text(
              _fields[index],
              style: TextStyle(
                color: isDelete ? Colors.redAccent : Colors.white70,
                fontSize: 20,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _fieldValue(index),
              style: TextStyle(color: accent, fontSize: 20),
            ),
          ),
          if (selected)
            Icon(
              isDelete ? Icons.delete_outline : Icons.chevron_right,
              color: isDelete ? Colors.redAccent : Colors.amber,
              size: 26,
            ),
        ],
      ),
    );
    // 卡面贴图是唯一用子页面选择的字段，鼠标/触摸点击整行也直接进选择页
    return index == 3
        ? GestureDetector(onTap: _pickImage, child: field)
        : field;
  }

  String _fieldValue(int index) {
    switch (index) {
      case 0:
        return _app.name;
      case 1:
        return _app.appType.label;
      case 2:
        return _app.packageName ?? '（未设置）';
      case 3:
        // 贴图地址通常是长 URL，菜单里只提示是否已选，避免挤占整行
        return _app.imageAsset == null ? '（无贴图）' : '已选择';
      case 4:
        return _colorLabel(_app.textColor.toARGB32());
      case 5:
        return _app.backgroundColor == null
            ? '（默认黑）'
            : _colorLabel(_app.backgroundColor!.toARGB32());
      case 6:
        return _app.maskColor.label;
      case 7:
        return _deleteArmed ? '再按一次确认删除' : '删除这张卡片';
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
        if (_focused > 0) {
          // 离开删除项就撤销武装，避免误删
          setState(() {
            _focused--;
            _deleteArmed = false;
          });
          _scroll.ensureVisible(_focused);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (_focused < _fields.length - 1) {
          setState(() {
            _focused++;
            _deleteArmed = false;
          });
          _scroll.ensureVisible(_focused);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        _editFocused();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        // 遥控器无触摸，左键作等价入口进入贴图选择页
        _pickImage();
        return KeyEventResult.handled;
      default:
        // 返回键交回系统，由 GetX 路由弹栈
        return KeyEventResult.ignored;
    }
  }

  /// 确认键：按字段类型采用不同编辑方式；删除项需二次确认
  Future<void> _editFocused() async {
    if (_focused == _fields.length - 1) {
      if (!_deleteArmed) {
        setState(() => _deleteArmed = true);
        return;
      }
      // 删除后当前卡片已失效，直接退回 App 设置页，不做写回
      Get.find<SettingsController>().deleteAt(widget.index);
      Get.back();
      return;
    }
    switch (_focused) {
      case 0:
        await _editName();
      case 1:
        _cycleType();
      case 2:
        await _pickPackage();
      case 3:
        // 选择页内部已写盘并刷新，这里直接返回，避免末尾重复写一次
        await _pickImage();
        return;
      case 4:
        _cycleColor(text: true);
      case 5:
        _cycleColor(text: false);
      case 6:
        _cycleMaskColor();
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
        maskColor: _app.maskColor,
      );
    }
  }

  /// 类型在普通 App / HDMI 1 / HDMI 2 / HDMI 3 间循环，
  /// 选信号源时自动填好固定的 action/component/input
  void _cycleType() {
    final current = _app.appType;
    final next = AppType.values[(current.index + 1) % AppType.values.length];
    _app = _app.withAppType(next);
  }

  /// 打开贴图选择页：返回 null 是取消；空串是「不使用卡片」，清掉贴图
  Future<void> _pickImage() async {
    final picked = await Get.to<String>(
      () => CardGalleryPage(
        initialImage: _app.imageAsset,
        cardName: _app.name,
        textColor: _app.textColor,
        backgroundColor: _app.backgroundColor,
        maskColor: _app.maskColor,
      ),
    );
    if (picked == null) return;
    // 空串表示清除贴图，要显式传标记，不能靠 null（null 在 _copyWith 里表示「不覆盖」）
    final clear = picked.isEmpty;
    _app = _copyWith(imageAsset: clear ? null : picked, clearImage: clear);
    Get.find<SettingsController>().updateApp(widget.index, _app);
    setState(() {});
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

  /// 蒙版颜色只有黑白两值，确认键直接取反
  void _cycleMaskColor() {
    _app = _copyWith(
      maskColor: _app.maskColor == CardMaskColor.black
          ? CardMaskColor.white
          : CardMaskColor.black,
    );
  }

  /// 基于当前值生成新 AppInfo，只覆盖传入字段。
  /// clearImage 用于把贴图置空，因为 null 在这里表示「不覆盖」。
  AppInfo _copyWith({
    String? name,
    String? packageName,
    String? launchAction,
    String? launchComponent,
    Map<String, int>? launchIntExtras,
    Color? textColor,
    Color? backgroundColor,
    String? imageAsset,
    CardMaskColor? maskColor,
    bool clearImage = false,
  }) {
    return AppInfo(
      name: name ?? _app.name,
      packageName: packageName ?? _app.packageName,
      launchAction: launchAction ?? _app.launchAction,
      launchComponent: launchComponent ?? _app.launchComponent,
      launchIntExtras: launchIntExtras ?? _app.launchIntExtras,
      textColor: textColor ?? _app.textColor,
      backgroundColor: backgroundColor ?? _app.backgroundColor,
      imageAsset: clearImage ? null : (imageAsset ?? _app.imageAsset),
      maskColor: maskColor ?? _app.maskColor,
    );
  }

}
