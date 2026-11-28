package com.ts.launcher

import android.content.ComponentName
import android.content.Intent
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
                // 已确认小米电视设置包，直接拉起，不遍历、不试标准 Action
                val packageName = call.argument<String>("packageName")
                    ?.takeIf { it.isNotBlank() }
                    ?: "com.xiaomi.mitv.settings"
                val intent = packageManager.getLaunchIntentForPackage(packageName)
                if (intent == null) {
                    result.error("SETTINGS_NOT_FOUND", "No launch intent for $packageName", null)
                    return
                }
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}
