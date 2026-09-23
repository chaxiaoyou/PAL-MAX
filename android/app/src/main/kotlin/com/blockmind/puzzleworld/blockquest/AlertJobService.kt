package com.blockmind.puzzleworld.blockquest

import android.app.job.JobParameters
import android.app.job.JobService
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation

/**
 * Runs the alert check with the app closed.
 *
 * It starts a headless Flutter engine, hands the Dart entrypoint the stored
 * rules, and waits for the crossings to come back. All of the judgement —
 * what a crossing is, how to talk to the quote API — stays in Dart; this class
 * only schedules, stores and notifies.
 */
class AlertJobService : JobService() {
    private var engine: FlutterEngine? = null
    private val timeout = Handler(Looper.getMainLooper())
    private var timeoutTask: Runnable? = null
    private var completed = false

    override fun onStartJob(params: JobParameters): Boolean {
        // The running app evaluates alerts itself; a second evaluator would
        // announce the same crossing twice.
        if (AlertBackground.appProcessAlive) {
            return false
        }
        val handle = AlertBackground.callbackHandle(this)
        if (handle == 0L) {
            return false
        }

        // The engine has to exist before the callback handle can be resolved:
        // lookupCallbackInformation is a JNI call, and in a process that has
        // never hosted the app — which is exactly the case here — libflutter.so
        // is not loaded until a FlutterEngine has been created. Doing it the
        // other way round kills the service with UnsatisfiedLinkError.
        val engine = try {
            FlutterEngine(applicationContext)
        } catch (error: Throwable) {
            Log.e(TAG, "alert check could not start the Flutter engine", error)
            return false
        }
        val info = try {
            FlutterCallbackInformation.lookupCallbackInformation(handle)
        } catch (error: Throwable) {
            Log.e(TAG, "alert check could not resolve its callback", error)
            engine.destroy()
            return false
        }
        if (info == null) {
            engine.destroy()
            return false
        }
        Log.i(
            TAG,
            "running alert check: ${info.callbackLibraryPath}#${info.callbackName}",
        )
        this.engine = engine
        // The handler has to exist before the entrypoint runs, or the first
        // call from Dart races the registration.
        MethodChannel(engine.dartExecutor.binaryMessenger, AlertBackground.CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "readRules" -> result.success(AlertBackground.rules(this))
                    "finish" -> {
                        call.argument<String>("rules")?.let {
                            AlertBackground.saveRules(this, it)
                        }
                        for (note in notificationsFrom(call)) {
                            AlertNotifications.show(this, note.first, note.second, note.third)
                        }
                        result.success(null)
                        complete(params)
                    }

                    else -> result.notImplemented()
                }
            }
        engine.dartExecutor.executeDartEntrypoint(
            // Three arguments, not two. The two-argument constructor is
            // (pathToBundle, functionName) and leaves dartEntrypointLibrary
            // null, so passing the library path there silently drops it and the
            // engine cannot resolve the entrypoint:
            //   "Could not resolve main entrypoint function"
            DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                info.callbackLibraryPath,
                info.callbackName,
            ),
        )

        // A background engine that never answers must not wedge the job.
        val task = Runnable { complete(params) }
        timeoutTask = task
        timeout.postDelayed(task, TIMEOUT_MS)
        return true
    }

    override fun onStopJob(params: JobParameters): Boolean {
        releaseEngine()
        // Reschedule: the check never got to run.
        return true
    }

    private fun complete(params: JobParameters) {
        if (completed) return
        completed = true
        timeoutTask?.let { timeout.removeCallbacks(it) }
        timeoutTask = null
        releaseEngine()
        jobFinished(params, false)
    }

    private fun releaseEngine() {
        engine?.destroy()
        engine = null
    }

    private fun notificationsFrom(call: MethodCall): List<Triple<Int, String, String>> {
        val raw = call.argument<List<Any?>>("notifications") ?: return emptyList()
        val out = mutableListOf<Triple<Int, String, String>>()
        for (entry in raw) {
            val map = entry as? Map<*, *> ?: continue
            val id = (map["id"] as? Number)?.toInt() ?: continue
            val title = map["title"] as? String ?: continue
            val body = map["body"] as? String ?: continue
            out.add(Triple(id, title, body))
        }
        return out
    }

    private companion object {
        const val TIMEOUT_MS = 60_000L
        const val TAG = "AlertJobService"
    }
}
