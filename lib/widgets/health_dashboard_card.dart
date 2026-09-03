import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/health_tracking_service.dart';
import '../theme/app_theme.dart';

class HealthDashboardCard extends StatefulWidget {
  final UserProfile profile;

  const HealthDashboardCard({
    super.key,
    required this.profile,
  });

  @override
  State<HealthDashboardCard> createState() => _HealthDashboardCardState();
}

class _HealthDashboardCardState extends State<HealthDashboardCard> {
  @override
  Widget build(BuildContext context) {
    final steps = HealthTrackingService.todaySteps;
    final waterMl = HealthTrackingService.todayWaterMl;
    final calories = HealthTrackingService.calculateCalories(widget.profile, steps);
    final distanceKm = HealthTrackingService.calculateDistanceKm(steps);
    final waterStreak = HealthTrackingService.waterStreakDays;

    final stepProgress = (steps / HealthTrackingService.stepGoal).clamp(0.0, 1.0);
    final waterProgress = (waterMl / HealthTrackingService.waterGoalMl).clamp(0.0, 1.0);

    // Son 7 günün gün adları ve su tamamlama durumları
    final now = DateTime.now();
    final dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final List<Map<String, dynamic>> last7Days = [];

    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final dStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final amount = HealthTrackingService.weeklyWaterMap[dStr] ?? (i == 0 ? waterMl : 0);
      final isMet = amount >= HealthTrackingService.waterGoalMl;
      final isToday = i == 0;

      last7Days.add({
        'name': dayNames[d.weekday - 1],
        'isMet': isMet,
        'isToday': isToday,
        'amount': amount,
      });
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.8), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. ADIM & KALORİ BÖLÜMÜ
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      value: stepProgress,
                      backgroundColor: AppTheme.surfaceBorder,
                      color: AppTheme.primaryNeon,
                      strokeWidth: 5,
                    ),
                  ),
                  const Text('🚶', style: TextStyle(fontSize: 20)),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'GÜNLÜK ADIM HEDEFİ',
                          style: TextStyle(
                            color: AppTheme.primaryNeon,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '${(stepProgress * 100).toInt()}%',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$steps / ${HealthTrackingService.stepGoal} Adım',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '🔥 ${calories.toStringAsFixed(0)} kcal',
                          style: const TextStyle(color: AppTheme.secondaryOrange, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '📍 ${distanceKm.toStringAsFixed(2)} km',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: AppTheme.surfaceBorder, height: 1),
          const SizedBox(height: 14),

          // 2. 💧 SU İÇME STREAK & HIZLI TÜKETİM BÖLÜMÜ (Görsel 1 Tarzı)
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      value: waterProgress,
                      backgroundColor: AppTheme.surfaceBorder,
                      color: const Color(0xFF38BDF8),
                      strokeWidth: 5,
                    ),
                  ),
                  const Text('💧', style: TextStyle(fontSize: 20)),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'GÜNLÜK SU TÜKETİMİ',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            if (waterStreak > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '💧 $waterStreak Gün',
                                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '$waterMl / ${HealthTrackingService.waterGoalMl} ml',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: waterProgress,
                        backgroundColor: AppTheme.surfaceBorder,
                        color: const Color(0xFF0284C7),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  await HealthTrackingService.addWater(250);
                  setState(() {});
                },
                child: const Text('+250ml', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. 📅 HAFTALIK 7 GÜN SU STREAK ŞERİDİ (Her Gün İçilmelidir, Off-day Yoktur)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: last7Days.map((day) {
                final isMet = day['isMet'] as bool;
                final isToday = day['isToday'] as bool;
                final name = day['name'] as String;

                return Column(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isToday ? const Color(0xFF38BDF8) : AppTheme.textMuted,
                        fontSize: 9,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isMet
                            ? const Color(0xFF0284C7).withOpacity(0.3)
                            : (isToday ? const Color(0xFF38BDF8).withOpacity(0.1) : Colors.transparent),
                        border: Border.all(
                          color: isMet
                              ? const Color(0xFF38BDF8)
                              : (isToday ? const Color(0xFF38BDF8) : AppTheme.surfaceBorder),
                          width: isToday ? 1.5 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isMet ? '💧' : '•',
                          style: TextStyle(
                            fontSize: isMet ? 11 : 12,
                            color: isMet ? Colors.white : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
