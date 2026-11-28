import 'package:flutter/services.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/pages/home/home_controller.dart';
import 'package:dlauncher/services/platform_service.dart';
import 'package:dlauncher/widgets/character_card.dart';

/// 桌面首页。
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  // 时钟文字的轻微投影，让浅色字在深浅不一的壁纸上都清晰
  static const _textShadows = [
    Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black54),
  ];

  /// 背景图淡入：本地图多同步命中直接显示，网络图首次解码完成再渐显
  static Widget _fadeInBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded) return child;
    return AnimatedOpacity(
      opacity: frame == null ? 0 : 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 桌面是根页面，系统返回键不能退出：一旦 finish，作为 HOME 会被系统重新拉起，表现为整页重启。
    // 返回键改在这里换背景，不依赖卡片区的键盘焦点，焦点丢失时也能响应。
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.refreshBackground();
      },
      child: Scaffold(
        body: _buildBody(),
      ),
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
                  : controller.backgroundImage.value.startsWith('http')
                  // 网络图走磁盘缓存，重复进首页不再重新下载；淡入参数与本地图保持一致
                  ? CachedNetworkImage(
                      imageUrl: controller.backgroundImage.value,
                      fit: BoxFit.cover,
                      memCacheHeight: 2160,
                      fadeInDuration: const Duration(milliseconds: 500),
                      fadeInCurve: Curves.easeOut,
                    )
                  : Image.asset(
                      controller.backgroundImage.value,
                      fit: BoxFit.cover,
                      cacheHeight: 2160,
                      frameBuilder: _fadeInBuilder,
                    ),
            ),
          ),
        ),
        // 内容层同样铺满，给 Row 的 Expanded 与 stretch 提供紧约束
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            // 两块之间间隔一致，用 spacing 统一，无需逐个插间距组件
            spacing: 30,
            crossAxisAlignment: .stretch,
            children: [
              // 左侧时钟占四成，右侧卡片占六成
              Expanded(flex: 3, child: _buildClock()),
              Expanded(
                flex: 5,
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
      ],
    );
  }

  /// 左侧时钟：按内容自适应后整体等比缩放到可用空间，避免溢出
  Widget _buildClock() {
    return FittedBox(
      fit: BoxFit.none,
      alignment: Alignment.topLeft,
      // 不设固定尺寸，Column 按内容布局；FittedBox 拿到真实尺寸再统一缩放
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Obx(
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
                Row(
                  spacing: 8,
                  children: [
                    Text(
                      controller.date.value,
                      // 日期与星期沿用时间的字体，保持视觉统一
                      style: const TextStyle(
                        fontSize: 22,
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
              ],
            ),
          ),

          // 天气启动时拉取一次，未返回前显示占位，避免文字区域塌陷
          Obx(
            () => Text(
              controller.weatherText.value.isEmpty
                  ? '天气获取中…'
                  : controller.weatherText.value,
              textAlign: .end,
              style: const TextStyle(
                fontSize: 20,
                color: Color.fromARGB(255, 220, 220, 220),
                shadows: _textShadows,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 右侧应用卡片：固定渲染 4 张，焦点越过第 4 张时窗口整体左移一张
  Widget _buildCards() {
    // 卡片横向步长，小于卡宽以保留原来层叠的视觉效果
    const step = 160.0;
    const visible = HomeController.visibleCardCount;
    return Focus(
      // 进入首页自动聚焦到卡片区，遥控器左右键在卡片间切换
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.bottomRight,
        child: SizedBox(
          // 容器按固定 4 张的占位计算，改卡片尺寸时需同步这里
          width: 30 + (visible - 1) * step + CharacterCard.width + 30,
          height: 30 + CharacterCard.height + 30,
          child: Obx(
            () {
              final focused = controller.focusedIndex.value;
              final count = controller.apps.length;
              // 焦点进入第 5 张起窗口右端跟着走，左端同步滑出；到末尾就停住
              final maxStart = count > visible ? count - visible : 0;
              final start = (focused - (visible - 1)).clamp(0, maxStart).toInt();
              // 不足 4 张时把卡片排到右侧槽位，右端与满屏时对齐
              final shown = (count - start).clamp(0, visible).toInt();
              final rightOffset = visible - shown;
              return Stack(
                children: [
                  for (var i = 0; i < shown; i++)
                    AnimatedPositioned(
                      // 以 AppInfo 实例作 key，窗口滑动时同一张卡能被识别，平滑位移而非闪现
                      key: ValueKey(controller.apps[start + i]),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      left: 30 + (i + rightOffset) * step,
                      top: 30,
                      child: CharacterCard(
                        name: controller.apps[start + i].name,
                        backgroundColor:
                            controller.apps[start + i].backgroundColor ?? Colors.black,
                        imageAsset: controller.apps[start + i].imageAsset,
                        textColor: controller.apps[start + i].textColor,
                        maskColor: controller.apps[start + i].maskColor,
                        // 当前焦点卡片高亮
                        isFocused: start + i == focused,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 遥控器按键：左右切焦点，上键进设置，确认键拉起应用，菜单键开系统设置
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final isDown = event is KeyDownEvent;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (isDown) controller.moveFocus(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (isDown) controller.moveFocus(1);
        return KeyEventResult.handled;
      // 上键进桌面设置页，只在按下瞬间触发一次
      case LogicalKeyboardKey.arrowUp:
        if (isDown) controller.openSettingsPage();
        return KeyEventResult.handled;
      // 确认键只在按下瞬间触发一次，长按重复不重复拉起
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        if (isDown) controller.openFocusedApp();
        return KeyEventResult.handled;
      // 后退键交给 PopScope 处理（见 build），此处不拦截，避免重复换图
      // 菜单键短按开系统设置，长按重复不重复拉起
      case LogicalKeyboardKey.contextMenu:
        if (isDown) PlatformService.openSettings();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }
}
