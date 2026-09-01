import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sleep_log.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import 'storage_service.dart';

class SleepTrackingService {
  static const String _lastActiveKey = 'gym_last_active_timestamp';
  static const String _sleepLogsKey = 'gym_sleep_logs_history';
  static List<SleepLog> sleepHistory = [];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getString(_sleepLogsKey);
    if (logsJson != null) {
      try {
        final List list = jsonDecode(logsJson);
        sleepHistory = list.map((e) => SleepLog.fromJson(e)).toList();
      } catch (_) {}
    }
  }

  // Uygulama her kapandığında veya arka plana geçtiğinde zaman damgası bırak
  static Future<void> recordActiveTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActiveKey, DateTime.now().toIso8601String());
  }

  // Uygulama açıldığında 4-14 saat arası bir inaktiflik var mı kontrol et
  static Future<void> checkInactivityOnStartup(BuildContext context, UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final lastActiveStr = prefs.getString(_lastActiveKey);
    final now = DateTime.now();

    // Zaman damgasını hemen güncelle
    await recordActiveTimestamp();

    if (lastActiveStr == null) return;

    final lastActive = DateTime.tryParse(lastActiveStr);
    if (lastActive == null) return;

    final diffMins = now.difference(lastActive).inMinutes;
    final diffHours = diffMins / 60.0;

    // 4.5 saat ile 14 saat arasında telefona bakılmamışsa uyku olarak algıla
    if (diffHours >= 4.5 && diffHours <= 14.0) {
      // Eğer son 12 saat içinde zaten bir uyku kaydı girilmişse tekrar sorma
      if (sleepHistory.isNotEmpty) {
        final lastLog = sleepHistory.last;
        if (now.difference(lastLog.sleepEnd).inHours < 10) {
          return;
        }
      }

      if (context.mounted) {
        _showSleepInquiryDialog(context, lastActive, now, diffHours, profile);
      }
    }
  }

  static void _showSleepInquiryDialog(
    BuildContext context,
    DateTime sleepStart,
    DateTime sleepEnd,
    double durationHours,
    UserProfile profile,
  ) {
    final startStr = '${sleepStart.hour.toString().padLeft(2, '0')}:${sleepStart.minute.toString().padLeft(2, '0')}';
    final endStr = '${sleepEnd.hour.toString().padLeft(2, '0')}:${sleepEnd.minute.toString().padLeft(2, '0')}';
    final durationStr = durationHours.toStringAsFixed(1);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.primaryNeon, width: 1.5),
        ),
        title: const Row(
          children: [
            Text('🌙', style: TextStyle(fontSize: 26)),
            SizedBox(width: 10),
            Text(
              'Uyku Algılandı!',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$startStr ile $endStr saatleri arasında ($durationStr Saat) uyuyor muydunuz?',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppTheme.primaryNeon, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Doğru uyku takibi antrenman toparlanmasını ve RPG XP çarpanınızı artırır!',
                      style: TextStyle(color: AppTheme.primaryNeon, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hayır, Uyumuyordum', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNeon,
              foregroundColor: AppTheme.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final log = SleepLog.evaluate(sleepStart, sleepEnd);
              await saveSleepLog(log, profile);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⚡ Uyku Kaydedildi: ${log.qualityScore} (${log.recoveryBonus})'),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text('EVET, UYUDUM', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static Future<void> saveSleepLog(SleepLog log, UserProfile profile) async {
    sleepHistory.add(log);
    // Maksimum son 30 günün uykusunu tut
    if (sleepHistory.length > 30) {
      sleepHistory.removeAt(0);
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonList = sleepHistory.map((e) => e.toJson()).toList();
    await prefs.setString(_sleepLogsKey, jsonEncode(jsonList));

    // Kaliteli uykuda +100 XP bonus ver
    if (log.durationHours >= 7.0) {
      profile.currentXP += 100;
      if (profile.currentXP >= profile.targetXP) {
        profile.level++;
        profile.currentXP -= profile.targetXP;
        profile.targetXP = (profile.targetXP * 1.5).round();
      }
      await StorageService.saveUserProfile(profile);
    }
  }
}
