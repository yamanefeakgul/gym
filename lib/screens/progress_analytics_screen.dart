import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_progress_chart.dart';

class ProgressAnalyticsScreen extends StatelessWidget {
  final List<Exercise> exercises;

  const ProgressAnalyticsScreen({
    super.key,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    // Ağırlık geçmişi olan egzersizler
    final exercisesWithLogs = exercises.where((e) => e.history.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelişim & İstatistikler'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PR Rekor Özeti Kartları
            const Text(
              'GÜÇ REKORLARI (PERSONAL RECORDS)',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),

            // Big 3 (Squat, Bench, Deadlift)
            _buildBigThreeCard(exercises),

            const SizedBox(height: 20),

            // Detaylı Hareket Gelişim Grafikleri
            const Text(
              'EGZERSİZ BAZLI GELİŞİM ÇİZELGELERİ',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            if (exercisesWithLogs.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: const Center(
                  child: Text(
                    'Henüz antrenman ağırlığı girilmedi.\nAna sayfadan hareketlerinize ağırlık girerek grafikleri açabilirsiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              )
            else
              ...exercisesWithLogs.map((exercise) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(exercise.muscleGroup.emoji, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(
                                  exercise.name,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryNeon.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Max: ${exercise.personalRecordWeight} kg',
                                style: const TextStyle(
                                  color: AppTheme.primaryNeon,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: MiniProgressChart(
                          history: exercise.history,
                          exerciseName: exercise.name,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBigThreeCard(List<Exercise> exercises) {
    final bench = exercises.firstWhere((e) => e.id == 'bench_press', orElse: () => exercises.first);
    final squat = exercises.firstWhere((e) => e.id == 'barbell_squat', orElse: () => exercises.first);
    final deadlift = exercises.firstWhere((e) => e.id == 'deadlift', orElse: () => exercises.first);

    final totalBig3 = bench.personalRecordWeight + squat.personalRecordWeight + deadlift.personalRecordWeight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.purpleXP.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '👑 Big 3 Güç Toplamı',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.purpleXP,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${totalBig3.toStringAsFixed(1)} KG',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBig3Item('Bench Press', bench.personalRecordWeight, '🛡️'),
              _buildBig3Item('Squat', squat.personalRecordWeight, '🦵'),
              _buildBig3Item('Deadlift', deadlift.personalRecordWeight, '🦅'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBig3Item(String name, double weight, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          '${weight.toStringAsFixed(1)} kg',
          style: const TextStyle(
            color: AppTheme.primaryNeon,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
