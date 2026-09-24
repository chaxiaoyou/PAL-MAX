package com.toolnest.rulerratio.screen.ratio.utility

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Posts price-alert notifications.
 *
 * Shared by the running app and the background job so a crossing reads the same
 * whichever one found it, and so there is one place that knows the channel.
 */
object AlertNotifications {
    private const val CHANNEL_ID = "price_alerts"

    /** Whether the system would actually deliver a notification right now. */
    fun allowed(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return true
        val manager = context.getSystemService(NotificationManager::class.java)
        return manager?.areNotificationsEnabled() ?: true
    }

    fun show(context: Context, id: Int, title: String, body: String) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Price alerts",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description =
                    "Fires when a watched price crosses the level you set."
            }
            manager.createNotificationChannel(channel)
        }
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        val notification = builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()
        manager.notify(id, notification)
    }
}
