import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/models/app_info.dart';

/// 单张应用卡片：带圆角的斜切卡面，右下角显示 App 名称。
class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.name,
    this.backgroundColor = Colors.black,
    this.imageAsset,
    this.textColor = Colors.white,
    this.maskColor = CardMaskColor.black,
    this.isFocused = false,
    this.child,
  });

  /// 卡片尺寸，供外层布局计算平移与容器大小
  static const width = 200.0;
  static const height = 300.0;

  /// 顶边相对底边的右移比例，决定斜切程度；外层布局按此补偿间隔
  static const skewRatio = 0.28;

  /// 图片缓存超采系数：卡片经外层 FittedBox 放大显示，按逻辑尺寸解码会模糊
  static const cacheOversample = 3.0;

  /// 右下角显示的 App 名称
  final String name;

  /// 卡面背景色，默认黑；有贴图时不绘制底色
  final Color backgroundColor;

  /// 卡面贴图网络地址，为空则不显示
  final String? imageAsset;

  /// 卡面文字颜色，默认白
  final Color textColor;

  /// 底部渐变蒙版颜色，默认黑，垫在名称下提升可读性
  final CardMaskColor maskColor;

  /// 是否为遥控器焦点卡片，焦点态高亮描边
  final bool isFocused;

  /// 卡片内容，暂为空，后续按需填充
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // 缓存尺寸 = 逻辑尺寸 × 设备像素比 × 超采系数，兼顾清晰度与解码开销
    final cacheScale = MediaQuery.devicePixelRatioOf(context) * cacheOversample;
    // 焦点态平滑放大，配合光效强化选中反馈
    return AnimatedScale(
      scale: isFocused ? 1.06 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _CardPainter(
            color: backgroundColor,
            isFocused: isFocused,
            hasImage: imageAsset != null,
            showGlow: maskColor.hasMask,
          ),
          child: ClipPath(
            clipper: _CardClipper(),
            child: Stack(
              children: [
                // 贴图铺满卡面，由 ClipPath 裁成斜切形状；统一走磁盘缓存
                if (imageAsset != null)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: imageAsset!,
                      fit: BoxFit.cover,
                      // 只按高度缓存：cover 由高度撑满，宽度按比例推导必然够覆盖
                      memCacheHeight: (height * cacheScale).round(),
                      fadeInDuration: const Duration(milliseconds: 500),
                      fadeInCurve: Curves.easeOut,
                    ),
                  ),
                ?child,
                // 底部渐变蒙版：由底部实色向上渐隐到全透明，垫在名称下提升可读性。
                // 「不使用」时整段跳过，卡面保持贴图或底色的原样
                if (maskColor.hasMask)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            maskColor.color,
                            Colors.transparent,
                          ],
                          stops: [0, .8],
                        ),
                      ),
                    ),
                  ),
                // 名称压在卡面右下角；右侧留出斜切量避免文字被裁
                Positioned(
                  right: width * skewRatio + 12,
                  bottom: 14,
                  child: Text(
                    name,
                    // App 名走全局字体，仅按卡片底色指定文字颜色
                    style: TextStyle(
                      fontSize: 20,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 圆角半径
const _radius = 16.0;

/// 生成带圆角的斜切梯形：顶边窄且右移，四角倒圆角，painter 与 clipper 共用
Path _buildCardPath(Size size) {
  final inset = size.width * CharacterCard.skewRatio;
  // 顺时针四个顶点：左上、右上、右下、左下
  final points = [
    Offset(inset, 0),
    Offset(size.width, 0),
    Offset(size.width - inset, size.height),
    Offset(0, size.height),
  ];

  final path = Path();
  for (var i = 0; i < points.length; i++) {
    final prev = points[(i - 1 + points.length) % points.length];
    final cur = points[i];
    final next = points[(i + 1) % points.length];
    // 沿两条边各退让 radius，用二次贝塞尔连接成圆角
    final toPrev = prev - cur;
    final toNext = next - cur;
    final p1 = cur + toPrev / toPrev.distance * _radius;
    final p2 = cur + toNext / toNext.distance * _radius;
    if (i == 0) {
      path.moveTo(p1.dx, p1.dy);
    } else {
      path.lineTo(p1.dx, p1.dy);
    }
    path.quadraticBezierTo(cur.dx, cur.dy, p2.dx, p2.dy);
  }
  path.close();
  return path;
}

class _CardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _buildCardPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CardPainter extends CustomPainter {
  const _CardPainter({
    required this.color,
    required this.isFocused,
    required this.hasImage,
    required this.showGlow,
  });

  /// 由 App 背景色决定卡面底色
  final Color color;

  /// 焦点态
  final bool isFocused;

  /// 有贴图时贴图铺满卡面，底色被完全遮住，跳过绘制
  final bool hasImage;

  /// 焦点态是否画描边光效；不用蒙版时只留放大，不画光效
  final bool showGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildCardPath(size);
    // 先画投影
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black54
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // 有贴图时底色被完全盖住，不必再画
    if (!hasImage) {
      canvas.drawPath(path, Paint()..color = color);
    }
    // 焦点态光效：不用蒙版时跳过，只保留外层 AnimatedScale 的放大反馈
    if (isFocused && showGlow) {
      // 外层大范围柔光
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      // 中层光带
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      // 内层清晰白边
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CardPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isFocused != isFocused ||
      oldDelegate.hasImage != hasImage ||
      oldDelegate.showGlow != showGlow;
}
