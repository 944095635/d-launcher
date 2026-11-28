# DLauncher

电视桌面启动器。Flutter + GetX 负责界面，系统能力（拉起应用、切换 HDMI 信号源）放在原生 Android 层，通过 MethodChannel 桥接。

- 目标设备：小米电视 MiTV-MFTR0 / Android 11
- 架构：仅 `armeabi-v7a` （有需要可以自己修改 build.gradle.kts）
- 当前包名：`com.ts.launcher`（原因见下方「桌面接管」）

## 预览

![DLauncher 桌面预览](preview/image.jpg)

下文命令中的 `<TV_IP>` 为电视的 IP 地址，按实际替换（端口固定 `5555`）。

## 连接电视

通过局域网 ADB 连接电视，后续命令都靠这条连接执行：

```bash
# 连接电视（端口固定 5555）
adb connect <TV_IP>:5555

# 查看已连接设备，状态显示 device 才算连上
adb devices
```

> 首次连接若提示 `unauthorized`，需在电视端弹出的授权框里点允许。若提示 `connection refused`，确认电视已开启 ADB 调试并和电脑在同一局域网。

## 构建与安装

在项目根目录执行：

```bash
# 1. 打包 release APK
flutter build apk --release

# 2. 安装到电视（按实际设备地址修改 -s 参数）
adb -s <TV_IP>:5555 install -r build/app/outputs/flutter-apk/app-release.apk

# 3. 手动拉起一次，让系统认识这个包
adb -s <TV_IP>:5555 shell am start -n com.ts.launcher/.MainActivity

# 4. 设为默认桌面
adb -s <TV_IP>:5555 shell cmd package set-home-activity com.ts.launcher/.MainActivity

# 5. 禁用小米桌面（必须在第 4 步之后）
adb -s <TV_IP>:5555 shell pm disable-user --user 0 com.mitv.tvhome

# 6. 撤销操作：卸载本 App（不想用 DLauncher 时执行）
adb -s <TV_IP>:5555 shell pm uninstall com.ts.launcher
```

> 第 5 步只能用**包级**禁用（`pm disable-user --user 0 包名`）。组件级写法 `pm disable-user com.mitv.tvhome/.MainActivityUserMode` 会被系统拒绝（`SecurityException`）。第 6 步是**撤销操作**：卸载本 App（`com.ts.launcher`），只移除 DLauncher，不动系统预装的小米桌面；执行后按文末命令把默认桌面设回小米桌面即可。

## 桌面接管

小米电视锁定了默认桌面，第三方应用必须伪装成系统白名单里的包名，才能接管 HOME 键。

- 系统白名单由固件云控下发，可用 `logcat -d -s MitvConfigParser | findstr "White"` 查看。
- 标志位含 HOME 位（值为 4）的才允许作为桌面。日志中的标志值只有三种含该位：`511`（桌面应用）、`7` 与 `3583`（均为小米系统组件，不适合当桌面包名）。
- 当前使用的 `com.ts.launcher` 在白名单内，标志位 `511`。

### 白名单候选包名（标志 511，均已确认未被占用）

| 包名 | 语义 | 推荐度 |
| --- | --- | --- |
| `com.ts.launcher` | 通用桌面 | ✅ 已验证成功，首选 |
| `com.bytv.launcher` | 第三方桌面 | ✅ 备选 |
| `com.thunderstone.idun` | 雷电桌面 | ✅ 备选 |
| `com.tongshi.home` | 同视桌面 | ✅ 备选 |
| `com.meituan.retail.launcher` | 美团桌面 | ✅ 备选 |
| `com.bytv.launcher.special` | 桌面（特殊版） | ⚠️ 可用但语义特殊 |
| `com.thunderstone.idun.dev` | 桌面（开发版） | ⚠️ 可用但语义特殊 |
| `com.gochinatv.ad` | 高斯贝尔 | ⚠️ 语义不像桌面 |
| `com.mitv.care` / `com.mi.receiver` / `com.xiaomi.mitvshow` | 小米组件 | ⚠️ 系统语义，不推荐 |
| `com.xiaomi.smoke` / `.smoke.test` / `.saber.test` / `.voicecontrol.demo...` | 测试 / demo 包 | 🚫 不建议 |

> 白名单由小米云控下发，条目可能被删除。若接管突然失效，第一时间重抓日志确认包名仍在名单中。

**改包名必须同步修改四处**，否则 Manifest 中的相对类名 `.MainActivity` 解析不到实际类，启动即崩溃：

| 位置 | 文件 |
| --- | --- |
| `namespace` | `android/app/build.gradle.kts` |
| `applicationId` | `android/app/build.gradle.kts` |
| 源码目录 | `android/app/src/main/kotlin/com/ts/launcher/` |
| `package` 声明 | `MainActivity.kt` 第一行 |

> MethodChannel 名 `com.dlauncher/platform` 是 Dart 与原生的内部约定，与包名无关，不要跟着改。

## 验证

```bash
# 查看当前默认桌面
adb -s <TV_IP>:5555 shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME

# 按 HOME 键后查看前台窗口
adb -s <TV_IP>:5555 shell dumpsys window | findstr mCurrentFocus
```

期望结果均为 `com.ts.launcher/.MainActivity`。

## 恢复小米桌面

```bash
# 第 5 步禁用了小米桌面：重新启用
adb -s <TV_IP>:5555 shell pm enable com.mitv.tvhome

adb -s <TV_IP>:5555 shell cmd package set-home-activity com.mitv.tvhome/.MainActivityUserMode
adb -s <TV_IP>:5555 shell reboot
```

> 第 6 步只是卸载本 App（撤销操作），小米桌面还在，卸载后按上面命令设回默认桌面即可恢复。`com.xiaomi.mitv.settings/.entry.FallbackHome` 是系统开机兜底桌面，不要禁用，否则开机可能进不去桌面。
