package com.example.pal_max

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

/**
 * Home-screen widget that mirrors the in-app watchlist grid. The Flutter side
 * pushes the latest quote snapshot through `pal_max/stocks_widget` whenever a
 * refresh succeeds; this provider renders that snapshot with RemoteViews so the
 * widget itself does not need its own network/authentication stack.
 */
class StocksWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle?,
    ) {
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    companion object {
        private const val PREFS = "stocks_widget"
        private const val DATA_KEY = "snapshot"
        private const val MAX_CELLS = 8

        fun saveSnapshot(context: Context, payload: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putString(DATA_KEY, payload)
                .apply()
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                android.content.ComponentName(context, StocksWidgetProvider::class.java),
            )
            for (id in ids) {
                updateWidget(context, manager, id)
            }
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val views = RemoteViews(context.packageName, R.layout.stocks_widget)
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val raw = prefs.getString(DATA_KEY, null)

            val openIntent = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, openIntent)

            val dark = try {
                raw != null && JSONObject(raw).optBoolean("dark", false)
            } catch (_: Exception) {
                false
            }
            applyTheme(views, dark)

            if (raw.isNullOrEmpty()) {
                views.setViewVisibility(R.id.widget_empty, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.widget_grid, android.view.View.GONE)
            } else {
                try {
                    val snapshot = JSONObject(raw)
                    val quotes = snapshot.optJSONArray("quotes") ?: JSONArray()
                    for (i in 0 until MAX_CELLS) {
                        val cell = cellId(i)
                        if (i < quotes.length()) {
                            val quote = quotes.getJSONObject(i)
                            views.setViewVisibility(cell.layout, android.view.View.VISIBLE)
                            views.setTextViewText(cell.symbol, quote.optString("symbol", ""))
                            views.setTextViewText(cell.name, quote.optString("name", ""))
                            views.setTextViewText(
                                cell.price,
                                quote.optString("priceText", "--"),
                            )
                            views.setTextViewText(
                                cell.percent,
                                quote.optString("percentText", ""),
                            )
                            views.setTextViewText(
                                cell.change,
                                quote.optString("changeText", ""),
                            )
                            val color = if (quote.optDouble("change", 0.0) >= 0) {
                                if (dark) DARK_UP else LIGHT_UP
                            } else {
                                if (dark) DARK_DOWN else LIGHT_DOWN
                            }
                            views.setTextColor(cell.percent, color)
                            views.setTextColor(cell.change, color)
                        } else {
                            views.setViewVisibility(cell.layout, android.view.View.GONE)
                        }
                    }
                    views.setViewVisibility(R.id.widget_empty, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_grid, android.view.View.VISIBLE)
                    val updatedAt = snapshot.optLong("updatedAt", 0L)
                    views.setTextViewText(
                        R.id.widget_subtitle,
                        if (updatedAt > 0) {
                            "Last fetch: ${formatTime(updatedAt)}"
                        } else {
                            ""
                        },
                    )
                } catch (_: Exception) {
                    views.setViewVisibility(R.id.widget_empty, android.view.View.VISIBLE)
                    views.setViewVisibility(R.id.widget_grid, android.view.View.GONE)
                }
            }
            manager.updateAppWidget(appWidgetId, views)
        }

        private fun applyTheme(views: RemoteViews, dark: Boolean) {
            val bg = if (dark) DARK_BG else LIGHT_BG
            val card = if (dark) DARK_CARD else LIGHT_CARD
            val title = if (dark) DARK_TEXT else LIGHT_TEXT
            val muted = if (dark) DARK_MUTED else LIGHT_MUTED
            views.setInt(R.id.widget_root, "setBackgroundColor", bg)
            views.setTextColor(R.id.widget_title, title)
            views.setTextColor(R.id.widget_subtitle, muted)
            views.setTextColor(R.id.widget_empty, muted)
            for (i in 0 until MAX_CELLS) {
                val cell = cellId(i)
                views.setInt(cell.layout, "setBackgroundColor", card)
                views.setTextColor(cell.symbol, title)
                views.setTextColor(cell.name, muted)
                views.setTextColor(cell.price, title)
            }
        }

        private fun cellId(index: Int): CellIds {
            val symbol = when (index) {
                0 -> R.id.widget_symbol_0
                1 -> R.id.widget_symbol_1
                2 -> R.id.widget_symbol_2
                3 -> R.id.widget_symbol_3
                4 -> R.id.widget_symbol_4
                5 -> R.id.widget_symbol_5
                6 -> R.id.widget_symbol_6
                else -> R.id.widget_symbol_7
            }
            val name = when (index) {
                0 -> R.id.widget_name_0
                1 -> R.id.widget_name_1
                2 -> R.id.widget_name_2
                3 -> R.id.widget_name_3
                4 -> R.id.widget_name_4
                5 -> R.id.widget_name_5
                6 -> R.id.widget_name_6
                else -> R.id.widget_name_7
            }
            val price = when (index) {
                0 -> R.id.widget_price_0
                1 -> R.id.widget_price_1
                2 -> R.id.widget_price_2
                3 -> R.id.widget_price_3
                4 -> R.id.widget_price_4
                5 -> R.id.widget_price_5
                6 -> R.id.widget_price_6
                else -> R.id.widget_price_7
            }
            val percent = when (index) {
                0 -> R.id.widget_percent_0
                1 -> R.id.widget_percent_1
                2 -> R.id.widget_percent_2
                3 -> R.id.widget_percent_3
                4 -> R.id.widget_percent_4
                5 -> R.id.widget_percent_5
                6 -> R.id.widget_percent_6
                else -> R.id.widget_percent_7
            }
            val change = when (index) {
                0 -> R.id.widget_change_0
                1 -> R.id.widget_change_1
                2 -> R.id.widget_change_2
                3 -> R.id.widget_change_3
                4 -> R.id.widget_change_4
                5 -> R.id.widget_change_5
                6 -> R.id.widget_change_6
                else -> R.id.widget_change_7
            }
            val layout = when (index) {
                0 -> R.id.widget_cell_0
                1 -> R.id.widget_cell_1
                2 -> R.id.widget_cell_2
                3 -> R.id.widget_cell_3
                4 -> R.id.widget_cell_4
                5 -> R.id.widget_cell_5
                6 -> R.id.widget_cell_6
                else -> R.id.widget_cell_7
            }
            return CellIds(layout, symbol, name, price, percent, change)
        }

        private fun formatTime(epochMillis: Long): String {
            val date = java.util.Date(epochMillis)
            return String.format(Locale.getDefault(), "%tR", date)
        }

        private val LIGHT_BG = Color.rgb(0xFC, 0xFD, 0xF6)
        private val LIGHT_CARD = Color.rgb(0xFF, 0xFF, 0xFF)
        private val LIGHT_TEXT = Color.rgb(0x1A, 0x1C, 0x18)
        private val LIGHT_MUTED = Color.rgb(0x6E, 0x6E, 0x6E)
        private val LIGHT_UP = Color.rgb(0x00, 0x99, 0x00)
        private val LIGHT_DOWN = Color.rgb(0xE5, 0x5B, 0x5B)
        private val DARK_BG = Color.rgb(0x1A, 0x1C, 0x18)
        private val DARK_CARD = Color.rgb(0x1D, 0x1D, 0x1D)
        private val DARK_TEXT = Color.rgb(0xE2, 0xE3, 0xDD)
        private val DARK_MUTED = Color.rgb(0x8F, 0x96, 0x8C)
        private val DARK_UP = Color.rgb(0xCC, 0xFF, 0x66)
        private val DARK_DOWN = Color.rgb(0xFF, 0x66, 0x66)
    }
}

private data class CellIds(
    val layout: Int,
    val symbol: Int,
    val name: Int,
    val price: Int,
    val percent: Int,
    val change: Int,
)
