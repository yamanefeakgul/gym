import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../models/workout_program.dart';
import '../../services/api_service.dart';
import '../../services/program_service.dart';
import '../../theme/app_theme.dart';
import 'create_program_screen.dart';

class ProgramsListTab extends StatefulWidget {
  final List<Exercise> allExercises;
  final VoidCallback onProgramSelected;

  const ProgramsListTab({
    super.key,
    required this.allExercises,
    required this.onProgramSelected,
  });

  @override
  State<ProgramsListTab> createState() => _ProgramsListTabState();
}

class _ProgramsListTabState extends State<ProgramsListTab> {
  int _selectedFilter = 0; // 0: Tümü, 1: Programlarım, 2: Topluluk
  List<WorkoutProgram> _cloudPrograms = [];
  bool _isLoadingCloud = false;

  @override
  void initState() {
    super.initState();
    _fetchCloudPrograms();
  }

  void _fetchCloudPrograms() async {
    setState(() => _isLoadingCloud = true);
    final progs = await ApiService.fetchCloudPrograms();
    if (mounted) {
      setState(() {
        _cloudPrograms = progs;
        _isLoadingCloud = false;
      });
    }
  }

  void _activateProgram(WorkoutProgram program) async {
    await ProgramService.setActiveProgram(program);
    widget.onProgramSelected();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚡ "${program.title}" aktif antrenman programınız olarak ayarlandı!',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF16A34A), // Canlı Yeşil
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _publishProgram(WorkoutProgram program) async {
    final success = await ApiService.saveProgramToCloud(program);
    if (success) {
      _fetchCloudPrograms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🌍 "${program.title}" VDS Sunucusuna başarıyla yüklendi! Herkes görebilir.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF16A34A), // Canlı Yeşil
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '⚠️ Sunucuya bağlanırken hata oluştu. Lütfen VDS bağlantınızı kontrol edin.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _editProgram(WorkoutProgram program) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProgramScreen(
          allExercises: widget.allExercises,
          existingProgram: program,
          onProgramCreated: () {
            widget.onProgramSelected();
            setState(() {});
          },
        ),
      ),
    );
  }

  void _deleteProgram(WorkoutProgram program) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Programı Sil', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('"${program.title}" programını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ProgramService.deleteProgram(program.id);
      widget.onProgramSelected();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeProg = ProgramService.getActiveProgram();
    final Map<String, WorkoutProgram> mergedMap = {};
    for (var p in _cloudPrograms) {
      mergedMap[p.id] = p;
    }
    for (var p in ProgramService.customPrograms) {
      mergedMap[p.id] = p; // Kullanıcının özel programı önceliklidir
    }
    final allPrograms = mergedMap.values.toList();

    List<WorkoutProgram> displayed = [];
    if (_selectedFilter == 0) {
      displayed = allPrograms;
    } else if (_selectedFilter == 1) {
      displayed = ProgramService.customPrograms;
    } else {
      displayed = _cloudPrograms;
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNeon,
        foregroundColor: AppTheme.background,
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, anim, _) => CreateProgramScreen(
                allExercises: widget.allExercises,
                onProgramCreated: () {
                  widget.onProgramSelected();
                  setState(() {});
                },
              ),
              transitionsBuilder: (context, anim, _, child) {
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
                  child: child,
                );
              },
            ),
          );
        },
        icon: const Icon(Icons.add_rounded, fontWeight: FontWeight.bold),
        label: const Text('PROGRAM OLUŞTUR', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Aktif Program Durum Kartı
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: activeProg != null ? AppTheme.purpleXP.withOpacity(0.5) : AppTheme.surfaceBorder,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (activeProg != null ? AppTheme.purpleXP : AppTheme.surfaceBorder).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      activeProg != null ? Icons.star_rounded : Icons.info_outline_rounded,
                      color: activeProg != null ? AppTheme.goldRank : AppTheme.textMuted,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeProg != null ? 'ŞU ANKİ AKTİF PROGRAMINIZ' : 'AKTİF PROGRAM SEÇİLMEDİ',
                          style: TextStyle(
                            color: activeProg != null ? AppTheme.goldRank : AppTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeProg?.title ?? 'Aşağıdan bir program seçin veya oluşturun',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        if (activeProg != null)
                          Text(
                            '${activeProg.daysPerWeek} Gün / Hafta • ${activeProg.level}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Segmented Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Row(
                children: [
                  _buildSegment(0, 'Tümü (${allPrograms.length})'),
                  _buildSegment(1, 'Özel (${ProgramService.customPrograms.length})'),
                  _buildSegment(2, 'Topluluk (${_cloudPrograms.length})'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Program Listesi
          Expanded(
            child: displayed.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fitness_center_outlined, size: 48, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'Henüz bu kategoride program bulunmuyor.',
                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '"Program Oluştur" butonuna basarak ilk programınızı oluşturun.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: displayed.length,
                    itemBuilder: (context, index) {
                      final prog = displayed[index];
                      final isActive = activeProg?.id == prog.id;
                      final isCustom = ProgramService.customPrograms.any((p) => p.id == prog.id);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isActive ? AppTheme.primaryNeon : AppTheme.surfaceBorder,
                            width: isActive ? 1.5 : 1.0,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryNeon.withOpacity(0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            prog.title,
                                            style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (prog.isCommunity) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryAccent.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'VDS TOPLULUK',
                                                style: TextStyle(color: AppTheme.primaryAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Hazırlayan: ${prog.authorName} • ${prog.daysPerWeek} Gün/Hafta • ${prog.level}',
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isCustom) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryAccent, size: 22),
                                    tooltip: 'Programı Düzenle',
                                    onPressed: () => _editProgram(prog),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    tooltip: 'Programı Sil',
                                    onPressed: () => _deleteProgram(prog),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              prog.description,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: AppTheme.surfaceBorder, height: 1),
                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (isCustom)
                                  TextButton.icon(
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                    onPressed: () => _publishProgram(prog),
                                    icon: const Icon(Icons.cloud_upload_rounded, color: AppTheme.primaryAccent, size: 16),
                                    label: const Text('Sunucuda Yayınla', style: TextStyle(color: AppTheme.primaryAccent, fontSize: 12)),
                                  )
                                else
                                  const Text('VDS Bulut Programı', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),

                                if (isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryNeon.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: AppTheme.primaryNeon, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          'AKTİF PROGRAM',
                                          style: TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.surfaceLight,
                                      foregroundColor: AppTheme.textPrimary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    onPressed: () => _activateProgram(prog),
                                    child: const Text('BU PROGRAMI SEÇ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(int index, String label) {
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryNeon : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.background : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
