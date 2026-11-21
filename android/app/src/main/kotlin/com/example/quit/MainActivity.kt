package com.example.quit

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Process
import android.provider.Settings
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.pm.PackageManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.temporal.ChronoUnit
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
                    "getAppUsage" -> {
                        if (!hasUsageAccess()) {
                            result.error("USAGE_ACCESS_REQUIRED", "Usage access is not enabled", null)
                        } else {
                            val days = (call.argument<Int>("days") ?: 7).coerceIn(1, 14)
                            result.success(readAppUsage(days))
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

    /** Per app and local day: foreground minutes, total and per hour (contracts/android-usage-channel.md). */
    private fun readAppUsage(days: Int): List<Map<String, Any>> {
        val zone = ZoneId.systemDefault()
        val start = LocalDate.now(zone).minusDays((days - 1).toLong())
            .atStartOfDay(zone).toInstant().toEpochMilli()
        val end = System.currentTimeMillis()
        val manager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val excluded = setOfNotNull(packageName, defaultLauncher(), "com.android.systemui")

        val buckets = HashMap<Pair<LocalDate, String>, DoubleArray>()
        fun add(pkg: String, from: Long, to: Long) {
            var t = from
            while (t < to) { // split the session at every hour (and so at midnight)
                val at = Instant.ofEpochMilli(t).atZone(zone)
                val nextHour = at.truncatedTo(ChronoUnit.HOURS).plusHours(1).toInstant().toEpochMilli()
                val sliceEnd = minOf(to, nextHour)
                buckets.getOrPut(at.toLocalDate() to pkg) { DoubleArray(24) }[at.hour] +=
                    (sliceEnd - t) / 60000.0
                t = sliceEnd
            }
        }

        val openSince = HashMap<String, Long>()
        val events = manager.queryEvents(start, end)
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName ?: continue
            if (pkg in excluded) continue
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> openSince.putIfAbsent(pkg, event.timeStamp)
                UsageEvents.Event.ACTIVITY_PAUSED, UsageEvents.Event.ACTIVITY_STOPPED ->
                    openSince.remove(pkg)?.let { add(pkg, it, event.timeStamp) }
            }
        }
        openSince.forEach { (pkg, since) -> add(pkg, since, end) } // still in use

        val labels = HashMap<String, String>()
        return buckets.mapNotNull { (key, hourly) ->
            val minutes = hourly.sum()
            if (minutes <= 0) return@mapNotNull null
            mapOf(
                "date" to key.first.toString(),
                "package" to key.second,
                "label" to labels.getOrPut(key.second) { appLabel(key.second) },
                "minutes" to minutes,
                "hourly" to hourly.toList()
            )
        }
    }

    private fun appLabel(pkg: String): String = try {
        packageManager.getApplicationLabel(packageManager.getApplicationInfo(pkg, 0)).toString()
    } catch (e: PackageManager.NameNotFoundException) {
        pkg
    }

    private fun defaultLauncher(): String? = packageManager.resolveActivity(
        Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME),
        PackageManager.MATCH_DEFAULT_ONLY
    )?.activityInfo?.packageName

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
