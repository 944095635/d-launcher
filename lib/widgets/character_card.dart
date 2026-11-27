import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// 单张应用卡片：带圆角的斜切卡面，右下角显示 App 名称。
class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.name,
    this.backgroundColor = Colors.white,
    this.imageAsset,
    this.textColor = Colors.white,
    this.child,
  });

  /// 卡片尺寸，供外层布局计算平移与容器大小
  static const width = 200.0;
  static const height = 360.0;

  /// 顶边相对底边的右移比例，决定斜切程度；外层布局按此补偿间隔
  static const skewRatio = 0.28;

  /// 右下角显示的 App 名称
  final String name;

  /// 卡面背景色，默认白
  final Color backgroundColor;

  /// 卡面贴图，http(s) 开头走网络图，否则当作本地资源路径；为空则不显示
  final String? imageAsset;

  /// 卡面文字颜色，默认白
  final Color textColor;

  /// 卡片内容，暂为空，后续按需填充
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CardPainter(color: backgroundColor),
        child: ClipPath(
          clipper: _CardClipper(),
          child: Stack(
            children: [
              // 贴图铺满卡面，由 ClipPath 裁成斜切形状；支持网络地址与本地资源
              if (imageAsset != null)
                Positioned.fill(
                  child: imageAsset!.startsWith('http')
                      ? Image.network(
                          imageAsset!,
                          fit: BoxFit.cover,
                          // 加载失败（如离线）时留空，露出底色卡面
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        )
                      : Image.asset(imageAsset!, fit: BoxFit.cover),
                ),
              ?child,
              // 名称压在卡面右下角；右侧留出斜切量避免文字被裁
              Positioned(
                right: width * skewRatio + 12,
                bottom: 14,
                child: Text(
                  name,
                  // App 名用站酷庆科黄油体，与时钟的 Science Gothic 区分开
                  style: GoogleFonts.zcoolQingKeHuangYou(
                    textStyle: TextStyle(
                      fontSize: 20,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ],
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
  const _CardPainter({required this.color});

  /// 由 App 背景色决定卡面底色
  final Color color;

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
  }

  @override
  bool shouldRepaint(covariant _CardPainter oldDelegate) =>
      oldDelegate.color != color;
}
