package com.gympulse.gymapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import kotlin.random.Random

class QuoteAppWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private val quotes = arrayOf(
            Pair("Stay Hard! Zihnin pes etmek istediğinde, kapasitenin sadece %40'ını kullanmışsındır.", "David Goggins"),
            Pair("Aynaya bak ve kendine doğruyu söyle. Kimse seni kurtarmaya gelmeyecek!", "David Goggins"),
            Pair("Disiplin, canın istemediği anlarda bile yapman gerekeni yapmaktır.", "David Goggins"),
            Pair("Acı geçicidir. Pes etmek ise sonsuza kadar sürer.", "David Goggins"),
            Pair("Konfor alanı hayallerin öldüğü yerdir. Kendini zorla!", "David Goggins"),
            Pair("Bugün yapmadığın antrenmanın telafisi yarın olmaz. Şimdi kalk ve başla!", "David Goggins"),
            Pair("Ruhunu zırh gibi sertleştir. Demir bükülür ama sen bükülmezsin.", "David Goggins"),
            Pair("Bahane üretmek yerine ter akıt. Terin sesi bahanelerden daha gür çıkar.", "David Goggins")
        )

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val randomIndex = Random.nextInt(quotes.size)
            val selected = quotes[randomIndex]

            val views = RemoteViews(context.packageName, R.layout.quote_app_widget)
            views.setTextViewText(R.id.widget_quote_text, selected.first)
            views.setTextViewText(R.id.widget_quote_author, "— " + selected.second)

            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 1, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.quote_widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, QuoteAppWidget::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (widgetId in allWidgetIds) {
                updateAppWidget(context, appWidgetManager, widgetId)
            }
        }
    }
}
