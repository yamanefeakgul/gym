import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/exercise.dart';
import '../models/workout_program.dart';
import '../services/program_service.dart';
import '../theme/app_theme.dart';
import '../widgets/streak_flame_widget.dart';
import '../widgets/exercise_card.dart';
import '../widgets/health_dashboard_card.dart';
import '../services/sleep_tracking_service.dart';
import 'streak_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile profile;
  final List<Exercise> exercises;
  final Function(String exerciseId, double weight, int reps, int sets) onLogWeight;
  final VoidCallback onNavigateToPrograms;
  final VoidCallback? onNavigateToProfile;

  const HomeScreen({
    super.key,
    required this.profile,
    required this.exercises,
    required this.onLogWeight,
    required this.onNavigateToPrograms,
    this.onNavigateToProfile,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDay = DateTime.now().weekday; // 1: Mon, 7: Sun

  @override
  Widget build(BuildContext context) {
    final activeProgram = ProgramService.getActiveProgram();

    WorkoutDay? daySchedule;
    if (activeProgram != null) {
      final matches = activeProgram.schedule.where((d) => d.dayOfWeek == _selectedDay);
      if (matches.isNotEmpty) {
        daySchedule = matches.first;
      }
    }

    final todayDetails = daySchedule?.exercises ?? [];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar: En Solda Profil Avatarı + Seviye Barı (Lv. X) & En Sağda Tonaj ve Seri (Streak)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sol: Profil Avatarı & Seviye Barı (Lv. X)
                    GestureDetector(
                      onTap: widget.onNavigateToProfile,
                      child: Row(
                        children: [
                          // Profil Avatarı
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryNeon, AppTheme.primaryAccent],
                              ),
                              border: Border.all(color: AppTheme.primaryNeon, width: 1.8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryNeon.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: (widget.profile.avatarBase64 != null && widget.profile.avatarBase64!.isNotEmpty)
                                  ? Image.memory(
                                      base64Decode(widget.profile.avatarBase64!),
                                      fit: BoxFit.cover,
                                    )
                                  : const Center(
                                      child: Text('⚔️', style: TextStyle(fontSize: 20)),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Seviye Barı & Üstünde Lv. X Yazısı
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Lv. ${widget.profile.level}',
                                    style: const TextStyle(
                                      color: AppTheme.primaryNeon,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${widget.profile.currentXP}/${widget.profile.targetXP} XP',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              // XP Progress Bar
                              Container(
                                width: 85,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceBorder,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: widget.profile.xpProgress,
                                    backgroundColor: Colors.transparent,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryNeon),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Sağ: Tonaj + Spor Serisi (Streak)
                    Row(
                      children: [
                        // Tonaj Çipi
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.line_weight_rounded, color: AppTheme.primaryAccent, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${(widget.profile.totalTonnageLiftedKg / 1000).toStringAsFixed(1)} T',
                                style: const TextStyle(
                                  color: AppTheme.primaryAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Spor Serisi Çipi (Streak - Tıklanınca Detay Sayfası Açılır)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StreakDetailScreen(profile: widget.profile),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: widget.profile.streakDays > 0 ? const Color(0xFFEF4444).withOpacity(0.6) : AppTheme.surfaceBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(widget.profile.streakDays > 0 ? '🔥' : '⚪', style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.profile.streakDays}',
                                  style: TextStyle(
                                    color: widget.profile.streakDays > 0 ? const Color(0xFFFCA5A5) : AppTheme.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 🚶💧 ADIM SAYAR, KALORİ & SU TAKİP DASHBOARD KARTI
            SliverToBoxAdapter(
              child: HealthDashboardCard(profile: widget.profile),
            ),

            // 🌙 UYKU KALİTESİ & GÜÇ TAVSİYESİ BANNER'I
            _buildSleepPerformanceBanner(),

            // 🔥 YENİ ÖZEL STREAK FLAME WIDGET'I (Ana Ekranda Parlayan Ateş & Hafta Şeridi)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: StreakFlameWidget(profile: widget.profile),
              ),
            ),

            // Gün Seçici Yatay Liste
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'HAFTALIK PROGRAM',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          activeProgram != null ? activeProgram.title : 'Program Seçilmedi',
                          style: const TextStyle(
                            color: AppTheme.primaryNeon,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 52,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 7,
                        itemBuilder: (context, index) {
                          final dayNum = index + 1;
                          final isSelected = _selectedDay == dayNum;
                          final isToday = DateTime.now().weekday == dayNum;
                          final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDay = dayNum;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 60,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryNeon : AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isToday && !isSelected
                                      ? AppTheme.primaryNeon.withOpacity(0.6)
                                      : (isSelected ? AppTheme.primaryNeon : AppTheme.surfaceBorder),
                                  width: isToday ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryNeon.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    days[index],
                                    style: TextStyle(
                                      color: isSelected ? AppTheme.background : AppTheme.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isToday)
                                    Text(
                                      'Bugün',
                                      style: TextStyle(
                                        color: isSelected ? AppTheme.background : AppTheme.primaryNeon,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Program / Gün Durum Başlığı
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          daySchedule?.title ?? (activeProgram != null ? 'Dinlenme Günü' : 'Aktif Programınız Yok'),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (todayDetails.isNotEmpty)
                        Text(
                          '${todayDetails.length} Hareket',
                          style: const TextStyle(
                            color: AppTheme.primaryNeon,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // Eğer aktif program yoksa veya bugün hareket yoksa
            if (activeProgram == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.playlist_add_check_circle_outlined, size: 48, color: AppTheme.primaryNeon),
                        const SizedBox(height: 12),
                        const Text(
                          'Henüz Bir Antrenman Programı Seçmediniz',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Kendinize özel bir program oluşturabilir veya Topluluk kütüphanesindeki hazır split programlardan birini seçebilirsiniz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryNeon,
                            foregroundColor: AppTheme.background,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: widget.onNavigateToPrograms,
                          icon: const Icon(Icons.calendar_month_rounded, size: 18),
                          label: const Text('PROGRAMLARA GİT', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (todayDetails.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('🧘', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 10),
                        const Text(
                          'Bugün Dinlenme / Toparlanma Günü',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kaslarınız dinlenirken gelişir. Bol su için ve beslenmenize dikkat edin!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final detail = todayDetails[index];
                      final exercise = widget.exercises.firstWhere(
                        (e) => e.id == detail.exerciseId,
                        orElse: () => Exercise(
                          id: detail.exerciseId,
                          name: detail.exerciseId,
                          muscleGroup: MuscleGroup.chest,
                          equipment: 'Ekipman',
                        ),
                      );

                      return ExerciseCard(
                        key: ValueKey('${exercise.id}_$_selectedDay'),
                        exercise: exercise,
                        targetDetail: detail,
                        onLogWeight: (weight, reps, sets) {
                          widget.onLogWeight(exercise.id, weight, reps, sets);
                        },
                      );
                    },
                    childCount: todayDetails.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepPerformanceBanner() {
    final history = SleepTrackingService.sleepHistory;
    if (history.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final lastSleep = history.last;
    final hours = lastSleep.durationHours;

    final isLowSleep = hours < 6.5;
    final isGoodSleep = hours >= 7.5;

    final color = isGoodSleep ? AppTheme.primaryNeon : (isLowSleep ? const Color(0xFFEF4444) : const Color(0xFFFACC15));
    final icon = isGoodSleep ? '⚡' : (isLowSleep ? '⚠️' : '🔋');
    final title = isGoodSleep ? 'GÜÇ MODU: TİTAN PERFORMANS' : (isLowSleep ? 'DİKKAT: YETERSİZ UYKU & GÜÇ DÜŞÜŞÜ' : 'DENGELİ RECOVERY');
    final desc = isGoodSleep
        ? 'Dün gece ${hours.toStringAsFixed(1)} saat uyudun! Büyüme hormonu zirvede, bugün ağırlıkları parçalama ve PR kırma günü!'
        : (isLowSleep
            ? 'Dün gece sadece ${hours.toStringAsFixed(1)} saat uyudun. Sinir sistemi tam toparlanamadı, bugün formuna dikkat et ve yarın daha ağır kaldırmak için erken uyu!'
            : 'Dün gece ${hours.toStringAsFixed(1)} saat uyudun. Antrenmanda istikrarlı ve kontrollü tekrarlara odaklan.');

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
