import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_progress_chart.dart';
import 'programs/programs_list_tab.dart';

class LibraryScreenContainer extends StatefulWidget {
  final List<Exercise> exercises;
  final Function(String exerciseId, double weight, int reps, int sets) onLogWeight;
  final VoidCallback onProgramChanged;

  const LibraryScreenContainer({
    super.key,
    required this.exercises,
    required this.onLogWeight,
    required this.onProgramChanged,
  });

  @override
  State<LibraryScreenContainer> createState() => _LibraryScreenContainerState();
}

class _LibraryScreenContainerState extends State<LibraryScreenContainer> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kütüphane & Programlar'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryNeon,
          labelColor: AppTheme.primaryNeon,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.fitness_center_rounded), text: 'Egzersizler'),
            Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Programlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ExerciseLibraryTab(exercises: widget.exercises),
          ProgramsListTab(
            allExercises: widget.exercises,
            onProgramSelected: widget.onProgramChanged,
          ),
        ],
      ),
    );
  }
}

class ExerciseLibraryTab extends StatefulWidget {
  final List<Exercise> exercises;

  const ExerciseLibraryTab({
    super.key,
    required this.exercises,
  });

  @override
  State<ExerciseLibraryTab> createState() => _ExerciseLibraryTabState();
}

class _ExerciseLibraryTabState extends State<ExerciseLibraryTab> {
  MuscleGroup? _selectedGroup;
  String _searchQuery = '';
  final Map<String, bool> _expandedState = {};

  @override
  Widget build(BuildContext context) {
    final filteredExercises = widget.exercises.where((exercise) {
      final matchesGroup = _selectedGroup == null || exercise.muscleGroup == _selectedGroup;
      final matchesSearch = exercise.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesGroup && matchesSearch;
    }).toList();

    return Column(
      children: [
        // Arama Çubuğu
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Egzersiz ara (Örn: Chest Press, Bench, Row)...',
                hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),

        // Kas Grubu Filtreleri
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _buildFilterChip('TÜMÜ', null),
              ...MuscleGroup.values.map((group) {
                return _buildFilterChip(group.displayName.toUpperCase(), group);
              }),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Egzersizler Listesi: Sadece İsim ve Ağırlık Gelişim Tablosu / Grafiği
        Expanded(
          child: filteredExercises.isEmpty
              ? const Center(
                  child: Text('Egzersiz bulunamadı.', style: TextStyle(color: AppTheme.textMuted)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                  itemCount: filteredExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = filteredExercises[index];
                    final isExpanded = _expandedState[exercise.id] ?? false;
                    final hasHistory = exercise.history.isNotEmpty;
                    final pr = exercise.personalRecordWeight;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isExpanded ? AppTheme.primaryNeon : AppTheme.surfaceBorder),
                      ),
                      child: Column(
                        children: [
                          // Egzersiz Başlık Satırı
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() {
                                _expandedState[exercise.id] = !isExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryNeon.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(exercise.muscleGroup.emoji, style: const TextStyle(fontSize: 20)),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise.name,
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${exercise.muscleGroup.displayName} • ${exercise.equipment}',
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // İstatistik / Grafik Aç Kapa Butonu
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isExpanded ? AppTheme.primaryNeon : AppTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.auto_graph_rounded,
                                          color: isExpanded ? AppTheme.background : AppTheme.primaryNeon,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Gelişim',
                                          style: TextStyle(
                                            color: isExpanded ? AppTheme.background : AppTheme.primaryNeon,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Açılır Gelişim Tablosu ve Çizge Grafiği
                          if (isExpanded) ...[
                            const Divider(color: AppTheme.surfaceBorder, height: 1),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'AĞIRLIK & 1RM GELİŞİM ÇİZELGESİ',
                                        style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                      ),
                                      if (hasHistory)
                                        Text(
                                          'PR: ${pr.toStringAsFixed(1)} KG',
                                          style: const TextStyle(color: AppTheme.primaryNeon, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  MiniProgressChart(
                                    history: exercise.history,
                                    exerciseName: exercise.name,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, MuscleGroup? group) {
    final isSelected = _selectedGroup == group;
    return GestureDetector(
      onTap: () => setState(() => _selectedGroup = group),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryNeon : AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? AppTheme.primaryNeon : AppTheme.surfaceBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.background : AppTheme.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
