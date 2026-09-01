import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../models/workout_program.dart';
import '../../services/auth_service.dart';
import '../../services/program_service.dart';
import '../../theme/app_theme.dart';

class CreateProgramScreen extends StatefulWidget {
  final List<Exercise> allExercises;
  final WorkoutProgram? existingProgram; // Eğer düzenleniyorsa dolu gelir
  final VoidCallback onProgramCreated;

  const CreateProgramScreen({
    super.key,
    required this.allExercises,
    this.existingProgram,
    required this.onProgramCreated,
  });

  @override
  State<CreateProgramScreen> createState() => _CreateProgramScreenState();
}

class _CreateProgramScreenState extends State<CreateProgramScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _level;

  final Map<int, List<ProgramExerciseDetail>> _selectedExercisesPerDay = {
    1: [], // Pzt
    2: [], // Sal
    3: [], // Çar
    4: [], // Per
    5: [], // Cum
    6: [], // Cmt
    7: [], // Paz
  };

  final List<String> _dayNames = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existingProgram;
    _titleController = TextEditingController(text: p?.title ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _level = p?.level ?? 'Orta Seviye';

    if (p != null) {
      for (var day in p.schedule) {
        if (day.dayOfWeek >= 1 && day.dayOfWeek <= 7) {
          _selectedExercisesPerDay[day.dayOfWeek] = List.from(day.exercises);
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _pickExercisesForDay(int dayNum) {
    String searchQuery = '';
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentList = _selectedExercisesPerDay[dayNum]!;
            final filtered = widget.allExercises.where((e) {
              return searchQuery.isEmpty ||
                  e.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  e.muscleGroup.displayName.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_dayNames[dayNum - 1]} Hareketleri',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('BİTTİ', style: TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppTheme.primaryNeon, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: searchCtrl,
                            autofocus: false,
                            onChanged: (val) {
                              setModalState(() {
                                searchQuery = val;
                              });
                            },
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Hareket adı yazın (Örn: Chest Press, Lat...)',
                              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                            onPressed: () {
                              searchCtrl.clear();
                              setModalState(() => searchQuery = '');
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),
                  const SizedBox(height: 4),

                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final ex = filtered[index];
                        final existingIndex = currentList.indexWhere((e) => e.exerciseId == ex.id);
                        final isSelected = existingIndex != -1;
                        final detail = isSelected ? currentList[existingIndex] : null;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryNeon.withOpacity(0.08) : AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryNeon.withOpacity(0.4) : AppTheme.surfaceBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    activeColor: AppTheme.primaryNeon,
                                    checkColor: AppTheme.background,
                                    value: isSelected,
                                    onChanged: (val) {
                                      setModalState(() {
                                        if (val == true) {
                                          currentList.add(ProgramExerciseDetail(exerciseId: ex.id));
                                        } else {
                                          currentList.removeWhere((e) => e.exerciseId == ex.id);
                                        }
                                      });
                                      setState(() {});
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ex.name,
                                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Text(
                                          '${ex.muscleGroup.displayName} • ${ex.equipment}',
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (isSelected && detail != null) ...[
                                const Divider(color: AppTheme.surfaceBorder, height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.background,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: TextField(
                                          controller: TextEditingController(text: detail.setsReps),
                                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            labelText: 'Set × Rep',
                                            labelStyle: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                            border: InputBorder.none,
                                          ),
                                          onChanged: (val) {
                                            final idx = currentList.indexWhere((e) => e.exerciseId == ex.id);
                                            if (idx != -1) {
                                              currentList[idx] = ProgramExerciseDetail(
                                                exerciseId: ex.id,
                                                setsReps: val,
                                                intensity: detail.intensity,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.background,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<IntensityTarget>(
                                            value: detail.intensity,
                                            dropdownColor: AppTheme.surface,
                                            style: const TextStyle(color: AppTheme.primaryNeon, fontSize: 11, fontWeight: FontWeight.bold),
                                            items: IntensityTarget.values.map((target) {
                                              return DropdownMenuItem(
                                                value: target,
                                                child: Text(target.shortTag),
                                              );
                                            }).toList(),
                                            onChanged: (newTarget) {
                                              if (newTarget != null) {
                                                setModalState(() {
                                                  final idx = currentList.indexWhere((e) => e.exerciseId == ex.id);
                                                  if (idx != -1) {
                                                    currentList[idx] = ProgramExerciseDetail(
                                                      exerciseId: ex.id,
                                                      setsReps: detail.setsReps,
                                                      intensity: newTarget,
                                                    );
                                                  }
                                                });
                                                setState(() {});
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
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

  void _saveProgram() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen program başlığı girin.')),
      );
      return;
    }

    final activeUser = AuthService.currentUser;
    final schedule = <WorkoutDay>[];
    int activeDays = 0;

    for (int d = 1; d <= 7; d++) {
      final list = _selectedExercisesPerDay[d]!;
      if (list.isNotEmpty) activeDays++;
      schedule.add(
        WorkoutDay(
          dayOfWeek: d,
          title: '${_dayNames[d - 1]} Antrenmanı',
          exercises: list,
        ),
      );
    }

    final isEdit = widget.existingProgram != null;
    final programId = isEdit ? widget.existingProgram!.id : 'custom_${DateTime.now().millisecondsSinceEpoch}';

    final updatedProgram = WorkoutProgram(
      id: programId,
      title: title,
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : 'Kişisel özel antrenman programı.',
      authorName: widget.existingProgram?.authorName ?? (activeUser?.username ?? 'Sporcu'),
      level: _level,
      daysPerWeek: activeDays,
      schedule: schedule,
    );

    await ProgramService.saveOrUpdateProgram(updatedProgram);
    await ProgramService.setActiveProgram(updatedProgram);
    widget.onProgramCreated();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingProgram != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Programı Düzenle' : 'Yeni Program Oluştur'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(
              controller: _titleController,
              label: 'Program Adı',
              hint: 'Örn: 5 Günlük RIR/Failure Split',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _descController,
              label: 'Açıklama / Hedef',
              hint: 'Örn: Maksimum hipertrofi için RIR odaklı program',
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            const Text(
              'Zorluk Seviyesi',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _level,
                  isExpanded: true,
                  dropdownColor: AppTheme.surface,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  items: ['Başlangıç', 'Orta Seviye', 'İleri Seviye', 'Elit'].map((l) {
                    return DropdownMenuItem(value: l, child: Text(l));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _level = val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'HAFTALIK GÜNLER VE HAREKETLER',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),

            ...List.generate(7, (index) {
              final dayNum = index + 1;
              final dayName = _dayNames[index];
              final list = _selectedExercisesPerDay[dayNum]!;
              final count = list.length;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: count > 0 ? AppTheme.primaryNeon.withOpacity(0.4) : AppTheme.surfaceBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dayName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            count == 0 ? 'Dinlenme Günü' : '$count Hareket Eklendi',
                            style: TextStyle(
                              color: count == 0 ? AppTheme.textMuted : AppTheme.primaryNeon,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: count > 0 ? AppTheme.surfaceLight : AppTheme.surfaceBorder,
                        foregroundColor: count > 0 ? AppTheme.primaryNeon : AppTheme.textSecondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _pickExercisesForDay(dayNum),
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: Text(count > 0 ? 'Düzenle ($count)' : 'Hareket Ara & Ekle'),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _saveProgram,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNeon,
                foregroundColor: AppTheme.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                isEdit ? 'DEĞİŞİKLİKLERİ KAYDET' : 'PROGRAMI OLUŞTUR VE AKTİF ET',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
