package com.gympulse.gymapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews

class CardioAppWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        val serviceIntent = Intent(context, CardioTrackingService::class.java)

        when (action) {
            ACTION_TOGGLE -> {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val isRunning = prefs.getBoolean("flutter.cardio_is_running", false)
                val mode = prefs.getString("flutter.cardio_mode", "Koşu") ?: "Koşu"

                if (isRunning) {
                    serviceIntent.action = CardioTrackingService.ACTION_STOP
                    context.startService(serviceIntent)
                } else {
                    serviceIntent.action = CardioTrackingService.ACTION_START
                    serviceIntent.putExtra("mode", mode)
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                }
            }
            ACTION_SELECT_WALK -> {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                prefs.edit().putString("flutter.cardio_mode", "Yürüyüş").apply()
                serviceIntent.action = CardioTrackingService.ACTION_SET_MODE
                serviceIntent.putExtra("mode", "Yürüyüş")
                context.startService(serviceIntent)
                updateAllWidgets(context)
            }
            ACTION_SELECT_RUN -> {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                prefs.edit().putString("flutter.cardio_mode", "Koşu").apply()
                serviceIntent.action = CardioTrackingService.ACTION_SET_MODE
                serviceIntent.putExtra("mode", "Koşu")
                context.startService(serviceIntent)
                updateAllWidgets(context)
            }
        }
    }

    companion object {
        const val ACTION_TOGGLE = "com.gympulse.gymapp.CARDIO_WIDGET_TOGGLE"
        const val ACTION_SELECT_WALK = "com.gympulse.gymapp.CARDIO_SELECT_WALK"
        const val ACTION_SELECT_RUN = "com.gympulse.gymapp.CARDIO_SELECT_RUN"

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isRunning = prefs.getBoolean("flutter.cardio_is_running", false)
            val mode = prefs.getString("flutter.cardio_mode", "Koşu") ?: "Koşu"
            val seconds = prefs.getInt("flutter.cardio_seconds", 0)
            val speed = prefs.getFloat("flutter.cardio_speed", 0.0f)

            val hours = seconds / 3600
            val mins = (seconds % 3600) / 60
            val secs = seconds % 60
            val timeStr = String.format("%02d:%02d:%02d", hours, mins, secs)

            val views = RemoteViews(context.packageName, R.layout.cardio_app_widget)
            views.setTextViewText(R.id.cardio_timer_text, timeStr)
            views.setTextViewText(R.id.cardio_speed_text, String.format("%.1f km/h", speed))
            views.setTextViewText(R.id.cardio_status_badge, if (isRunning) "CANLI TAKİP • $mode" else "HAZIR • $mode")

            if (isRunning) {
                views.setTextViewText(R.id.cardio_toggle_text, "⏹ DURDUR")
                views.setInt(R.id.btn_cardio_toggle, "setBackgroundColor", Color.parseColor("#EF4444"))
            } else {
                views.setTextViewText(R.id.cardio_toggle_text, "▶ BAŞLAT")
                views.setInt(R.id.btn_cardio_toggle, "setBackgroundColor", Color.parseColor("#00E676"))
            }

            // Aksiyon Intentleri
            val toggleIntent = Intent(context, CardioAppWidget::class.java).apply { action = ACTION_TOGGLE }
            val pendingToggle = PendingIntent.getBroadcast(context, 301, toggleIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.btn_cardio_toggle, pendingToggle)

            val walkIntent = Intent(context, CardioAppWidget::class.java).apply { action = ACTION_SELECT_WALK }
            val pendingWalk = PendingIntent.getBroadcast(context, 302, walkIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.btn_mode_walk, pendingWalk)

            val runIntent = Intent(context, CardioAppWidget::class.java).apply { action = ACTION_SELECT_RUN }
            val pendingRun = PendingIntent.getBroadcast(context, 303, runIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.btn_mode_run, pendingRun)

            // Uygulamayı aç
            val openApp = Intent(context, MainActivity::class.java)
            val pendingOpen = PendingIntent.getActivity(context, 304, openApp, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.cardio_widget_root, pendingOpen)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, CardioAppWidget::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (widgetId in allWidgetIds) {
                updateAppWidget(context, appWidgetManager, widgetId)
            }
        }
    }
}
