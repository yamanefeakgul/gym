package com.gympulse.gymapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class WaterAppWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_ADD_WATER) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val todayKey = "flutter.gym_water_" + getTodayString()
            val currentAmount = prefs.getInt(todayKey, 0)
            val newAmount = currentAmount + 250
            prefs.edit().putInt(todayKey, newAmount).apply()

            updateAllWidgets(context)
        }
    }

    companion object {
        const val ACTION_ADD_WATER = "com.gympulse.gymapp.ADD_WATER_250"

        private fun getTodayString(): String {
            val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            return sdf.format(Date())
        }

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val todayKey = "flutter.gym_water_" + getTodayString()
            val waterMl = prefs.getInt(todayKey, 0)

            val views = RemoteViews(context.packageName, R.layout.water_app_widget)
            views.setTextViewText(R.id.water_amount_text, "$waterMl ml")

            // +250ml Buton Tıklama Aksiyonu
            val addIntent = Intent(context, WaterAppWidget::class.java).apply {
                action = ACTION_ADD_WATER
            }
            val pendingAddIntent = PendingIntent.getBroadcast(
                context, 201, addIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_add_water_250, pendingAddIntent)

            // Karta Tıklayınca Uygulamayı Aç
            val openAppIntent = Intent(context, MainActivity::class.java)
            val pendingOpenIntent = PendingIntent.getActivity(
                context, 202, openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.water_widget_root, pendingOpenIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, WaterAppWidget::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (widgetId in allWidgetIds) {
                updateAppWidget(context, appWidgetManager, widgetId)
            }
        }
    }
}
