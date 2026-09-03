package com.gympulse.gymapp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

class CardioTrackingService : Service(), LocationListener {
    private var isRunning = false
    private var mode = "Koşu"
    private var secondsElapsed = 0
    private var currentSpeedKmh = 0.0
    private var totalDistanceKm = 0.0
    private var lastLocation: Location? = null

    private val handler = Handler(Looper.getMainLooper())
    private var locationManager: LocationManager? = null

    private val timerRunnable = object : Runnable {
        override fun run() {
            if (isRunning) {
                secondsElapsed++
                saveState()
                updateNotification()
                updateCardioWidget()
                handler.postDelayed(this, 1000)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        when (action) {
            ACTION_START -> {
                mode = intent.getStringExtra("mode") ?: "Koşu"
                startTracking()
            }
            ACTION_STOP -> {
                stopTracking()
            }
            ACTION_SET_MODE -> {
                mode = intent.getStringExtra("mode") ?: "Koşu"
                updateCardioWidget()
            }
        }
        return START_STICKY
    }

    private fun startTracking() {
        if (isRunning) return
        isRunning = true
        secondsElapsed = 0
        totalDistanceKm = 0.0
        currentSpeedKmh = 0.0
        lastLocation = null

        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)

        startLocationUpdates()
        handler.post(timerRunnable)
        saveState()
        updateCardioWidget()
    }

    private fun stopTracking() {
        isRunning = false
        handler.removeCallbacks(timerRunnable)
        stopLocationUpdates()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        saveState()
        updateCardioWidget()
    }

    private fun startLocationUpdates() {
        try {
            locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            locationManager?.requestLocationUpdates(
                LocationManager.GPS_PROVIDER,
                1000L,
                1f,
                this
            )
        } catch (_: SecurityException) {}
    }

    private fun stopLocationUpdates() {
        locationManager?.removeUpdates(this)
    }

    override fun onLocationChanged(location: Location) {
        val prevLocation = lastLocation
        if (location.hasSpeed()) {
            currentSpeedKmh = (location.speed * 3.6).toDouble()
        } else if (prevLocation != null) {
            val dist = location.distanceTo(prevLocation)
            val timeDiff = (location.time - prevLocation.time) / 1000.0
            if (timeDiff > 0) {
                currentSpeedKmh = (dist / timeDiff) * 3.6
            }
        }

        if (prevLocation != null) {
            totalDistanceKm += (location.distanceTo(prevLocation) / 1000.0)
        }
        lastLocation = location

        saveState()
        updateNotification()
        updateCardioWidget()
    }

    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
    override fun onProviderEnabled(provider: String) {}
    override fun onProviderDisabled(provider: String) {}

    private fun buildNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val hours = secondsElapsed / 3600
        val mins = (secondsElapsed % 3600) / 60
        val secs = secondsElapsed % 60
        val timeFormatted = String.format("%02d:%02d:%02d", hours, mins, secs)

        val emoji = if (mode == "Yürüyüş") "🚶" else "🏃"

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("$emoji GYM Kardiyo: $mode Aktif")
            .setContentText("⏱️ $timeFormatted  |  ⚡ ${String.format("%.1f", currentSpeedKmh)} km/h  |  📍 ${String.format("%.2f", totalDistanceKm)} km")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOnlyAlertOnce(true)
            .build()
    }

    private fun updateNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification())
    }

    private fun saveState() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean("flutter.cardio_is_running", isRunning)
            .putString("flutter.cardio_mode", mode)
            .putInt("flutter.cardio_seconds", secondsElapsed)
            .putFloat("flutter.cardio_speed", currentSpeedKmh.toFloat())
            .putFloat("flutter.cardio_distance", totalDistanceKm.toFloat())
            .putFloat("flutter.cardio_lat", (lastLocation?.latitude ?: 0.0).toFloat())
            .putFloat("flutter.cardio_lng", (lastLocation?.longitude ?: 0.0).toFloat())
            .apply()
    }

    private fun updateCardioWidget() {
        CardioAppWidget.updateAllWidgets(this)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "GYM Kardiyo & Hız Takibi",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Canlı süre, hız ve mesafe bildirimi"
                setShowBadge(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    companion object {
        const val CHANNEL_ID = "gym_cardio_channel"
        const val NOTIFICATION_ID = 991
        const val ACTION_START = "com.gympulse.gymapp.START_CARDIO"
        const val ACTION_STOP = "com.gympulse.gymapp.STOP_CARDIO"
        const val ACTION_SET_MODE = "com.gympulse.gymapp.SET_CARDIO_MODE"
    }
}
