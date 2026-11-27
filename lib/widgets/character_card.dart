import 'package:material_ui/material_ui.dart';

/// 单张角色卡片：带圆角的斜切卡面，内容由外部填入。
class CharacterCard extends StatelessWidget {
  const CharacterCard({super.key, this.child});

  /// 卡片内容，暂为空，后续按需填充
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 500,
      child: CustomPaint(
        painter: _CardPainter(),
        child: ClipPath(
          clipper: _CardClipper(),
          child: child ?? const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// 圆角半径
const _radius = 16.0;

/// 生成带圆角的斜切梯形：顶边窄且右移，四角倒圆角，painter 与 clipper 共用
Path _buildCardPath(Size size) {
  final inset = size.width * 0.18;
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
  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildCardPath(size);
    // 先画投影，再画白色卡面
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black54
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _CardPainter oldDelegate) => false;
}
