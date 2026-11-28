/// 原生层返回的已安装应用摘要，供设置页点选包名。
class InstalledApp {
  const InstalledApp({required this.name, required this.packageName});

  final String name;
  final String packageName;

  factory InstalledApp.fromJson(Map<dynamic, dynamic> json) {
    return InstalledApp(
      name: json['name'] as String? ?? '',
      packageName: json['packageName'] as String? ?? '',
    );
  }
}
