package com.example.easymonitor

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.view.View
import android.app.PendingIntent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class EasyMonitorWidgetProvider : HomeWidgetProvider() {
    override fun onReceive(context: Context, intent: android.content.Intent) {
        try {
            Log.i("EasyMonitorWidget", "onReceive: ${intent.action}")
            super.onReceive(context, intent)
        } catch (e: Exception) {
            Log.e("EasyMonitorWidget", "onReceive failed: ${intent.action}", e)
        }
    }

    override fun onEnabled(context: Context) {
        Log.i("EasyMonitorWidget", "onEnabled")
        super.onEnabled(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        try {
            Log.i("EasyMonitorWidget", "onUpdate ids=${appWidgetIds.size}")
            val count = widgetData.getInt("item_count", 0)

            appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.easy_monitor_widget)
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                val rowIds = intArrayOf(R.id.row0, R.id.row1, R.id.row2, R.id.row3)
                val dotIds = intArrayOf(R.id.dot0, R.id.dot1, R.id.dot2, R.id.dot3)
                val nameIds = intArrayOf(R.id.name0, R.id.name1, R.id.name2, R.id.name3)

                for (i in 0 until 4) {
                    val rowId = rowIds[i]
                    val dotId = dotIds[i]
                    val nameId = nameIds[i]

                    if (i < count) {
                        val name = widgetData.getString("item_name_$i", "")
                        val status = widgetData.getInt("item_status_$i", 0)
                        views.setViewVisibility(rowId, View.VISIBLE)
                        views.setTextViewText(nameId, name)
                    views.setImageViewResource(dotId, statusDrawable(status))
                    } else {
                        views.setViewVisibility(rowId, View.GONE)
                    }
                }

                appWidgetManager.updateAppWidget(widgetId, views)
            }
        } catch (e: Exception) {
            Log.e("EasyMonitorWidget", "Widget update failed", e)
        }
    }

    private fun statusDrawable(status: Int): Int {
        return when (status) {
            1 -> R.drawable.status_green
            2 -> R.drawable.status_red
            3 -> R.drawable.status_yellow
            4 -> R.drawable.status_purple
            else -> R.drawable.status_unknown
        }
    }
}
