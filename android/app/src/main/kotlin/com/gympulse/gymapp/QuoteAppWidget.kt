package com.gympulse.gymapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import kotlin.random.Random

class QuoteAppWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        data class MotivationQuote(
            val quote: String,
            val author: String,
            val isAtaturk: Boolean = false
        )

        private val quotes = arrayOf(
            // 🇹🇷 Mustafa Kemal Atatürk Sözleri (Yeşil - Sarı Özel Renk)
            MotivationQuote(
                "Ben sporcunun zeki, çevik ve aynı zamanda ahlaklısını severim.",
                "Mustafa Kemal Atatürk",
                isAtaturk = true
            ),
            MotivationQuote(
                "Muhtaç olduğun kudret, damarlarındaki asil kanda mevcuttur!",
                "Mustafa Kemal Atatürk",
                isAtaturk = true
            ),
            MotivationQuote(
                "Zafer, 'Zafer benimdir' diyebilenindir. Başarı ise, 'Başaracağım' diye başlayanın!",
                "Mustafa Kemal Atatürk",
                isAtaturk = true
            ),
            MotivationQuote(
                "Sağlam kafa, sağlam vücutta bulunur.",
                "Mustafa Kemal Atatürk",
                isAtaturk = true
            ),
            MotivationQuote(
                "Dinlenmemek üzere yürümeye karar verenler, asla ve asla yorulmazlar.",
                "Mustafa Kemal Atatürk",
                isAtaturk = true
            ),

            // ⚡ Efsanevi Sporcu ve Düşünür Sözleri
            MotivationQuote(
                "Son 3-4 tekrar kasın büyümesini sağlar. Şampiyonları diğerlerinden ayıran o acı eşiğidir.",
                "Arnold Schwarzenegger"
            ),
            MotivationQuote(
                "Günün her dakikasından nefret ettim ama 'Vazgeçme' dedim. Şimdi acı çek ve ömrünün kalanını şampiyon olarak yaşa!",
                "Muhammed Ali"
            ),
            MotivationQuote(
                "Korkularının üzerine gitmezsen, zihnin sana asla ait olmaz.",
                "Mike Tyson"
            ),
            MotivationQuote(
                "Stay Hard! Zihnin pes etmek istediğinde, kapasitenin sadece %40'ını kullanmışsındır.",
                "David Goggins"
            ),
            MotivationQuote(
                "Disiplin, canın istemediği anlarda bile yapman gerekeni yapmaktır.",
                "David Goggins"
            ),
            MotivationQuote(
                "Acı geçicidir, pes etmek sonsuza kadar sürer.",
                "Lance Armstrong"
            ),
            MotivationQuote(
                "Kaybetmekten korkma; denememekten kork. Sınırlarını sadece sen belirlersin.",
                "Kobe Bryant"
            ),
            MotivationQuote(
                "Bahane üretmek yerine ter akıt. Terin sesi bahanelerden daha gür çıkar.",
                "David Goggins"
            )
        )

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val randomIndex = Random.nextInt(quotes.size)
            val selected = quotes[randomIndex]

            val views = RemoteViews(context.packageName, R.layout.quote_app_widget)
            views.setTextViewText(R.id.widget_quote_text, selected.quote)
            views.setTextViewText(R.id.widget_quote_author, "— " + selected.author)

            if (selected.isAtaturk) {
                // 🇹🇷 Atatürk Sözleri için Özel Yeşil & Sarı Vurgusu
                views.setTextColor(R.id.widget_quote_text, Color.parseColor("#FACC15")) // Parlak Altın Sarı
                views.setTextColor(R.id.widget_quote_author, Color.parseColor("#00E676")) // Neon Yeşil
            } else {
                views.setTextColor(R.id.widget_quote_text, Color.parseColor("#38BDF8")) // Açık Mavi
                views.setTextColor(R.id.widget_quote_author, Color.parseColor("#00E676")) // Neon Yeşil
            }

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
