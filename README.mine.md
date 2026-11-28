# DLauncher 我的部署命令

本机专属操作手册，电视 IP 固定为 `192.168.1.107:5555`。通用说明见 `README.md`。

## 连接电视

通过局域网 ADB 连接电视，后续命令都靠这条连接执行：

```bash
# 连接电视
adb connect 192.168.1.107:5555

# 查看已连接设备，状态显示 device 才算连上
adb devices
```

> 首次连接若提示 `unauthorized`，需在电视端弹出的授权框里点允许。若提示 `connection refused`，确认电视已开启 ADB 调试并和电脑在同一局域网。

## 构建与安装

在项目根目录依次执行：

```bash
# 1. 打包 release APK（仅 armeabi-v7a）
flutter build apk --release

# 2. 安装到电视
adb -s 192.168.1.107:5555 install -r build/app/outputs/flutter-apk/app-release.apk

# 3. 手动拉起一次，让系统认识这个包
adb -s 192.168.1.107:5555 shell am start -n com.ts.launcher/.MainActivity

# 4. 设为默认桌面
adb -s 192.168.1.107:5555 shell cmd package set-home-activity com.ts.launcher/.MainActivity

# 5. 禁用小米桌面（必须在第 4 步之后）
adb -s 192.168.1.107:5555 shell pm disable-user --user 0 com.mitv.tvhome

# 6. 撤销操作：卸载本 App（不想用 DLauncher 时执行）
adb -s 192.168.1.107:5555 shell pm uninstall com.ts.launcher
```

> 第 5 步必须用包级禁用；组件级写法会报 `SecurityException`。第 6 步是**撤销操作**：卸载本 App（`com.ts.launcher`），只移除 DLauncher，不动系统预装的小米桌面；执行后按文末命令把默认桌面设回小米桌面即可。

## 验证

```bash
# 查看当前默认桌面，期望 com.ts.launcher/.MainActivity
adb -s 192.168.1.107:5555 shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME

# 按 HOME 键后查看前台窗口，期望 com.ts.launcher/.MainActivity
adb -s 192.168.1.107:5555 shell dumpsys window | findstr mCurrentFocus
```

## 恢复小米桌面

```bash
# 第 5 步禁用了小米桌面：重新启用
adb -s 192.168.1.107:5555 shell pm enable com.mitv.tvhome

adb -s 192.168.1.107:5555 shell cmd package set-home-activity com.mitv.tvhome/.MainActivityUserMode
adb -s 192.168.1.107:5555 shell reboot
```

> 第 6 步只是卸载本 App（撤销操作），小米桌面还在，卸载后按上面命令设回默认桌面即可恢复。不要禁用 `com.xiaomi.mitv.settings/.entry.FallbackHome`，那是开机兜底桌面。
