import 'package:material_ui/material_ui.dart';

/// 单张应用卡片：带圆角的斜切卡面，右下角显示 App 名称。
class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.name,
    this.backgroundColor = Colors.white,
    this.imageAsset,
    this.logoAsset,
    this.textColor = Colors.white,
    this.isFocused = false,
    this.child,
  });

  /// 卡片尺寸，供外层布局计算平移与容器大小
  static const width = 200.0;
  static const height = 360.0;

  /// 顶边相对底边的右移比例，决定斜切程度；外层布局按此补偿间隔
  static const skewRatio = 0.28;

  /// 图片缓存超采系数：卡片经外层 FittedBox 放大显示，按逻辑尺寸解码会模糊
  static const cacheOversample = 3.0;

  /// 右下角显示的 App 名称
  final String name;

  /// 卡面背景色，默认白
  final Color backgroundColor;

  /// 卡面贴图，http(s) 开头走网络图，否则当作本地资源路径；为空则不显示
  final String? imageAsset;

  /// 卡片中心区域等比显示的 logo，为空则不显示
  final String? logoAsset;

  /// 卡面文字颜色，默认白
  final Color textColor;

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
          painter: _CardPainter(color: backgroundColor, isFocused: isFocused),
          child: ClipPath(
            clipper: _CardClipper(),
            child: Stack(
              children: [
                // 贴图铺满卡面，由 ClipPath 裁成斜切形状；支持网络地址与本地资源
                // 只按高度设缓存：cover 由高度撑满，宽度按比例推导且必然够覆盖，强行双设会破坏比例
                if (imageAsset != null)
                  Positioned.fill(
                    child: imageAsset!.startsWith('http')
                        ? Image.network(
                            imageAsset!,
                            fit: BoxFit.cover,
                            cacheHeight: (height * cacheScale).round(),
                          )
                        : Image.asset(
                            imageAsset!,
                            fit: BoxFit.cover,
                            cacheHeight: (height * cacheScale).round(),
                          ),
                  ),
                // 中心 logo 等比显示，不裁切；斜切卡面左右中点仍在 width/2，直接居中即可
                if (logoAsset != null)
                  Center(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: logoAsset!.startsWith('http')
                          ? Image.network(
                              logoAsset!,
                              fit: BoxFit.contain,
                              cacheWidth: (48 * cacheScale).round(),
                            )
                          : Image.asset(
                              logoAsset!,
                              fit: BoxFit.contain,
                              cacheWidth: (48 * cacheScale).round(),
                            ),
                    ),
                  ),
                ?child,
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
  const _CardPainter({required this.color, required this.isFocused});

  /// 由 App 背景色决定卡面底色
  final Color color;

  /// 焦点态
  final bool isFocused;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildCardPath(size);
    // 先画投影，再画底色卡面
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black54
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(path, Paint()..color = color);
    // 焦点态：沿卡面轮廓由外向内叠三层发光，范围比单层描边更大更醒目
    if (isFocused) {
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
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CardPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isFocused != isFocused;
}
