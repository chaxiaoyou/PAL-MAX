package com.toolnest.rulerratio.screen.ratio.utility

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Tells AlertJobService to stand down: a running app does its own
        // alert checks, and both running at once would double up.
        AlertBackground.appProcessAlive = true
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "NeedhamCapital/stocks_widget",
        ).setMethodCallHandler { call, result ->
            if (call.method == "update") {
                val payload = call.arguments as? String
                if (payload == null) {
                    result.error("bad_arguments", "JSON payload required", null)
                } else {
                    StocksWidgetProvider.saveSnapshot(this, payload)
                    result.success(null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Price alerts: permission, delivery, and the rule handover that lets
        // the periodic job run with the app closed. Written against the
        // platform APIs rather than a plugin — the app module already talks to
        // Android this way for the home-screen widget.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AlertBackground.CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "allowed" -> result.success(AlertNotifications.allowed(this))
                "request" -> requestNotificationPermission(result)
                "notify" -> {
                    val id = call.argument<Int>("id")
                    val title = call.argument<String>("title")
                    val body = call.argument<String>("body")
                    if (id == null || title == null || body == null) {
                        result.error(
                            "bad_arguments",
                            "id, title and body are required",
                            null,
                        )
                    } else {
                        AlertNotifications.show(this, id, title, body)
                        result.success(null)
                    }
                }

                "readRules" -> result.success(AlertBackground.rules(this))
                "syncRules" -> {
                    call.argument<String>("rules")?.let {
                        AlertBackground.saveRules(this, it)
                    }
                    result.success(
                        AlertBackground.schedule(
                            this,
                            call.argument<Boolean>("hasEnabled") ?: false,
                        ),
                    )
                }

                "setCallbackHandle" -> {
                    val handle = call.argument<Number>("handle")?.toLong()
                    if (handle == null || handle == 0L) {
                        result.error(
                            "bad_arguments",
                            "A non-zero callback handle is required",
                            null,
                        )
                    } else {
                        AlertBackground.saveCallbackHandle(this, handle)
                        result.success(null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    /**
     * Asks for POST_NOTIFICATIONS on Android 13+. Older releases have no
     * runtime permission, so the system setting is the final answer there.
     */
    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(AlertNotifications.allowed(this))
            return
        }
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.error(
                "in_progress",
                "A notification permission request is already running",
                null,
            )
            return
        }
        pendingPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_PERMISSION_REQUEST,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != NOTIFICATION_PERMISSION_REQUEST) return
        val result = pendingPermissionResult ?: return
        pendingPermissionResult = null
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        result.success(granted)
    }

    private companion object {
        const val NOTIFICATION_PERMISSION_REQUEST = 4711
    }
}
