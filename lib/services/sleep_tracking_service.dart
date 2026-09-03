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
  static const String _sleepScheduleKey = 'gym_custom_sleep_schedule';
  static List<SleepLog> sleepHistory = [];

  // Varsayılan Hedef Saatler (Alarm Seçici Tarzı)
  static TimeOfDay targetBedTime = const TimeOfDay(hour: 23, minute: 0);
  static TimeOfDay targetWakeTime = const TimeOfDay(hour: 7, minute: 0);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getString(_sleepLogsKey);
    if (logsJson != null) {
      try {
        final List list = jsonDecode(logsJson);
        sleepHistory = list.map((e) => SleepLog.fromJson(e)).toList();
      } catch (_) {}
    }

    final scheduleJson = prefs.getString(_sleepScheduleKey);
    if (scheduleJson != null) {
      try {
        final Map map = jsonDecode(scheduleJson);
        targetBedTime = TimeOfDay(hour: map['bedHour'] ?? 23, minute: map['bedMinute'] ?? 0);
        targetWakeTime = TimeOfDay(hour: map['wakeHour'] ?? 7, minute: map['wakeMinute'] ?? 0);
      } catch (_) {}
    }
  }

  static Future<void> saveSchedule(TimeOfDay bed, TimeOfDay wake) async {
    targetBedTime = bed;
    targetWakeTime = wake;
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'bedHour': bed.hour,
      'bedMinute': bed.minute,
      'wakeHour': wake.hour,
      'wakeMinute': wake.minute,
    };
    await prefs.setString(_sleepScheduleKey, jsonEncode(data));
  }

  // Uygulama her kapandığında veya arka plana geçtiğinde zaman damgası bırak
  static Future<void> recordActiveTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActiveKey, DateTime.now().toIso8601String());
  }

  // Manuel Uyku Kaydı Ekle (Saat/Dakika Seçmeli Alarm Tarzı)
  static Future<void> showManualSleepDialog(BuildContext context, UserProfile profile, VoidCallback onSaved) async {
    TimeOfDay selectedBed = targetBedTime;
    TimeOfDay selectedWake = targetWakeTime;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Uyku süresini hesapla
            double bedDouble = selectedBed.hour + (selectedBed.minute / 60.0);
            double wakeDouble = selectedWake.hour + (selectedWake.minute / 60.0);
            double duration = wakeDouble - bedDouble;
            if (duration < 0) duration += 24.0;

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: AppTheme.purpleXP, width: 2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text('⏰', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 8),
                          Text(
                            'UYKU HEDEFİ & SAAT AYARI',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Alarm Seçici Tarzı Kartlar
                  Row(
                    children: [
                      // Yatma Saati
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedBed,
                              builder: (context, child) {
                                return Theme(
                                  data: AppTheme.darkTheme.copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: AppTheme.purpleXP,
                                      surface: AppTheme.surface,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setModalState(() => selectedBed = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.purpleXP.withOpacity(0.5), width: 1.5),
                            ),
                            child: Column(
                              children: [
                                const Text('🌙 YATMA SAATİ', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(
                                  '${selectedBed.hour.toString().padLeft(2, '0')}:${selectedBed.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                const Text('Değiştirmek İçin Dokun', style: TextStyle(color: AppTheme.purpleXP, fontSize: 9)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Uyanma Saati
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedWake,
                              builder: (context, child) {
                                return Theme(
                                  data: AppTheme.darkTheme.copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: AppTheme.primaryNeon,
                                      surface: AppTheme.surface,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setModalState(() => selectedWake = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.5), width: 1.5),
                            ),
                            child: Column(
                              children: [
                                const Text('☀️ UYANMA SAATİ', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(
                                  '${selectedWake.hour.toString().padLeft(2, '0')}:${selectedWake.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                const Text('Değiştirmek İçin Dokun', style: TextStyle(color: AppTheme.primaryNeon, fontSize: 9)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Toplam Süre ve Toparlanma Rozeti
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Toplam Dinlenme Süresi:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        Text(
                          '${duration > 16.0 ? 16.0 : duration.toStringAsFixed(1)} Saat ${duration >= 7.0 ? '🔥 (+100 XP)' : ''}',
                          style: TextStyle(
                            color: duration >= 7.0 ? AppTheme.primaryNeon : AppTheme.secondaryOrange,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Kaydet & Güncelle Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.purpleXP,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        await saveSchedule(selectedBed, selectedWake);

                        final now = DateTime.now();
                        // Eğer uyanma saati yatma saatinden küçükse veya eşitse, yatma saati dündür
                        final isBedYesterday = (selectedWake.hour < selectedBed.hour) || 
                            (selectedWake.hour == selectedBed.hour && selectedWake.minute <= selectedBed.minute);
                        final bedDay = isBedYesterday ? now.subtract(const Duration(days: 1)) : now;
                        final bedTime = DateTime(bedDay.year, bedDay.month, bedDay.day, selectedBed.hour, selectedBed.minute);
                        final wakeTime = DateTime(now.year, now.month, now.day, selectedWake.hour, selectedWake.minute);

                        // Süreyi maksimum 16 saat ile sınırla
                        double computedHours = wakeTime.difference(bedTime).inMinutes / 60.0;
                        if (computedHours < 0) computedHours += 24.0;
                        if (computedHours > 16.0) computedHours = 16.0;

                        final log = SleepLog(
                          sleepStart: bedTime,
                          sleepEnd: wakeTime,
                          durationHours: double.parse(computedHours.toStringAsFixed(1)),
                          qualityScore: computedHours < 5.0 ? 'Yetersiz & Kritik 😴' : (computedHours < 7.0 ? 'Orta & İdare Eder 🥱' : 'Mükemmel & Titan ⚡'),
                          recoveryBonus: computedHours >= 7.0 ? '+%20 Toparlanma & +100 Bonus XP' : '+%5 Toparlanma',
                          advice: computedHours >= 7.0 ? 'Büyüme hormonu zirvede! Bugün salonda PR kırmak için harika bir gün.' : 'Yeterli toparlanamadın, ağırlıklarda dikkatli ol.',
                        );

                        await saveSleepLog(log, profile);
                        onSaved();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🌙 ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} Uykusu Kaydedildi: ${computedHours.toStringAsFixed(1)} Saat'),
                              backgroundColor: const Color(0xFF16A34A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                      child: const Text('UYKU PLANINI KAYDET', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Uygulama açıldığında inaktiflik kontrolü
  static Future<void> checkInactivityOnStartup(BuildContext context, UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final lastActiveStr = prefs.getString(_lastActiveKey);
    final now = DateTime.now();

    await recordActiveTimestamp();

    if (lastActiveStr == null) return;
    final lastActive = DateTime.tryParse(lastActiveStr);
    if (lastActive == null) return;

    final diffMins = now.difference(lastActive).inMinutes;
    final diffHours = diffMins / 60.0;

    if (diffHours >= 4.5 && diffHours <= 14.0) {
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
    double hours,
    UserProfile profile,
  ) {
    final log = SleepLog.evaluate(sleepStart, sleepEnd);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.purpleXP, width: 1.5),
        ),
        title: const Row(
          children: [
            Text('🌙', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Günaydın Savaşçı!', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'En son ${sleepStart.hour.toString().padLeft(2, '0')}:${sleepStart.minute.toString().padLeft(2, '0')}\'da aktif görünüyordun. Yaklaşık ${hours.toStringAsFixed(1)} saat uyudun mu?',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.purpleXP.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: AppTheme.purpleXP, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${log.qualityScore} • ${log.recoveryBonus}',
                    style: const TextStyle(color: AppTheme.purpleXP, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HAYIR', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.purpleXP,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await saveSleepLog(log, profile);
            },
            child: const Text('EVET, UYUDUM', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static Future<void> saveSleepLog(SleepLog log, UserProfile profile) async {
    // Aynı gün (YYYY-MM-DD) bazında kayıt kontrolü: Aynı güne ait varsa eski kaydı güncelle
    final logDateStr = '${log.sleepEnd.year}-${log.sleepEnd.month.toString().padLeft(2, '0')}-${log.sleepEnd.day.toString().padLeft(2, '0')}';
    
    final existingIndex = sleepHistory.indexWhere((item) {
      final itemDateStr = '${item.sleepEnd.year}-${item.sleepEnd.month.toString().padLeft(2, '0')}-${item.sleepEnd.day.toString().padLeft(2, '0')}';
      return itemDateStr == logDateStr;
    });

    if (existingIndex != -1) {
      sleepHistory[existingIndex] = log; // Önceki süreyi güncelle
    } else {
      sleepHistory.add(log);
    }

    if (sleepHistory.length > 30) {
      sleepHistory.removeAt(0);
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonList = sleepHistory.map((e) => e.toJson()).toList();
    await prefs.setString(_sleepLogsKey, jsonEncode(jsonList));

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
