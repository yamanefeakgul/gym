package com.gympulse.gymapp

import android.Manifest
import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity(), SensorEventListener {
    private val UPDATER_CHANNEL = "com.gympulse.gymapp/updater"
    private val SENSORS_CHANNEL = "com.gympulse.gymapp/sensors"
    private var downloadId: Long = -1

    private var sensorManager: SensorManager? = null
    private var stepSensor: Sensor? = null
    private var dailyStepOffset = -1

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. GÜNCELLEYİCİ KANALI
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkInstallPermission" -> {
                    val canInstall = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        packageManager.canRequestPackageInstalls()
                    } else {
                        true
                    }
                    result.success(canInstall)
                }
                "requestInstallPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 101)
                        }
                    }
                    result.success(true)
                }
                "downloadAndInstall" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        startDownloadAndInstall(url)
                        result.success(true)
                    } else {
                        result.error("INVALID_URL", "URL boş olamaz", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // 2. ADIMSAYAR SENSÖR KANALI & SU WIDGET SENKRONİZASYONU
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SENSORS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestStepPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACTIVITY_RECOGNITION) != PackageManager.PERMISSION_GRANTED) {
                            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.ACTIVITY_RECOGNITION), 102)
                        }
                    }
                    initStepSensor()
                    result.success(true)
                }
                "getTodaySteps" -> {
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val todayKey = "flutter.gym_steps_" + getTodayString()
                    val steps = prefs.getInt(todayKey, 0)
                    result.success(steps)
                }
                "getTodayWater" -> {
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val todayKey = "flutter.gym_water_" + getTodayString()
                    val water = prefs.getInt(todayKey, 0)
                    result.success(water)
                }
                "addWater" -> {
                    val amount = call.argument<Int>("amount") ?: 250
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val todayKey = "flutter.gym_water_" + getTodayString()
                    val current = prefs.getInt(todayKey, 0)
                    val updated = current + amount
                    prefs.edit().putInt(todayKey, updated).apply()
                    WaterAppWidget.updateAllWidgets(this)
                    result.success(updated)
                }
                "updateWaterWidget" -> {
                    WaterAppWidget.updateAllWidgets(this)
                    result.success(true)
                }
                "checkLocationPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }
                "requestLocationPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                    if (!granted) {
                        ActivityCompat.requestPermissions(this, arrayOf(
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACCESS_COARSE_LOCATION
                        ), 103)
                    }
                    result.success(granted)
                }
                "startCardioService" -> {
                    val mode = call.argument<String>("mode") ?: "Koşu"
                    val serviceIntent = Intent(this, CardioTrackingService::class.java).apply {
                        action = CardioTrackingService.ACTION_START
                        putExtra("mode", mode)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    result.success(true)
                }
                "stopCardioService" -> {
                    val serviceIntent = Intent(this, CardioTrackingService::class.java).apply {
                        action = CardioTrackingService.ACTION_STOP
                    }
                    startService(serviceIntent)
                    result.success(true)
                }
                "getCardioState" -> {
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val map = HashMap<String, Any>()
                    map["isRunning"] = prefs.getBoolean("flutter.cardio_is_running", false)
                    map["mode"] = prefs.getString("flutter.cardio_mode", "Koşu") ?: "Koşu"
                    map["seconds"] = prefs.getInt("flutter.cardio_seconds", 0)
                    map["speed"] = prefs.getFloat("flutter.cardio_speed", 0.0f).toDouble()
                    map["distance"] = prefs.getFloat("flutter.cardio_distance", 0.0f).toDouble()
                    map["lat"] = prefs.getFloat("flutter.cardio_lat", 0.0f).toDouble()
                    map["lng"] = prefs.getFloat("flutter.cardio_lng", 0.0f).toDouble()
                    result.success(map)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        initStepSensor()
    }

    private fun initStepSensor() {
        if (sensorManager == null) {
            sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
            stepSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
            if (stepSensor == null) {
                stepSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
            }
            stepSensor?.let {
                sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
            }
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null) return
        val totalStepsSinceBoot = event.values[0].toInt()

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val todayStr = getTodayString()
        val offsetKey = "flutter.gym_step_offset_" + todayStr
        val todayKey = "flutter.gym_steps_" + todayStr

        var savedOffset = prefs.getInt(offsetKey, -1)
        if (savedOffset == -1 || savedOffset > totalStepsSinceBoot) {
            savedOffset = totalStepsSinceBoot
            prefs.edit().putInt(offsetKey, savedOffset).apply()
        }

        val todaySteps = totalStepsSinceBoot - savedOffset
        prefs.edit().putInt(todayKey, todaySteps).apply()
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun getTodayString(): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        return sdf.format(Date())
    }

    private fun startDownloadAndInstall(url: String) {
        val fileName = "gym_update.apk"
        val destinationFile = File(getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS), fileName)
        if (destinationFile.exists()) {
            destinationFile.delete()
        }

        val request = DownloadManager.Request(Uri.parse(url))
            .setTitle("GYM Uygulaması Güncelleniyor")
            .setDescription("Yeni sürüm indiriliyor...")
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setDestinationUri(Uri.fromFile(destinationFile))
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(true)

        val downloadManager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        downloadId = downloadManager.enqueue(request)

        val onComplete = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val id = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1)
                if (id == downloadId) {
                    unregisterReceiver(this)
                    installApk(destinationFile)
                }
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(onComplete, IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE), Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(onComplete, IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE))
        }
    }

    private fun installApk(file: File) {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            val contentUri = FileProvider.getUriForFile(
                applicationContext,
                "${applicationContext.packageName}.fileprovider",
                file
            )
            setDataAndType(contentUri, "application/vnd.android.package-archive")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
        }
        startActivity(intent)
    }
}
