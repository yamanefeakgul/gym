package com.gympulse.gymapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class StreakAppWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val profileStr = prefs.getString("flutter.gym_user_profile_data", null)

            var streakCount = 0
            var activityCalendar = JSONObject()

            if (profileStr != null) {
                try {
                    val json = JSONObject(profileStr)
                    streakCount = json.optInt("streakDays", 0)
                    activityCalendar = json.optJSONObject("activityCalendar") ?: JSONObject()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            val views = RemoteViews(context.packageName, R.layout.streak_app_widget)
            views.setTextViewText(R.id.widget_streak_count, "$streakCount GÜN")
            views.setTextViewText(R.id.widget_flame_icon, if (streakCount > 0) "🔥" else "⚪")

            // 7 Günlük Mini Takvim Doldurma
            val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val dayViewIds = arrayOf(
                R.id.w_day_1, R.id.w_day_2, R.id.w_day_3, R.id.w_day_4,
                R.id.w_day_5, R.id.w_day_6, R.id.w_day_7
            )

            val cal = Calendar.getInstance()
            for (i in 6 downTo 0) {
                val dayCal = Calendar.getInstance()
                dayCal.add(Calendar.DAY_OF_YEAR, -i)
                val dateKey = sdf.format(dayCal.time)
                val status = activityCalendar.optString(dateKey, "")

                val targetViewId = dayViewIds[6 - i]
                when (status) {
                    "completed" -> views.setTextViewText(targetViewId, "🔥")
                    "rest" -> views.setTextViewText(targetViewId, "❄️")
                    else -> views.setTextViewText(targetViewId, "•")
                }
            }

            // Widget'a tıklandığında uygulamayı aç
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, StreakAppWidget::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (widgetId in allWidgetIds) {
                updateAppWidget(context, appWidgetManager, widgetId)
            }
        }
    }
}
