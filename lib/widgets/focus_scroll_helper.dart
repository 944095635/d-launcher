import 'package:material_ui/material_ui.dart';

/// 遥控器焦点跟随列表滚动：切焦点后把目标项滚入视野。
///
/// ListView 只构建可视区附近的项，目标项可能尚未生成，因此先按估算高度粗跳，
/// 待该项构建后再用 GlobalKey 精确定位。各页面持有一个实例，dispose 时释放。
class FocusScrollHelper {
  /// [estimatedItemHeight] 用于目标项未构建时的粗跳，取接近单项实际高度的值即可
  FocusScrollHelper({required this.estimatedItemHeight});

  final ScrollController controller = ScrollController();
  final Map<int, GlobalKey> _keys = {};

  /// 粗跳时用的单项高度估算
  final double estimatedItemHeight;

  /// 给列表项绑定 key，页面 itemBuilder 中传入
  GlobalKey keyOf(int index) => _keys.putIfAbsent(index, () => GlobalKey());

  /// 焦点变化后调用；先等本帧布局完成，再判断是否需要滚动
  void ensureVisible(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = keyOf(index).currentContext;
      if (ctx != null && ctx.mounted) {
        _exact(ctx);
        return;
      }
      // 目标项还没被 ListView 构建：先粗跳让它进入构建范围，下一帧再精确定位
      if (!controller.hasClients) return;
      final position = controller.position;
      if (!position.hasContentDimensions || !position.hasViewportDimension) {
        return;
      }
      controller.jumpTo(
        (index * estimatedItemHeight).clamp(0.0, position.maxScrollExtent),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final built = keyOf(index).currentContext;
        if (built != null && built.mounted) _exact(built);
      });
    });
  }

  void _exact(BuildContext context) {
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  void dispose() => controller.dispose();
}
