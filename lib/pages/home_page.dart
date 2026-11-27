import 'dart:math';

import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/controllers/home_controller.dart';
import 'package:dlauncher/services/platform_service.dart';
import 'package:dlauncher/widgets/character_card.dart';

/// 桌面首页。
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  // 时钟文字的轻微投影，让浅色字在深浅不一的壁纸上都清晰
  static const _textShadows = [
    Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black54),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  /// 页面主体：背景图铺满，内容为左右布局
  Widget _buildBody() {
    return Stack(
      fit: .expand,
      children: [
        // 背景由控制器定时随机切换，换图时淡入避免突变
        Obx(
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            // AnimatedSwitcher 内部是 Stack，child 需显式撑满才能 cover 铺满
            child: SizedBox.expand(
              key: ValueKey(controller.backgroundImage.value),
              child: controller.backgroundImage.value.isEmpty
                  ? const SizedBox.shrink()
                  : Image.asset(
                      controller.backgroundImage.value,
                      fit: BoxFit.cover,
                      cacheHeight: 2160,
                    ),
            ),
          ),
        ),
        // 内容层同样铺满，给 Row 的 Expanded 与 stretch 提供紧约束
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Row(
            // 两块之间间隔一致，用 spacing 统一，无需逐个插间距组件
            spacing: 40,
            crossAxisAlignment: .stretch,
            children: [
              // 左侧时钟占四成，右侧卡片占六成
              Expanded(flex: 3, child: _buildClock()),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    // 天气启动时拉取一次，未返回前显示占位，避免文字区域塌陷
                    Obx(() => Text(
                          controller.weatherText.value.isEmpty
                              ? '天气获取中…'
                              : controller.weatherText.value,
                          textAlign: .end,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color.fromARGB(255, 220, 220, 220),
                            shadows: _textShadows,
                          ),
                        )),
                    Spacer(),
                    Expanded(
                      flex: 3,
                      child: _buildCards(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 左侧时钟：按内容自适应后整体等比缩放到可用空间，避免溢出
  Widget _buildClock() {
    return FittedBox(
      fit: BoxFit.none,
      alignment: Alignment.topCenter,
      // 不设固定尺寸，Column 按内容布局；FittedBox 拿到真实尺寸再统一缩放
      child: Obx(
        () => Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            // 黄底时间：高度随文字自适应，压缩行高去掉字形下方的行高留白
            Text(
              controller.time.value,
              // 字体继承全局 ZCOOL，只有 Regular 一种字重，不再指定 w300
              style: const TextStyle(
                fontSize: 120,
                // 行高压到字号的 0.8，黄块紧贴数字；按比例缩放，换字号/字体无需改这里
                height: 1,
                // 等宽数字：分钟变化时每行宽度恒定，避免 FittedBox 缩放跳动
                fontFeatures: [FontFeature.tabularFigures()],
                shadows: _textShadows,
              ),
            ),
            // 日期与星期整体右缩进，避免与时间左端齐平显得突出
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    controller.date.value,
                    // 日期与星期沿用时间的字体，保持视觉统一
                    style: const TextStyle(
                      fontSize: 26,
                      color: Color.fromARGB(255, 230, 230, 230),
                      shadows: _textShadows,
                    ),
                  ),
                  Text(
                    controller.weekday.value,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 220, 220, 220),
                      shadows: _textShadows,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 右侧四张卡片：水平等距、高低交替错落，整体等比缩放
  Widget _buildCards() {
    // 水平间隔由步长决定，需大于卡宽避免重叠；交替高低由倾角决定
    const angle = 0 * pi / 180;
    const step = 160.0;
    final dx = step * cos(angle);
    final dy = step * sin(angle);
    // 斜切顶边右移，高低错开会让相邻缝隙宽窄交替；按高低差反向补偿水平位置
    final skew = CharacterCard.width * CharacterCard.skewRatio;
    final offsetX = skew * dy / CharacterCard.height;
    return Focus(
      // 进入首页自动聚焦到卡片区，遥控器左右键在卡片间切换
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.centerRight,
        child: SizedBox(
          // 容器按卡片实际占位计算，改角度或尺寸无需手调
          width: 30 + 3 * dx - offsetX + CharacterCard.width + 30,
          height: 30 + dy + CharacterCard.height + 30,
          child: Obx(
            () => Stack(
              children: [
                for (var i = 0; i < controller.apps.length; i++)
                  Positioned(
                    // 低的卡左移，抵消斜切造成的缝隙变宽
                    left: 30 + i * dx - (i.isOdd ? offsetX : 0),
                    // 奇偶交替：偶数在上、奇数在下，形成高低高低的节奏
                    top: 30 + (i.isOdd ? dy : 0),
                    child: CharacterCard(
                      name: controller.apps[i].name,
                      backgroundColor:
                          controller.apps[i].backgroundColor ?? Colors.black,
                      imageAsset: controller.apps[i].imageAsset,
                      textColor: controller.apps[i].textColor,
                      // 当前焦点卡片高亮
                      isFocused: controller.focusedIndex.value == i,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 遥控器按键：左右切焦点，确认键拉起当前应用
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        controller.moveFocus(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        controller.moveFocus(1);
        return KeyEventResult.handled;
      // 确认键只在按下瞬间触发一次，长按重复不重复拉起
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        if (event is KeyDownEvent) controller.openFocusedApp();
        return KeyEventResult.handled;
      // 后退键：手动换一张背景，只按下的瞬间触发，不影响定时轮换
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.goBack:
        if (event is KeyDownEvent) controller.refreshBackground();
        return KeyEventResult.handled;
      // 菜单键：短按打开系统设置，长按重复不重复拉起
      case LogicalKeyboardKey.contextMenu:
        if (event is KeyDownEvent) PlatformService.openSettings();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }
}
