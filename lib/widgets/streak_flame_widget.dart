import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/program_service.dart';
import '../theme/app_theme.dart';
import '../screens/streak_detail_screen.dart';
import 'streak_calendar_modal.dart';

class StreakFlameWidget extends StatefulWidget {
  final UserProfile profile;

  const StreakFlameWidget({
    super.key,
    required this.profile,
  });

  @override
  State<StreakFlameWidget> createState() => _StreakFlameWidgetState();
}

class _StreakFlameWidgetState extends State<StreakFlameWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = widget.profile.streakDays;
    final hasStreak = streak > 0;

    // Günlük durum (son 7 gün)
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    // Bugün dinlenme (rest) günü mü?
    // 1. activityCalendar'da 'rest' olarak işaretli mi?
    // 2. Veya kullanıcının aktif programında bugün egzersiz yok mu?
    final calendarStatusToday = widget.profile.activityCalendar[todayKey];
    bool isTodayRestDay = calendarStatusToday == 'rest';
    if (!isTodayRestDay && calendarStatusToday == null) {
      final activeProgram = ProgramService.getActiveProgram();
      if (activeProgram != null) {
        final matches = activeProgram.schedule.where((d) => d.dayOfWeek == now.weekday);
        if (matches.isNotEmpty && matches.first.exercises.isEmpty) {
          isTodayRestDay = true;
        }
      }
    }

    final List<Map<String, dynamic>> last7Days = [];
    final dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      String? status = widget.profile.activityCalendar[dateKey];
      final isToday = i == 0;

      // Eğer bugün ise ve programda egzersiz yoksa otomatik 'rest' göster
      if (isToday && status == null && isTodayRestDay) {
        status = 'rest';
      }

      last7Days.add({
        'dayName': dayNames[date.weekday - 1],
        'status': status, // 'completed', 'rest', null
        'isToday': isToday,
      });
    }

    // Kart temasını belirle (Rest day ise Buz Mavisi ❄️, Değilse Ateş 🔥 veya Koyu Boş)
    final List<Color> gradientColors;
    final Color borderColor;
    final Color glowColor;
    final String streakIcon;
    final String streakSubtitle;
    final Color streakColor;

    if (isTodayRestDay) {
      gradientColors = const [
        Color(0xFF0C4A6E), // Koyu Buz Mavisi
        Color(0xFF075985), // Buz Kristali
      ];
      borderColor = const Color(0xFF38BDF8);
      glowColor = const Color(0xFF0284C7);
      streakIcon = '❄️';
      streakSubtitle = 'GÜN BUZU (REST DAY)';
      streakColor = const Color(0xFF7DD3FC);
    } else if (hasStreak) {
      gradientColors = const [
        Color(0xFF450A0A), // Koyu Ateş Kırmızısı
        Color(0xFF1E1B4B), // Gece Mavisi
      ];
      borderColor = const Color(0xFFEF4444).withOpacity(0.6);
      glowColor = const Color(0xFFEF4444);
      streakIcon = '🔥';
      streakSubtitle = 'GÜN ATEŞİ';
      streakColor = const Color(0xFFFCA5A5);
    } else {
      gradientColors = const [
        Color(0xFF1E293B),
        Color(0xFF0F172A),
      ];
      borderColor = AppTheme.surfaceBorder;
      glowColor = Colors.transparent;
      streakIcon = '⚪';
      streakSubtitle = 'GÜN ATEŞİ';
      streakColor = AppTheme.textMuted;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StreakDetailScreen(profile: widget.profile),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
          boxShadow: (hasStreak || isTodayRestDay)
              ? [
                  BoxShadow(
                    color: glowColor.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Kısım: Başlık & Tıklama İpucu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ScaleTransition(
                      scale: (hasStreak || isTodayRestDay) ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isTodayRestDay ? const Color(0xFF38BDF8) : (hasStreak ? const Color(0xFFEF4444) : Colors.grey)).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          streakIcon,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTodayRestDay ? 'RECOVERY MODU (REST DAY)' : (hasStreak ? 'DİSİPLİN SERİSİ (STREAK)' : 'STREAK BAŞLAT'),
                          style: TextStyle(
                            color: streakColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$streak',
                              style: TextStyle(
                                color: isTodayRestDay ? const Color(0xFF38BDF8) : (hasStreak ? const Color(0xFFEF4444) : AppTheme.textPrimary),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              streakSubtitle,
                              style: TextStyle(
                                color: streakColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                // Takvim Butonu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: AppTheme.primaryNeon, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Takvim',
                        style: TextStyle(color: AppTheme.primaryNeon, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(color: Color(0xFF334155), height: 1),
            const SizedBox(height: 12),

            // 7 Günlük Mini Hafta Şeridi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: last7Days.map((d) {
                final isCompleted = d['status'] == 'completed';
                final isRest = d['status'] == 'rest';
                final isToday = d['isToday'] as bool;

                Color circleColor = const Color(0xFF334155); // Boş gri
                String icon = '•';

                if (isCompleted) {
                  circleColor = const Color(0xFFEF4444); // Kırmızı Ateş
                  icon = '🔥';
                } else if (isRest) {
                  circleColor = const Color(0xFF38BDF8); // Mavi Buz
                  icon = '❄️';
                }

                return Column(
                  children: [
                    Text(
                      d['dayName'],
                      style: TextStyle(
                        color: isToday ? AppTheme.primaryNeon : AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: circleColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isToday ? AppTheme.primaryNeon : circleColor,
                          width: isToday ? 2.0 : 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          icon,
                          style: TextStyle(
                            fontSize: (isCompleted || isRest) ? 14 : 16,
                            color: circleColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
