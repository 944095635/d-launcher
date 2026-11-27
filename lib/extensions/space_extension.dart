import 'package:material_ui/material_ui.dart';

/// 数值间距扩展：用数值直接生成横向/纵向间隔。
/// 例：10.horizontalSpace 等价于 SizedBox(width: 10)。
extension SpaceExtension on num {
  /// 纵向间隔，等价于 SizedBox(height: 数值)
  SizedBox get verticalSpace => SizedBox(height: toDouble());

  /// 横向间隔，等价于 SizedBox(width: 数值)
  SizedBox get horizontalSpace => SizedBox(width: toDouble());
}
