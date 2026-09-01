import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/workout_program.dart';
import '../theme/app_theme.dart';
import 'mini_progress_chart.dart';

class ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final ProgramExerciseDetail? targetDetail;
  final Function(double weight, int reps, int sets) onLogWeight;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.targetDetail,
    required this.onLogWeight,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> with SingleTickerProviderStateMixin {
  bool _isStatsExpanded = false;
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late TextEditingController _setsController;

  @override
  void initState() {
    super.initState();
    final last = widget.exercise.lastEntry;
    _weightController = TextEditingController(text: last != null ? '${last.weightKg}' : '');
    _repsController = TextEditingController(text: last != null ? '${last.reps}' : '');
    _setsController = TextEditingController(text: last != null ? '${last.sets}' : '3');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _setsController.dispose();
    super.dispose();
  }

  void _submitLog() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final reps = int.tryParse(_repsController.text) ?? 0;
    final sets = int.tryParse(_setsController.text) ?? 1;

    if (weight > 0 && reps > 0) {
      widget.onLogWeight(weight, reps, sets);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('⚡ +50 XP! ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Text(
                '${widget.exercise.name} kaydedildi ($weight kg × $reps)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A), // Canlı Yeşil
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final pr = widget.exercise.personalRecordWeight;
    final detail = widget.targetDetail;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isStatsExpanded ? AppTheme.primaryNeon.withOpacity(0.5) : AppTheme.surfaceBorder,
          width: _isStatsExpanded ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // Ana Başlık ve Hedef / PR Bilgisi
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.exercise.muscleGroup.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exercise.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            widget.exercise.equipment,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                          // Hedef Set x Rep & RIR / Failure Rozeti
                          if (detail != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                detail.setsReps,
                                style: const TextStyle(color: AppTheme.primaryAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: detail.intensity == IntensityTarget.rir0Failure
                                    ? Colors.red.withOpacity(0.2)
                                    : AppTheme.primaryNeon.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                detail.intensity.shortTag,
                                style: TextStyle(
                                  color: detail.intensity == IntensityTarget.rir0Failure
                                      ? Colors.redAccent
                                      : AppTheme.primaryNeon,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          if (pr > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppTheme.goldRank.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PR: ${pr.toStringAsFixed(1)} kg',
                                style: const TextStyle(color: AppTheme.goldRank, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // İstatistik Grafiği Aç/Kapa Butonu
                IconButton(
                  tooltip: 'Gelişim Çizelgesi',
                  onPressed: () {
                    setState(() {
                      _isStatsExpanded = !_isStatsExpanded;
                    });
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isStatsExpanded ? AppTheme.primaryNeon : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.auto_graph_rounded,
                      size: 18,
                      color: _isStatsExpanded ? AppTheme.background : AppTheme.primaryNeon,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppTheme.surfaceBorder, height: 1),

          // Hızlı Ağırlık Girme Input Alanı
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildInputField(
                    controller: _weightController,
                    label: 'Ağırlık',
                    unit: 'kg',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildInputField(
                    controller: _repsController,
                    label: 'Tekrar',
                    unit: 'rep',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildInputField(
                    controller: _setsController,
                    label: 'Set',
                    unit: 'set',
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _submitLog,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryNeon, Color(0xFF00C853)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryNeon.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, color: AppTheme.background, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'KAYDET',
                          style: TextStyle(
                            color: AppTheme.background,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Açılır İstatistik Çizelgesi
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: MiniProgressChart(
                history: widget.exercise.history,
                exerciseName: widget.exercise.name,
              ),
            ),
            crossFadeState: _isStatsExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Text(
                unit,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
