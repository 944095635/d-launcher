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
              children: [
                Spacer(),
                Expanded(flex: 2, child: _buildCards()),
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

  /// 右侧四张卡片：顶部对齐、横向等距，整体等比缩放
  Widget _buildCards() {
    // 横向等间距且大于卡宽，避免卡片互相遮挡；顶部对齐保证间隔视觉一致
    const stepX = 200.0;
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 840,
        height: 590,
        child: Stack(
          children: [
            for (var i = 0; i < 4; i++)
              Positioned(
                left: 30 + i * stepX,
                top: 30,
                child: const CharacterCard(),
              ),
          ],
        ),
      ),
    );
  }
}
