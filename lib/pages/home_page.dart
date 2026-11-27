import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/home_controller.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
      child: Row(
        crossAxisAlignment: .stretch,
        children: [
          // 左侧时钟占四成，右侧卡片占六成
          Expanded(flex: 4, child: _buildClock()),
          const SizedBox(width: 40),
          Expanded(flex: 6, child: _buildCards()),
        ],
      ),
    );
  }

  /// 左侧时钟：内部用固定设计尺寸，整体等比缩放到可用空间
  Widget _buildClock() {
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      child: SizedBox(
        // 以 1920×1080 电视为设计基准，实际按可用区域等比缩放
        width: 720,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 背景图为深色，时间用浅色文字保证可读，压到单行不换行
            Obx(
              () => Text(
                controller.time.value,
                style: const TextStyle(
                  fontSize: 200,
                  height: 1,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Obx(
              () => Text(
                controller.date.value,
                style: const TextStyle(fontSize: 40, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Text(
                controller.weekday.value,
                style: const TextStyle(fontSize: 40, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 右侧四个角色卡片，等宽横排
  Widget _buildCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        
      ],
    );
  }

  /// 单张卡片按原图比例显示，保留透明区域
  Widget _buildCard(String asset) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 559 / 873,
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }
}
