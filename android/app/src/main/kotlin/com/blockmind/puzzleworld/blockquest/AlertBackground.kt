package com.blockmind.puzzleworld.blockquest

import android.app.job.JobInfo
import android.app.job.JobScheduler
import android.content.ComponentName
import android.content.Context

/**
 * What Android needs to keep checking price alerts while the app is closed.
 *
 * The rule payload is produced and consumed by Dart and stored here as an inert
 * string: deciding what a crossing is stays in one language, so the background
 * check cannot drift away from what the app does.
 */
object AlertBackground {
    const val CHANNEL = "NeedhamCapital/alerts"

    private const val PREFS = "alert_background"
    private const val KEY_RULES = "rules"
    private const val KEY_HANDLE = "callback_handle"
    private const val JOB_ID = 8801
    private const val PERIOD_MINUTES = 15L

    /**
     * True while the app process is alive. The periodic job defers to the
     * running app: two evaluators would double up on notifications. Because
     * this is a process-wide flag, a job in a fresh process sees false.
     */
    @Volatile
    var appProcessAlive = false

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun rules(context: Context): String? =
        prefs(context).getString(KEY_RULES, null)

    fun saveRules(context: Context, json: String) {
        prefs(context).edit().putString(KEY_RULES, json).apply()
    }

    fun callbackHandle(context: Context): Long =
        prefs(context).getLong(KEY_HANDLE, 0L)

    fun saveCallbackHandle(context: Context, handle: Long) {
        prefs(context).edit().putLong(KEY_HANDLE, handle).apply()
    }

    /**
     * Whether Android runs the check while the app is closed.
     *
     * The engine resolves the Dart entrypoint with the three-argument
     * DartEntrypoint (see AlertJobService); with the two-argument form the
     * library name is dropped and the engine fails with "Could not resolve main
     * entrypoint function". Keep this false only if that path breaks again, so
     * the app stops spending a wakeup every 15 minutes on a check that cannot
     * run.
     */
    const val BACKGROUND_CHECK_SUPPORTED = true

    /** Reschedules the periodic job. Returns whether it is actually scheduled. */
    fun schedule(context: Context, enabled: Boolean): Boolean {
        val scheduler =
            context.getSystemService(JobScheduler::class.java) ?: return false
        scheduler.cancel(JOB_ID)
        if (!enabled) return false
        if (!BACKGROUND_CHECK_SUPPORTED) return false
        val info = JobInfo.Builder(
            JOB_ID,
            ComponentName(context, AlertJobService::class.java),
        )
            .setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY)
            // The platform floor for periodic work; Doze can push it later.
            .setPeriodic(PERIOD_MINUTES * 60_000L)
            .setPersisted(true)
            .build()
        scheduler.schedule(info)
        return true
    }
}
