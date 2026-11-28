import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/models/app_info.dart';
import 'package:dlauncher/services/card_image_service.dart';
import 'package:dlauncher/widgets/character_card.dart';

/// 卡面贴图选择页：左右翻看可选贴图，第一项为「不使用卡片」。
/// 卡片紧挨着排布，当前卡在最上层并轻微盖住左右两张；选中后返回贴图地址。
class CardGalleryPage extends StatefulWidget {
  const CardGalleryPage({
    super.key,
    required this.initialImage,
    required this.cardName,
    required this.textColor,
    required this.backgroundColor,
    required this.maskColor,
  });

  /// 当前已选贴图，用于进入时定位
  final String? initialImage;

  /// 以下几项用于按当前卡片样式渲染预览
  final String cardName;
  final Color textColor;
  final Color? backgroundColor;
  final CardMaskColor maskColor;

  @override
  State<CardGalleryPage> createState() => _CardGalleryPageState();
}

class _CardGalleryPageState extends State<CardGalleryPage> {
  /// 卡片相对主卡片的缩放，略小以容纳两侧卡片
  static const _cardScale = 0.78;

  /// 相邻卡片中心间距占显示宽度的比例，小于 1 才靠拢并轻微重叠
  static const _stepRatio = 0.9;

  /// 两侧各渲染的卡片数量，超出视野的不画
  static const _sideCount = 3;

  static const _duration = Duration(milliseconds: 250);

  /// 空串代表「不使用卡片」，固定在首位；其余来自首页启动时拉取的服务器清单
  late final List<String> _images = [
    '',
    ...CardImageService.cachedImages,
  ];

  int _current = 0;

  @override
  void initState() {
    super.initState();
    final initial = _images.indexOf(widget.initialImage ?? '');
    _current = initial < 0 ? 0 : initial;
  }

  /// 左右键翻页，确认键选中当前项；返回键交回系统由 GetX 弹栈（返回 null 即取消）
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (_current > 0) _goTo(_current - 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (_current < _images.length - 1) _goTo(_current + 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        Get.back<String>(result: _images[_current]);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _goTo(int index) => setState(() => _current = index);

  Widget _buildCard(int index) {
    final image = _images[index];
    final isNone = image.isEmpty;
    return Transform.scale(
      scale: _cardScale,
      child: GestureDetector(
        onTap: () => Get.back<String>(result: image),
        child: CharacterCard(
          // 不使用卡片时直接把文字标在卡面上，一眼能认出这一项
          name: isNone ? '不使用卡片' : widget.cardName,
          backgroundColor: widget.backgroundColor ?? Colors.black,
          imageAsset: isNone ? null : image,
          // 这一项没有贴图，文字用固定白，避免和卡面底色撞色看不清
          textColor: isNone ? Colors.white : widget.textColor,
          // 白色蒙版配固定白字会看不清，「不使用卡片」项统一用黑蒙版
          maskColor: isNone ? CardMaskColor.black : widget.maskColor,
          // 当前卡高亮放大，盖住左右两张
          isFocused: index == _current,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text('选择卡片 ${_current + 1}/${_images.length}'),
        backgroundColor: const Color(0xFF242424),
      ),
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final centerX = constraints.maxWidth / 2;
            final centerY = constraints.maxHeight / 2;
            // 间距略小于卡片显示宽，前后卡才靠拢并重叠一点点
            final step = CharacterCard.width * _cardScale * _stepRatio;
            // 由远到近排列，当前卡最后加入 Stack，绘制在最上层
            final order = <int>[];
            for (var distance = _sideCount; distance >= 1; distance--) {
              final left = _current - distance;
              final right = _current + distance;
              if (left >= 0) order.add(left);
              if (right < _images.length) order.add(right);
            }
            order.add(_current);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              // 触屏左右滑动翻页；电视上主要用遥控器左右键
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < 0 && _current < _images.length - 1) {
                  _goTo(_current + 1);
                } else if (velocity > 0 && _current > 0) {
                  _goTo(_current - 1);
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  for (final index in order)
                    AnimatedPositioned(
                      key: ValueKey(index),
                      duration: _duration,
                      curve: Curves.easeOut,
                      left: centerX - CharacterCard.width / 2 +
                          (index - _current) * step,
                      top: centerY - CharacterCard.height / 2,
                      child: _buildCard(index),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
