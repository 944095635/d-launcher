import 'dart:math';

import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/controllers/home_controller.dart';
import 'package:dlauncher/widgets/character_card.dart';

/// 桌面首页。
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  /// 页面主体：背景图铺满，内容为左右布局
  Widget _buildBody() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/home_background.png',
            fit: BoxFit.cover,
            cacheWidth: 600,
            // 备用网络背景：image: NetworkImage("https://w.wallhaven.cc/full/qr/wallhaven-qr5vmq.jpg")
            // colorFilter: ColorFilter.mode(Colors.white, BlendMode.color),
          ),
        ),
        // 内容层同样铺满，给 Row 的 Expanded 与 stretch 提供紧约束
        Positioned.fill(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Row(
              // 两块之间间隔一致，用 spacing 统一，无需逐个插间距组件
              spacing: 40,
              crossAxisAlignment: .stretch,
              children: [
                // 左侧时钟占四成，右侧卡片占六成
                Expanded(flex: 4, child: _buildClock()),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      Spacer(),
                      Expanded(
                        flex: 2,
                        child: _buildCards(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
            // 背景图为深色，时间用浅色文字保证可读，压到单行不换行
            Text(
              controller.time.value,
              // 字体继承全局 ZCOOL，只有 Regular 一种字重，不再指定 w300
              style: const TextStyle(
                fontSize: 120,
                // 等宽数字：分钟变化时每行宽度恒定，避免 FittedBox 缩放跳动
                fontFeatures: [FontFeature.tabularFigures()],
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
                      fontSize: 20,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    controller.weekday.value,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
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
      default:
        return KeyEventResult.ignored;
    }
  }
}
