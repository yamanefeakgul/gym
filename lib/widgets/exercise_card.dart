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
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetDetail != widget.targetDetail || oldWidget.exercise != widget.exercise) {
      _initControllers();
    }
  }

  void _initControllers() {
    final last = widget.exercise.lastEntry;
    String initialSets = '3';
    String initialReps = '10';

    // 🌟 Programa göre varsayılan Set & Rep değerlerini otomatik doldur (Örn: "3x10", "2x5-6")
    if (widget.targetDetail != null && widget.targetDetail!.setsReps.isNotEmpty) {
      final text = widget.targetDetail!.setsReps.toLowerCase().trim();
      if (text.contains('x')) {
        final parts = text.split('x');
        if (parts.isNotEmpty) {
          initialSets = parts[0].trim();
        }
        if (parts.length > 1) {
          final repPart = parts[1].trim();
          if (repPart.contains('-')) {
            initialReps = repPart.split('-')[0].trim(); // "5-6" -> "5"
          } else {
            initialReps = repPart;
          }
        }
      }
    } else if (last != null) {
      initialSets = '${last.sets}';
      initialReps = '${last.reps}';
    }

    _weightController = TextEditingController(text: last != null ? '${last.weightKg}' : '');
    _repsController = TextEditingController(text: initialReps);
    _setsController = TextEditingController(text: initialSets);
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
                '${widget.exercise.name} kaydedildi ($weight kg × $reps rep × $sets set)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir ağırlık ve tekrar girin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pr = widget.exercise.personalRecordWeight;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.targetDetail != null ? AppTheme.primaryNeon.withOpacity(0.4) : AppTheme.surfaceBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Başlık & Hedef Bilgisi
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Kas Grubu Rozeti
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Center(
                    child: Text(
                      widget.exercise.muscleGroup.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Egzersiz İsmi ve Hedef
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
                      Row(
                        children: [
                          Text(
                            widget.exercise.equipment,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                          if (widget.targetDetail != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF38BDF8), width: 0.8),
                              ),
                              child: Text(
                                widget.targetDetail!.setsReps,
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF16A34A), width: 0.8),
                              ),
                              child: Text(
                                widget.targetDetail!.intensity.shortTag,
                                style: const TextStyle(
                                  color: Color(0xFF4ADE80),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          if (pr > 0 && widget.targetDetail == null)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.goldRank.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
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

          // Hızlı Ağırlık Girme Input Alanı (Set & Rep otomatik seçili gelir)
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: AppTheme.background, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'KAYDET',
                          style: TextStyle(
                            color: AppTheme.background,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Açılır Gelişim Grafiği & Geçmiş
          if (_isStatsExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: MiniProgressChart(
                exerciseName: widget.exercise.name,
                history: widget.exercise.history,
              ),
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
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
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
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
              Text(
                unit,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
