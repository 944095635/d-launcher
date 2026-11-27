import 'dart:math';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/home_controller.dart';
import '../extensions/space_extension.dart';
import '../widgets/character_card.dart';

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
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/home_background.png'),
          fit: BoxFit.cover,
          // colorFilter: ColorFilter.mode(Colors.white, BlendMode.color),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
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
                  child: Container(
                    color: Colors.white30,
                    child: _buildCards(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 左侧时钟：按内容自适应后整体等比缩放到可用空间，避免溢出
  Widget _buildClock() {
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.topLeft,
      // 不设固定尺寸，Column 按内容布局；FittedBox 拿到真实尺寸再统一缩放
      child: Obx(
        () => Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            // 背景图为深色，时间用浅色文字保证可读，压到单行不换行
            Text(
              controller.time.value,
              // 时间套用 Science Gothic 字体，其余样式沿用原设置
              style: GoogleFonts.scienceGothic(
                textStyle: const TextStyle(
                  fontSize: 200,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            Text(
              controller.date.value,
              style: const TextStyle(
                fontSize: 40,
                color: Colors.white70,
              ),
            ),
            8.verticalSpace,
            Text(
              controller.weekday.value,
              style: const TextStyle(
                fontSize: 40,
                color: Colors.white70,
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
    const angle = 10 * pi / 180;
    const step = 180.0;
    final dx = step * cos(angle);
    final dy = step * sin(angle);
    // 斜切顶边右移，高低错开会让相邻缝隙宽窄交替；按高低差反向补偿水平位置
    final skew = CharacterCard.width * CharacterCard.skewRatio;
    final offsetX = skew * dy / CharacterCard.height;
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.centerRight,
      child: SizedBox(
        // 容器按卡片实际占位计算，改角度或尺寸无需手调
        width: 30 + 3 * dx - offsetX + CharacterCard.width + 30,
        height: 30 + dy + CharacterCard.height + 30,
        child: Stack(
          children: [
            for (var i = 0; i < 4; i++)
              Positioned(
                // 低的卡左移，抵消斜切造成的缝隙变宽
                left: 30 + i * dx - (i.isOdd ? offsetX : 0),
                // 奇偶交替：偶数在上、奇数在下，形成高低高低的节奏
                top: 30 + (i.isOdd ? dy : 0),
                child: const CharacterCard(),
              ),
          ],
        ),
      ),
    );
  }
}
