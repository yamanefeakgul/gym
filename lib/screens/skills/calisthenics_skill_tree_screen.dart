import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/visual_skill_tree.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/program_service.dart';
import '../../services/exercise_database.dart';
import '../../theme/app_theme.dart';

class CalisthenicsSkillTreeScreen extends StatefulWidget {
  final UserProfile profile;

  const CalisthenicsSkillTreeScreen({
    super.key,
    required this.profile,
  });

  @override
  State<CalisthenicsSkillTreeScreen> createState() => _CalisthenicsSkillTreeScreenState();
}

class _CalisthenicsSkillTreeScreenState extends State<CalisthenicsSkillTreeScreen> {
  late List<VisualSkillNode> _nodes;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _nodes = CalisthenicsVisualTreeData.getNodes();
    _syncWithProfile();
    // Başlangıçta ağacın merkezine ve İp Atlama / Calisthenics dallarına dengeli odaklan
    _transformationController.value = Matrix4.identity()
      ..scale(0.60)
      ..translate(-250.0, -150.0);
  }

  void _syncWithProfile() {
    final masteredIds = widget.profile.unlockedBadges; // sunucudan gelen master listesi
    for (var node in _nodes) {
      if (masteredIds.contains('skill_${node.id}')) {
        node.state = SkillNodeState.mastered;
      }
    }
  }

  void _onNodeTap(VisualSkillNode node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Color stateColor = Colors.grey;
            String stateLabel = 'KİLİTLİ (LOCKED)';
            if (node.state == SkillNodeState.mastered) {
              stateColor = const Color(0xFF84CC16);
              stateLabel = 'USTALAŞILDI (12s+ HOLD / 6+ REPS) 🏆';
            } else if (node.state == SkillNodeState.inProgress) {
              stateColor = const Color(0xFFF472B6);
              stateLabel = 'GELİŞİMDE (6s HOLD / 3 REPS) ⚡';
            } else if (node.state == SkillNodeState.unlocked) {
              stateColor = Colors.white;
              stateLabel = 'AÇILDI (2s HOLD / 1 REP) 🔓';
            }

            return Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: stateColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: stateColor, width: 2),
                        ),
                        child: Icon(
                          node.state == SkillNodeState.mastered
                              ? Icons.emoji_events_rounded
                              : (node.state == SkillNodeState.locked ? Icons.lock_outline_rounded : Icons.fitness_center_rounded),
                          color: stateColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              node.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${node.branch} • $stateLabel',
                              style: TextStyle(color: stateColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.surfaceBorder),
                  const SizedBox(height: 8),

                  const Text(
                    'BECERİ AÇIKLAMASI & HEDEF',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    node.description,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Durum Değiştirme Butonları (Oyun Tarzı İlerleme)
                  const Text(
                    'DURUMUNU GÜNCELLE (SUNUCUYA KAYDOLUR)',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildStateOption(
                        label: 'AÇIK (1 Rep)',
                        color: Colors.white,
                        isSelected: node.state == SkillNodeState.unlocked,
                        onTap: () => _updateNodeState(node, SkillNodeState.unlocked, setSheetState),
                      ),
                      const SizedBox(width: 8),
                      _buildStateOption(
                        label: 'GELİŞİMDE (3 Rep)',
                        color: const Color(0xFFF472B6),
                        isSelected: node.state == SkillNodeState.inProgress,
                        onTap: () => _updateNodeState(node, SkillNodeState.inProgress, setSheetState),
                      ),
                      const SizedBox(width: 8),
                      _buildStateOption(
                        label: 'USTA (6+ Rep)',
                        color: const Color(0xFF84CC16),
                        isSelected: node.state == SkillNodeState.mastered,
                        onTap: () => _updateNodeState(node, SkillNodeState.mastered, setSheetState),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStateOption({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppTheme.surfaceBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateNodeState(VisualSkillNode node, SkillNodeState newState, StateSetter setSheetState) {
    setState(() {
      node.state = newState;
      if (newState == SkillNodeState.mastered) {
        if (!widget.profile.unlockedBadges.contains('skill_${node.id}')) {
          widget.profile.unlockedBadges.add('skill_${node.id}');
        }
      }
    });
    setSheetState(() {});

    // VDS Bulut Sunucusuna anında canlı sync
    final user = AuthService.currentUser;
    if (user != null) {
      final allExercises = ExerciseDatabase.getAllExercises();
      final masteredList = _nodes.where((n) => n.state == SkillNodeState.mastered).map((n) => n.id).toList();
      ApiService.syncUserData(user.id, widget.profile, ProgramService.activeProgramId, allExercises, masteredList);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('Kalisnetiks Yetenek Ağacı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong_rounded, color: AppTheme.primaryNeon),
            tooltip: 'Merkeze Odaklan',
            onPressed: () {
              setState(() {
                _transformationController.value = Matrix4.identity()
                  ..scale(0.60)
                  ..translate(-250.0, -150.0);
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // İnteraktif Yakınlaştırılabilir & Kaydırılabilir RPG Ağaç Canvas
          InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(500),
            minScale: 0.35,
            maxScale: 2.5,
            constrained: false,
            child: SizedBox(
              width: 1500,
              height: 1350,
              child: CustomPaint(
                painter: SkillTreeCanvasPainter(nodes: _nodes),
                child: Stack(
                  children: _nodes.map((node) {
                    Color nodeColor = const Color(0xFF475569); // Gri Locked
                    if (node.state == SkillNodeState.mastered) {
                      nodeColor = const Color(0xFF84CC16); // Yeşil Mastered
                    } else if (node.state == SkillNodeState.inProgress) {
                      nodeColor = const Color(0xFFF472B6); // Pembe In Progress
                    } else if (node.state == SkillNodeState.unlocked) {
                      nodeColor = Colors.white; // Beyaz Unlocked
                    }

                    return Positioned(
                      left: node.position.dx - 18,
                      top: node.position.dy - 18,
                      child: GestureDetector(
                        onTap: () => _onNodeTap(node),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            shape: BoxShape.circle,
                            border: Border.all(color: nodeColor, width: 2.2),
                            boxShadow: node.state != SkillNodeState.locked
                                ? [
                                    BoxShadow(
                                      color: nodeColor.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Icon(
                              node.state == SkillNodeState.mastered
                                  ? Icons.check
                                  : (node.state == SkillNodeState.locked ? Icons.lock_outline_rounded : Icons.circle),
                              size: 14,
                              color: nodeColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Görsel 1'deki Lejant (Sağ/Sol Açıklama Kutusu)
          Positioned(
            bottom: 20,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFF475569), size: 10),
                      SizedBox(width: 6),
                      Text('- LOCKED', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 10),
                      SizedBox(width: 6),
                      Text('- UNLOCKED (2S HOLD / 1 REP)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFFF472B6), size: 10),
                      SizedBox(width: 6),
                      Text('- IN PROGRESS (6S HOLD / 3 REPS)', style: TextStyle(color: Color(0xFFF472B6), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFF84CC16), size: 10),
                      SizedBox(width: 6),
                      Text('- MASTERED (12S+ HOLD / 6+ REPS)', style: TextStyle(color: Color(0xFF84CC16), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Görseldeki gibi dalları ve metinleri çizen CustomPainter
class SkillTreeCanvasPainter extends CustomPainter {
  final List<VisualSkillNode> nodes;

  SkillTreeCanvasPainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final Map<String, VisualSkillNode> nodeMap = {for (var n in nodes) n.id: n};

    // 1. DALLARI ÇİZ (Çizgiler ve ok bağlantıları)
    for (var node in nodes) {
      for (var childId in node.childrenIds) {
        final child = nodeMap[childId];
        if (child != null) {
          final isUnlocked = node.state == SkillNodeState.mastered;
          final paint = Paint()
            ..color = isUnlocked ? const Color(0xFF84CC16).withOpacity(0.6) : const Color(0xFF334155)
            ..strokeWidth = isUnlocked ? 2.0 : 1.2
            ..style = PaintingStyle.stroke;

          canvas.drawLine(node.position, child.position, paint);
        }
      }
    }

    // 2. BÖLGE İSİMLERİNİ YAZ
    _drawBranchTitle(canvas, '🪢 JUMP ROPE & FREESTYLE', const Offset(620, 25));
    _drawBranchTitle(canvas, '🏹 VERTICAL PUSH (AMUT)', const Offset(120, 120));
    _drawBranchTitle(canvas, '🦅 VERTICAL PULL (BARFİKS)', const Offset(1050, 190));
    _drawBranchTitle(canvas, '🛡️ HORIZONTAL PUSH (PLANCHE)', const Offset(50, 680));
    _drawBranchTitle(canvas, '⛓️ HORIZONTAL PULL (LEVER)', const Offset(1050, 930));
    _drawBranchTitle(canvas, '🧱 CORE (MERKEZ)', const Offset(680, 660));
    _drawBranchTitle(canvas, '🦵 LEGS (BACAK)', const Offset(700, 1210));
  }

  void _drawBranchTitle(Canvas canvas, String text, Offset position) {
    const textStyle = TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 13,
      fontWeight: FontWeight.w900,
      letterSpacing: 2.0,
      fontFamily: 'monospace',
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
