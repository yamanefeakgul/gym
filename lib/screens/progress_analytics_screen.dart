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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelişim & İstatistikler'),
      ),
      body: ProgressAnalyticsContent(exercises: exercises),
    );
  }
}

class ProgressAnalyticsContent extends StatelessWidget {
  final List<Exercise> exercises;

  const ProgressAnalyticsContent({
    super.key,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    // Ağırlık geçmişi olan egzersizler
    final exercisesWithLogs = exercises.where((e) => e.history.isNotEmpty).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
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
                  'Henüz kaydedilmiş ağırlık verisi yok.\nAntrenman yaptıkça burası grafiklerle dolacak!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exercisesWithLogs.length,
              itemBuilder: (context, index) {
                final ex = exercisesWithLogs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(ex.muscleGroup.emoji, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text(
                                ex.name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.goldRank.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'PR: ${ex.personalRecordWeight.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                color: AppTheme.goldRank,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      MiniProgressChart(
                        exerciseName: ex.name,
                        history: ex.history,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBigThreeCard(List<Exercise> allExercises) {
    Exercise findEx(String id, String fallbackName) {
      return allExercises.firstWhere(
        (e) => e.id == id || e.name.toLowerCase().contains(fallbackName.toLowerCase()),
        orElse: () => Exercise(id: id, name: fallbackName, muscleGroup: MuscleGroup.chest, equipment: 'Barbell'),
      );
    }

    final bench = findEx('bench_press', 'Barbell Bench Press');
    final squat = findEx('barbell_squat', 'Barbell Back Squat');
    final deadlift = findEx('deadlift', 'Barbell Conventional Deadlift');

    final totalBig3 = bench.personalRecordWeight + squat.personalRecordWeight + deadlift.personalRecordWeight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.purpleXP.withOpacity(0.4), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.military_tech_rounded, color: AppTheme.purpleXP),
                  SizedBox(width: 8),
                  Text(
                    'BIG 3 TOPLAMI',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
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
