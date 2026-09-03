package com.gympulse.gymapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorManager
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            // Telefon yeniden başladığında arka plan adım & widget servislerini hazırla
            WaterAppWidget.updateAllWidgets(context)
            QuoteAppWidget.updateAllWidgets(context)
            StreakAppWidget.updateAllWidgets(context)
        }
    }
}
