package com.example.quit

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Process
import android.provider.Settings
import android.app.usage.UsageStatsManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.time.LocalDate
import java.time.ZoneId
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val channelName = "athar/device_usage"
    private val socialPackages = setOf(
        "com.instagram.android",
        "com.zhiliaoapp.musically",
        "com.twitter.android",
        "com.facebook.katana",
        "com.snapchat.android",
        "com.google.android.youtube"
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasUsageAccess" -> result.success(hasUsageAccess())
                    "openUsageAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    "getTodayUsage" -> {
                        if (!hasUsageAccess()) {
                            result.error("USAGE_ACCESS_REQUIRED", "Usage access is not enabled", null)
                        } else {
                            result.success(readTodayUsage())
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun readTodayUsage(): Map<String, Any> {
        val start = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val end = System.currentTimeMillis()
        val manager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = manager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)
        val totalMillis = stats.sumOf { it.totalTimeInForeground.toLong() }
        val socialMillis = stats
            .filter { socialPackages.contains(it.packageName) }
            .sumOf { it.totalTimeInForeground.toLong() }
        val date = LocalDate.now(ZoneId.systemDefault()).toString()

        return mapOf(
            "date" to date,
            "screen_hours" to totalMillis / 3600000.0,
            "social_hours" to socialMillis / 3600000.0,
            // Android does not expose a true scroll counter; social usage is
            // used as a transparent approximation until an app integration exists.
            "scroll_minutes" to socialMillis / 60000.0
        )
    }
}
