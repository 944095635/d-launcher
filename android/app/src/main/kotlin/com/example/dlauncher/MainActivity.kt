package com.example.dlauncher

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
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}
