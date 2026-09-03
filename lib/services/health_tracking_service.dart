import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class HealthTrackingService {
  static const MethodChannel _channel = MethodChannel('com.gympulse.gymapp/sensors');

  static int todaySteps = 0;
  static int todayWaterMl = 0;
  static const int waterGoalMl = 3000;
  static const int stepGoal = 10000;
  static int waterStreakDays = 0;
  static Map<String, int> weeklyWaterMap = {};

  static Timer? _syncTimer;

  // Servisi Başlat ve İzinleri Al
  static Future<void> init() async {
    try {
      await _channel.invokeMethod('requestStepPermission');
      await refreshData();

      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
        await refreshData();
      });
    } catch (_) {}
  }

  static Future<void> refreshData() async {
    try {
      final int? steps = await _channel.invokeMethod('getTodaySteps');
      final int? water = await _channel.invokeMethod('getTodayWater');

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      todaySteps = steps ?? prefs.getInt('gym_steps_$todayStr') ?? 0;
      todayWaterMl = water ?? prefs.getInt('gym_water_$todayStr') ?? 0;

      // Son 7 günün su verisini ve su streak'ini hesapla
      weeklyWaterMap.clear();
      int streak = 0;

      for (int i = 0; i < 7; i++) {
        final d = now.subtract(Duration(days: i));
        final dStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        final val = prefs.getInt('gym_water_$dStr') ?? (i == 0 ? todayWaterMl : 0);
        weeklyWaterMap[dStr] = val;
      }

      // Su serisini geriye doğru say (Bugün hedefe ulaştıysa bugünden, ulaşmadıysa dünden say)
      final hasTodayMet = todayWaterMl >= waterGoalMl;
      int offset = hasTodayMet ? 0 : 1;

      while (true) {
        final d = now.subtract(Duration(days: offset));
        final dStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        final val = prefs.getInt('gym_water_$dStr') ?? (offset == 0 ? todayWaterMl : 0);

        if (val >= waterGoalMl) {
          streak++;
          offset++;
        } else {
          break; // Seri kırıldı
        }
      }

      waterStreakDays = streak;
    } catch (_) {}
  }

  // +250ml veya İstenen Miktar Su Ekle
  static Future<int> addWater(int amountMl) async {
    try {
      final int? updated = await _channel.invokeMethod('addWater', {'amount': amountMl});
      if (updated != null) {
        todayWaterMl = updated;
        await refreshData();
        return updated;
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final current = prefs.getInt('gym_water_$todayStr') ?? 0;
    final updated = current + amountMl;
    await prefs.setInt('gym_water_$todayStr', updated);
    todayWaterMl = updated;
    await refreshData();
    return updated;
  }

  // Yakılan Kalori Hesabı (Kilo & Cinsiyet bazlı)
  static double calculateCalories(UserProfile profile, int steps) {
    final factor = profile.gender == 'Kadın' ? 0.00044 : 0.00050;
    return (steps * profile.weightKg * factor);
  }

  // Yürünüş Mesafesi (KM)
  static double calculateDistanceKm(int steps) {
    return (steps * 0.75) / 1000.0;
  }
}
