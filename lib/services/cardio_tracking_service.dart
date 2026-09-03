import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cardio_workout_log.dart';
import 'api_service.dart';

class CardioTrackingService {
  static const MethodChannel _channel = MethodChannel('com.gympulse.gymapp/sensors');

  static bool isRunning = false;
  static String activeMode = 'Koşu'; // 'Koşu' veya 'Yürüyüş'
  static int secondsElapsed = 0;
  static double currentSpeedKmh = 0.0;
  static double totalDistanceKm = 0.0;

  static Timer? _syncTimer;
  static Timer? _internalTimer;
  static List<Map<String, double>> routePoints = [];

  // Konum iznini kontrol et ve gerekirse iste
  static Future<bool> checkAndRequestLocationPermission() async {
    try {
      final res = await _channel.invokeMethod('requestLocationPermission');
      if (res is bool) return res;
    } catch (_) {}
    return true; // Web veya fallback izin
  }

  static Future<void> init() async {
    try {
      await _channel.invokeMethod('requestLocationPermission');
    } catch (_) {}

    await refreshState();

    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await refreshState();
    });

    // Eğer zaten çalışıyorsa dahili timer'ı başlat
    if (isRunning && _internalTimer == null) {
      _startInternalTimer();
    }
  }

  static void _startInternalTimer() {
    _internalTimer?.cancel();
    _internalTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (isRunning) {
        secondsElapsed++;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('cardio_seconds', secondsElapsed);
      } else {
        _internalTimer?.cancel();
        _internalTimer = null;
      }
    });
  }

  static Future<void> refreshState() async {
    try {
      final res = await _channel.invokeMethod('getCardioState');
      if (res != null && res is Map) {
        isRunning = res['isRunning'] ?? false;
        activeMode = res['mode'] ?? 'Koşu';
        secondsElapsed = res['seconds'] ?? secondsElapsed;
        currentSpeedKmh = (res['speed'] as num?)?.toDouble() ?? currentSpeedKmh;
        totalDistanceKm = (res['distance'] as num?)?.toDouble() ?? totalDistanceKm;
        final lat = (res['lat'] as num?)?.toDouble() ?? 0.0;
        final lng = (res['lng'] as num?)?.toDouble() ?? 0.0;
        if (lat != 0.0 && lng != 0.0 && isRunning) {
          if (routePoints.isEmpty || (routePoints.last['lat'] != lat || routePoints.last['lng'] != lng)) {
            routePoints.add({'lat': lat, 'lng': lng});
          }
        }
        return;
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    isRunning = prefs.getBool('cardio_is_running') ?? false;
    activeMode = prefs.getString('cardio_mode') ?? 'Koşu';
    // Eğer web / emülatörde yerel artıyorsa geriye çekme
    final savedSeconds = prefs.getInt('cardio_seconds') ?? 0;
    if (savedSeconds > secondsElapsed) {
      secondsElapsed = savedSeconds;
    }
    currentSpeedKmh = prefs.getDouble('cardio_speed') ?? currentSpeedKmh;
    totalDistanceKm = prefs.getDouble('cardio_distance') ?? totalDistanceKm;
  }

  static Future<void> start(String mode) async {
    activeMode = mode;
    isRunning = true;
    secondsElapsed = 0;
    currentSpeedKmh = 0.0;
    totalDistanceKm = 0.0;
    routePoints.clear();

    _startInternalTimer();

    try {
      await _channel.invokeMethod('startCardioService', {'mode': mode});
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cardio_is_running', true);
    await prefs.setString('cardio_mode', mode);
    await prefs.setInt('cardio_seconds', 0);
    await prefs.setDouble('cardio_speed', 0.0);
    await prefs.setDouble('cardio_distance', 0.0);
  }

  static Future<CardioWorkoutLog> stop({String username = 'Sporcu'}) async {
    isRunning = false;
    _internalTimer?.cancel();
    _internalTimer = null;

    final finishedSeconds = secondsElapsed;
    final finishedDistance = totalDistanceKm;
    final finishedSpeed = currentSpeedKmh > 0
        ? currentSpeedKmh
        : (finishedSeconds > 0 ? (finishedDistance / (finishedSeconds / 3600.0)) : 0.0);

    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final workoutLog = CardioWorkoutLog(
      id: now.millisecondsSinceEpoch.toString(),
      dateStr: dateStr,
      mode: activeMode,
      seconds: finishedSeconds,
      distanceKm: finishedDistance,
      avgSpeedKmh: finishedSpeed,
      route: List<Map<String, double>>.from(routePoints),
    );

    // Yerel Hafızaya Geçmişi Ekle
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cardio_is_running', false);

    final historyJsonList = prefs.getStringList('cardio_history_$username') ?? [];
    historyJsonList.insert(0, jsonEncode(workoutLog.toJson()));
    await prefs.setStringList('cardio_history_$username', historyJsonList);

    // Sunucuya Asenkron Gönder
    ApiService.saveCardioLog(username, workoutLog);

    try {
      await _channel.invokeMethod('stopCardioService');
    } catch (_) {}

    return workoutLog;
  }

  // Kullanıcının Geçmiş Koşularını Getir (Önce Bulut, sonra Yerel Cache)
  static Future<List<CardioWorkoutLog>> getWorkoutHistory(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJsonList = prefs.getStringList('cardio_history_$username') ?? [];
    List<CardioWorkoutLog> localList = historyJsonList.map((str) => CardioWorkoutLog.fromJson(jsonDecode(str))).toList();

    // Buluttan da getirmeyi dene
    final cloudLogs = await ApiService.fetchCardioLogs(username);
    if (cloudLogs.isNotEmpty) {
      return cloudLogs;
    }
    return localList;
  }

  // Rota Noktası Ekle (Harita Çizimi İçin)
  static void addPoint(double lat, double lng) {
    routePoints.add({'lat': lat, 'lng': lng});
  }

  static String get formattedTime {
    final hours = secondsElapsed ~/ 3600;
    final minutes = (secondsElapsed % 3600) ~/ 60;
    final secs = secondsElapsed % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
