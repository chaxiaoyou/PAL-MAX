package com.example.pal_max

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "pal_max/stocks_widget",
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
    }
}
