package com.ts.launcher

import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.dlauncher/platform"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handleCall(call, result) }
    }

    /// 按包名拉起应用：包名来自 AppInfo，未安装时返回错误由 Flutter 侧处理
    private fun handleCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "launchApp" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName.isNullOrBlank()) {
                    result.error("INVALID_PACKAGE", "packageName is required", null)
                    return
                }
                val intent = packageManager.getLaunchIntentForPackage(packageName)
                if (intent == null) {
                    result.error("APP_NOT_FOUND", "No launch intent for $packageName", null)
                    return
                }
                // 目标 task 还在后台时原样切回前台（恢复栈顶），避免重新走启动页
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
                startActivity(intent)
                result.success(true)
            }
            "launchIntent" -> {
                val component = call.argument<String>("component")
                if (component.isNullOrBlank()) {
                    result.error("INVALID_COMPONENT", "component is required", null)
                    return
                }
                val intent = Intent()
                call.argument<String>("action")?.takeIf { it.isNotBlank() }?.let {
                    intent.action = it
                }
                intent.component = ComponentName.unflattenFromString(component)
                if (intent.component == null) {
                    result.error("INVALID_COMPONENT", "Cannot parse component $component", null)
                    return
                }
                // 信号源切换等入口依赖 int 参数，如 HDMI3 的 input=25
                val extras = call.argument<Any>("intExtras") as? Map<*, *>
                extras?.forEach { (key, value) ->
                    if (key is String && value is Int) intent.putExtra(key, value)
                }
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
                startActivity(intent)
                result.success(true)
            }
            "openSettings" -> {
                // 不同设备的设置包名不同：小米电视、原生 Android TV、普通 Android 各用自己的包。
                // 没有可靠区分型号的办法，逐个探测候选包，命中哪个起哪个，全部落空再试标准 Action。
                // 显式传入的包名（若配置）优先，便于覆盖特殊机型。
                val candidates = mutableListOf<String>()
                call.argument<String>("packageName")
                    ?.takeIf { it.isNotBlank() }
                    ?.let { candidates.add(it) }
                candidates.addAll(
                    listOf(
                        "com.xiaomi.mitv.settings", // 小米电视
                        "com.android.tv.settings",  // 原生 Android TV（ATV / Google TV）
                        "com.android.settings",     // 普通 Android 设置
                    )
                )

                var launched = false
                for (pkg in candidates.distinct()) {
                    val intent = packageManager.getLaunchIntentForPackage(pkg)
                        ?: continue // 该设备没有这个包，试下一个
                    try {
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        launched = true
                        break
                    } catch (ignored: ActivityNotFoundException) {
                        // 包存在但没有可用入口，继续试下一个候选
                    }
                }

                // 候选包都拉不起时，退回标准设置 Action，让系统自己解析入口
                if (!launched) {
                    val fallback = Intent(Settings.ACTION_SETTINGS)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    if (fallback.resolveActivity(packageManager) != null) {
                        try {
                            startActivity(fallback)
                            launched = true
                        } catch (ignored: ActivityNotFoundException) {
                            // 标准 Action 也无入口，落到下面的失败分支
                        }
                    }
                }

                if (launched) {
                    result.success(true)
                } else {
                    result.error("SETTINGS_NOT_FOUND", "No usable settings entry", null)
                }
            }
            "getInstalledApps" -> {
                // 只返回有启动入口的应用，避免把无界面的系统服务列进设置页
                val pm = packageManager
                val apps = pm.getInstalledPackages(0).mapNotNull { info ->
                    if (pm.getLaunchIntentForPackage(info.packageName) == null) {
                        return@mapNotNull null
                    }
                    val label = info.applicationInfo?.loadLabel(pm)?.toString().orEmpty()
                    if (label.isBlank()) return@mapNotNull null
                    mapOf("name" to label, "packageName" to info.packageName)
                }
                result.success(apps)
            }
            else -> result.notImplemented()
        }
    }
}
