import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/exercise.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';

enum MuscleRank {
  unranked(0, 'BAŞLANGIÇ', Colors.transparent),
  wood(1, 'ODUN', Color(0xFF8D6E63)),
  bronze(2, 'BRONZ', Color(0xFFCD7F32)),
  silver(3, 'GÜMÜŞ', Color(0xFFCBD5E1)),
  gold(4, 'ALTIN', Color(0xFFFBBF24)),
  plat(5, 'PLAT', Color(0xFF38BDF8)),
  diamond(6, 'ELMAS', Color(0xFFA855F7)),
  champion(7, 'ŞAMPİYON', Color(0xFFEC4899)),
  titan(8, 'TİTAN', Color(0xFFEF4444)),
  olympian(9, 'OLİMPİYATÇI', Color(0xFF10B981));

  final int level;
  final String title;
  final Color color;

  const MuscleRank(this.level, this.title, this.color);

  static MuscleRank fromLevel(int lvl) {
    if (lvl <= 0) return MuscleRank.unranked;
    if (lvl == 1) return MuscleRank.wood;
    if (lvl == 2) return MuscleRank.bronze;
    if (lvl == 3) return MuscleRank.silver;
    if (lvl == 4) return MuscleRank.gold;
    if (lvl == 5) return MuscleRank.plat;
    if (lvl == 6) return MuscleRank.diamond;
    if (lvl == 7) return MuscleRank.champion;
    if (lvl == 8) return MuscleRank.titan;
    return MuscleRank.olympian;
  }
}

// Alt Kas Grubu Bilgisi (Ara Grup)
class SubMuscleData {
  final String id;
  final String name;
  final MuscleRank rank;
  final int sets;
  final double volumeKg;

  SubMuscleData({
    required this.id,
    required this.name,
    required this.rank,
    required this.sets,
    required this.volumeKg,
  });

  /// 🌟 3 Kademeli Gösterim (Örn: Gümüş III, Bronz II)
  String get rankDisplayName {
    if (rank == MuscleRank.unranked) return 'BAŞLANGIÇ';
    final userScore = volumeKg + (sets * 120);
    int sub = 1;
    switch (rank) {
      case MuscleRank.wood:
        sub = userScore > 250 ? 3 : (userScore > 100 ? 2 : 1);
        break;
      case MuscleRank.bronze:
        sub = userScore > 900 ? 3 : (userScore > 650 ? 2 : 1);
        break;
      case MuscleRank.silver:
        sub = userScore > 2000 ? 3 : (userScore > 1600 ? 2 : 1);
        break;
      case MuscleRank.gold:
        sub = userScore > 3800 ? 3 : (userScore > 3100 ? 2 : 1);
        break;
      case MuscleRank.plat:
        sub = userScore > 6500 ? 3 : (userScore > 5500 ? 2 : 1);
        break;
      case MuscleRank.diamond:
        sub = userScore > 10500 ? 3 : (userScore > 9000 ? 2 : 1);
        break;
      case MuscleRank.champion:
        sub = userScore > 16000 ? 3 : (userScore > 14000 ? 2 : 1);
        break;
      case MuscleRank.titan:
        sub = userScore > 23000 ? 3 : (userScore > 20500 ? 2 : 1);
        break;
      case MuscleRank.olympian:
        sub = userScore > 35000 ? 3 : (userScore > 30000 ? 2 : 1);
        break;
      default:
        sub = 1;
    }
    final roman = sub == 1 ? 'I' : (sub == 2 ? 'II' : 'III');
    return '${rank.title} $roman';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rank': rank.name,
        'sets': sets,
        'volumeKg': volumeKg,
      };

  factory SubMuscleData.fromJson(Map<String, dynamic> json) {
    final rName = json['rank'] ?? 'bronze';
    final rank = MuscleRank.values.firstWhere((e) => e.name == rName, orElse: () => MuscleRank.bronze);
    return SubMuscleData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      rank: rank,
      sets: json['sets'] ?? 0,
      volumeKg: (json['volumeKg'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// Ana Kas Grubu Bilgisi (Ara grupların ortalamasıyla rank belirlenir)
class MainMuscleGroupData {
  final String id;
  final String name;
  final String emoji;
  final List<SubMuscleData> subMuscles;

  MainMuscleGroupData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.subMuscles,
  });

  // Ara grupların ortalama rütbesi
  MuscleRank get averageRank {
    if (subMuscles.isEmpty) return MuscleRank.unranked;
    final totalLevel = subMuscles.fold<int>(0, (sum, sub) => sum + sub.rank.level);
    final avg = (totalLevel / subMuscles.length).round();
    return MuscleRank.fromLevel(avg);
  }

  String get averageRankDisplayName {
    if (averageRank == MuscleRank.unranked) return 'BAŞLANGIÇ';
    // Alt kasların kademe ortalaması
    return averageRank.title;
  }

  int get totalSets => subMuscles.fold<int>(0, (sum, sub) => sum + sub.sets);
  double get totalVolume => subMuscles.fold<double>(0.0, (sum, sub) => sum + sub.volumeKg);

  SubMuscleData? getSub(String id) {
    try {
      return subMuscles.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

class BodyGraphScreen extends StatefulWidget {
  final UserProfile profile;
  final List<Exercise> exercises;

  const BodyGraphScreen({
    super.key,
    required this.profile,
    this.exercises = const [],
  });

  @override
  State<BodyGraphScreen> createState() => _BodyGraphScreenState();
}

class _BodyGraphScreenState extends State<BodyGraphScreen> {
  String? _expandedMainGroupId = 'chest'; // Varsayılan açık akordeon
  String? _selectedSubMuscleId = 'chest_upper'; // Seçili ara kas

  List<MainMuscleGroupData> _groups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _computeMuscleRanks();
  }

  void _computeMuscleRanks() async {
    setState(() => _isLoading = true);

    // Egzersiz eşleştirmeleri ve hacim dağılımı
    final Map<String, double> subVolume = {};
    final Map<String, int> subSets = {};

    for (final ex in widget.exercises) {
      final nameLower = ex.name.toLowerCase();
      int sCount = 0;
      double vol = 0.0;
      for (final h in ex.history) {
        sCount += h.sets;
        vol += (h.weightKg * h.reps * h.sets);
      }

      // Ana / Alt Kas Eşleştirmesi
      if (ex.muscleGroup == MuscleGroup.chest) {
        if (nameLower.contains('incline') || nameLower.contains('üst')) {
          subVolume['chest_upper'] = (subVolume['chest_upper'] ?? 0) + vol;
          subSets['chest_upper'] = (subSets['chest_upper'] ?? 0) + sCount;
        } else {
          subVolume['chest_lower'] = (subVolume['chest_lower'] ?? 0) + vol;
          subSets['chest_lower'] = (subSets['chest_lower'] ?? 0) + sCount;
        }
      } else if (ex.muscleGroup == MuscleGroup.back) {
        if (nameLower.contains('lat') || nameLower.contains('pulldown') || nameLower.contains('kanat')) {
          subVolume['back_lats'] = (subVolume['back_lats'] ?? 0) + vol;
          subSets['back_lats'] = (subSets['back_lats'] ?? 0) + sCount;
        } else if (nameLower.contains('deadlift') || nameLower.contains('hyperextension') || nameLower.contains('alt')) {
          subVolume['back_lower'] = (subVolume['back_lower'] ?? 0) + vol;
          subSets['back_lower'] = (subSets['back_lower'] ?? 0) + sCount;
        } else if (nameLower.contains('shrug') || nameLower.contains('trapez')) {
          subVolume['back_traps'] = (subVolume['back_traps'] ?? 0) + vol;
          subSets['back_traps'] = (subSets['back_traps'] ?? 0) + sCount;
        } else {
          subVolume['back_upper'] = (subVolume['back_upper'] ?? 0) + vol;
          subSets['back_upper'] = (subSets['back_upper'] ?? 0) + sCount;
        }
      } else if (ex.muscleGroup == MuscleGroup.shoulders) {
        if (nameLower.contains('front') || nameLower.contains('ön')) {
          subVolume['shoulder_front'] = (subVolume['shoulder_front'] ?? 0) + vol;
          subSets['shoulder_front'] = (subSets['shoulder_front'] ?? 0) + sCount;
        } else if (nameLower.contains('rear') || nameLower.contains('reverse') || nameLower.contains('arka')) {
          subVolume['shoulder_rear'] = (subVolume['shoulder_rear'] ?? 0) + vol;
          subSets['shoulder_rear'] = (subSets['shoulder_rear'] ?? 0) + sCount;
        } else {
          subVolume['shoulder_lateral'] = (subVolume['shoulder_lateral'] ?? 0) + vol;
          subSets['shoulder_lateral'] = (subSets['shoulder_lateral'] ?? 0) + sCount;
        }
      } else if (ex.muscleGroup == MuscleGroup.core) {
        if (nameLower.contains('oblique') || nameLower.contains('russian') || nameLower.contains('yan')) {
          subVolume['core_obliques'] = (subVolume['core_obliques'] ?? 0) + vol;
          subSets['core_obliques'] = (subSets['core_obliques'] ?? 0) + sCount;
        } else {
          subVolume['core_abs'] = (subVolume['core_abs'] ?? 0) + vol;
          subSets['core_abs'] = (subSets['core_abs'] ?? 0) + sCount;
        }
      } else if (ex.muscleGroup == MuscleGroup.legs) {
        if (nameLower.contains('calf') || nameLower.contains('kalf')) {
          subVolume['leg_calves'] = (subVolume['leg_calves'] ?? 0) + vol;
          subSets['leg_calves'] = (subSets['leg_calves'] ?? 0) + sCount;
        } else if (nameLower.contains('glute') || nameLower.contains('hip') || nameLower.contains('kalça')) {
          subVolume['leg_glutes'] = (subVolume['leg_glutes'] ?? 0) + vol;
          subSets['leg_glutes'] = (subSets['leg_glutes'] ?? 0) + sCount;
        } else if (nameLower.contains('hamstring') || nameLower.contains('curl') || nameLower.contains('romanian')) {
          subVolume['leg_hamstrings'] = (subVolume['leg_hamstrings'] ?? 0) + vol;
          subSets['leg_hamstrings'] = (subSets['leg_hamstrings'] ?? 0) + sCount;
        } else if (nameLower.contains('adductor')) {
          subVolume['leg_adductors'] = (subVolume['leg_adductors'] ?? 0) + vol;
          subSets['leg_adductors'] = (subSets['leg_adductors'] ?? 0) + sCount;
        } else if (nameLower.contains('abductor')) {
          subVolume['leg_abductors'] = (subVolume['leg_abductors'] ?? 0) + vol;
          subSets['leg_abductors'] = (subSets['leg_abductors'] ?? 0) + sCount;
        } else {
          subVolume['leg_quads'] = (subVolume['leg_quads'] ?? 0) + vol;
          subSets['leg_quads'] = (subSets['leg_quads'] ?? 0) + sCount;
        }
      } else if (ex.muscleGroup == MuscleGroup.arms) {
        if (nameLower.contains('tricep') || nameLower.contains('pushdown') || nameLower.contains('dip')) {
          subVolume['arm_triceps'] = (subVolume['arm_triceps'] ?? 0) + vol;
          subSets['arm_triceps'] = (subSets['arm_triceps'] ?? 0) + sCount;
        } else if (nameLower.contains('wrist') || nameLower.contains('forearm') || nameLower.contains('bilek')) {
          subVolume['arm_wrists'] = (subVolume['arm_wrists'] ?? 0) + vol;
          subSets['arm_wrists'] = (subSets['arm_wrists'] ?? 0) + sCount;
        } else {
          subVolume['arm_biceps'] = (subVolume['arm_biceps'] ?? 0) + vol;
          subSets['arm_biceps'] = (subSets['arm_biceps'] ?? 0) + sCount;
        }
      }
    }

    MuscleRank calculateSubRank(String subId) {
      final vol = subVolume[subId] ?? 0.0;
      final sets = subSets[subId] ?? 0;
      final userScore = vol + (sets * 120);

      if (userScore > 26000) return MuscleRank.olympian;
      if (userScore > 18000) return MuscleRank.titan;
      if (userScore > 12000) return MuscleRank.champion;
      if (userScore > 7500) return MuscleRank.diamond;
      if (userScore > 4500) return MuscleRank.plat;
      if (userScore > 2500) return MuscleRank.gold;
      if (userScore > 1200) return MuscleRank.silver;
      if (userScore > 400) return MuscleRank.bronze;
      if (userScore > 0) return MuscleRank.wood;
      return MuscleRank.unranked; // Seviye 0 ise boyasız, başlangıç
    }

    SubMuscleData createSub(String id, String name) {
      return SubMuscleData(
        id: id,
        name: name,
        rank: calculateSubRank(id),
        sets: subSets[id] ?? 0,
        volumeKg: subVolume[id] ?? 0.0,
      );
    }

    // Kullanıcının tam olarak istediği hiyerarşi:
    final list = [
      MainMuscleGroupData(
        id: 'chest',
        name: 'Göğüs',
        emoji: '🛡️',
        subMuscles: [
          createSub('chest_upper', 'Üst Göğüs'),
          createSub('chest_lower', 'Alt Göğüs'),
        ],
      ),
      MainMuscleGroupData(
        id: 'back',
        name: 'Sırt',
        emoji: '🦅',
        subMuscles: [
          createSub('back_lats', 'Kanatlar'),
          createSub('back_lower', 'Alt Sırt'),
          createSub('back_traps', 'Trapezler'),
          createSub('back_upper', 'Üst Sırt'),
        ],
      ),
      MainMuscleGroupData(
        id: 'shoulders',
        name: 'Omuzlar',
        emoji: '🏹',
        subMuscles: [
          createSub('shoulder_front', 'Ön Omuzlar'),
          createSub('shoulder_lateral', 'Yan Omuzlar'),
          createSub('shoulder_rear', 'Arka Omuzlar'),
        ],
      ),
      MainMuscleGroupData(
        id: 'core',
        name: 'Karın',
        emoji: '🧱',
        subMuscles: [
          createSub('core_abs', 'Abdominals'),
          createSub('core_obliques', 'Obluklar'),
        ],
      ),
      MainMuscleGroupData(
        id: 'legs',
        name: 'Bacaklar',
        emoji: '🦵',
        subMuscles: [
          createSub('leg_abductors', 'Abductorlar'),
          createSub('leg_adductors', 'Adductorlar'),
          createSub('leg_calves', 'Kalfler'),
          createSub('leg_glutes', 'Kalça'),
          createSub('leg_hamstrings', 'Hamstringler'),
          createSub('leg_quads', 'Quadricepsler'),
        ],
      ),
      MainMuscleGroupData(
        id: 'arms',
        name: 'Kollar',
        emoji: '💪',
        subMuscles: [
          createSub('arm_biceps', 'Biceps'),
          createSub('arm_wrists', 'Bilek'),
          createSub('arm_triceps', 'Triceps'),
        ],
      ),
    ];

    // Yerel ve Sunucu Senkronizasyonu
    final prefs = await SharedPreferences.getInstance();
    final savedMap = {
      for (var g in list)
        g.id: {
          'rank': g.averageRank.name,
          'sub': {for (var s in g.subMuscles) s.id: s.toJson()}
        }
    };
    await prefs.setString('bodygraph_muscle_hierarchy_${widget.profile.name}', jsonEncode(savedMap));

    // Sunucuya asenkron güncelleme gönder
    ApiService.syncUserData(
      widget.profile.name,
      widget.profile,
      '',
      widget.exercises,
      widget.profile.unlockedBadges,
    );

    if (mounted) {
      setState(() {
        _groups = list;
        _isLoading = false;
      });
    }
  }

  // Belirli bir alt kasın rengini çeker (seviye 0 ise şeffaf/boyasız kalır)
  Color _getSubColor(String subId) {
    for (final g in _groups) {
      for (final s in g.subMuscles) {
        if (s.id == subId) {
          return s.rank.color;
        }
      }
    }
    return Colors.transparent;
  }

  SubMuscleData? _getSubData(String subId) {
    for (final g in _groups) {
      for (final s in g.subMuscles) {
        if (s.id == subId) return s;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
    }

    SubMuscleData? selectedSub;
    MainMuscleGroupData? selectedParentGroup;
    for (final g in _groups) {
      for (final s in g.subMuscles) {
        if (s.id == _selectedSubMuscleId) {
          selectedSub = s;
          selectedParentGroup = g;
          break;
        }
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // 1. Üst Bar: Başlık
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('BODYGRAPH', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      SizedBox(width: 8),
                      Text('ANATOMİ', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(
                    'Ön & Arka Vücut Modeli • Ara grupların ortalaması ana grubun rütbesidir',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Rütbe Renk Skalası Lejantı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF131722),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E2433)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildRankLegendItem('Odun', MuscleRank.wood.color),
                  const SizedBox(width: 12),
                  _buildRankLegendItem('Bronz', MuscleRank.bronze.color),
                  const SizedBox(width: 12),
                  _buildRankLegendItem('Gümüş', MuscleRank.silver.color),
                  const SizedBox(width: 12),
                  _buildRankLegendItem('Altın', MuscleRank.gold.color),
                  const SizedBox(width: 12),
                  _buildRankLegendItem('Plat', MuscleRank.plat.color),
                  const SizedBox(width: 12),
                  _buildRankLegendItem('Elmas', MuscleRank.diamond.color),
                  const SizedBox(width: 12),
                  _buildRankLegendItem('Şampiyon', MuscleRank.champion.color),
                  const SizedBox(width: 12),
                  _buildRankLegendItem('Titan', MuscleRank.titan.color),
                  const SizedBox(width: 12),
                  _buildRankLegendItem('Olimpiyatçı', MuscleRank.olympian.color),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. ANATOMİK KARAKTER MODELİ (Görsel 1 Tarzı Yan Yana Ön ve Arka Model)
          Container(
            width: double.infinity,
            height: 420,
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [Color(0xFF1A2234), Color(0xFF090C13)],
                radius: 0.95,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF263044), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: (selectedSub != null && selectedSub.rank != MuscleRank.unranked
                          ? selectedSub.rank.color
                          : const Color(0xFF38BDF8))
                      .withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Arka Plan İnce Izgara Deseni
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BodyGridBackgroundPainter(),
                  ),
                ),

                // Yan Yana İki Model (Solda ÖN, Sağda ARKA)
                Positioned(
                  top: 10,
                  bottom: 58,
                  left: 6,
                  right: 6,
                  child: Row(
                    children: [
                      // SOL: ÖN MODEL
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B).withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ÖN GÖRÜNÜM',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapUp: (details) => _handleFrontTap(details.localPosition, constraints.biggest),
                                    child: Center(
                                      child: AspectRatio(
                                        aspectRatio: 512 / 944,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            // Ön Vücut Bazı
                                            Image.asset(
                                              'assets/images/anatomy_front_base.png',
                                              fit: BoxFit.contain,
                                            ),
                                            // Ön Kas Katmanları
                                            _buildMuscleMaskLayer('chest_upper', 'assets/images/submask_chest_upper.png'),
                                            _buildMuscleMaskLayer('chest_lower', 'assets/images/submask_chest_lower.png'),
                                            _buildMuscleMaskLayer('shoulder_front', 'assets/images/submask_shoulder_front.png'),
                                            _buildMuscleMaskLayer('shoulder_lateral', 'assets/images/submask_shoulder_lateral.png'),
                                            _buildMuscleMaskLayer('arm_biceps', 'assets/images/submask_arm_biceps.png'),
                                            _buildMuscleMaskLayer('arm_wrists', 'assets/images/submask_arm_wrists.png'),
                                            _buildMuscleMaskLayer('core_abs', 'assets/images/submask_core_abs.png'),
                                            _buildMuscleMaskLayer('core_obliques', 'assets/images/submask_core_obliques.png'),
                                            _buildMuscleMaskLayer('leg_quads', 'assets/images/submask_leg_quads.png'),
                                            _buildMuscleMaskLayer('leg_adductors', 'assets/images/submask_leg_adductors.png'),
                                            _buildMuscleMaskLayer('leg_abductors', 'assets/images/submask_leg_abductors.png'),
                                            _buildMuscleMaskLayer('leg_calves', 'assets/images/submask_leg_calves.png'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Ortada Dikey Ayrım Çizgisi
                      Container(
                        width: 1,
                        height: 280,
                        color: const Color(0xFF1E293B).withOpacity(0.5),
                      ),

                      // SAĞ: ARKA MODEL
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B).withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ARKA GÖRÜNÜM',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapUp: (details) => _handleBackTap(details.localPosition, constraints.biggest),
                                    child: Center(
                                      child: AspectRatio(
                                        aspectRatio: 512 / 944,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            // Arka Vücut Bazı
                                            Image.asset(
                                              'assets/images/anatomy_back_base.png',
                                              fit: BoxFit.contain,
                                            ),
                                            // Arka Kas Katmanları
                                            _buildMuscleMaskLayer('back_traps', 'assets/images/submask_back_traps.png'),
                                            _buildMuscleMaskLayer('back_lats', 'assets/images/submask_back_lats.png'),
                                            _buildMuscleMaskLayer('back_upper', 'assets/images/submask_back_upper.png'),
                                            _buildMuscleMaskLayer('back_lower', 'assets/images/submask_back_lower.png'),
                                            _buildMuscleMaskLayer('shoulder_rear', 'assets/images/submask_shoulder_rear.png'),
                                            _buildMuscleMaskLayer('arm_triceps', 'assets/images/submask_arm_triceps.png'),
                                            _buildMuscleMaskLayer('arm_wrists', 'assets/images/submask_back_wrists.png'),
                                            _buildMuscleMaskLayer('leg_glutes', 'assets/images/submask_leg_glutes.png'),
                                            _buildMuscleMaskLayer('leg_hamstrings', 'assets/images/submask_leg_hamstrings.png'),
                                            _buildMuscleMaskLayer('leg_calves', 'assets/images/submask_back_calves.png'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Seçili Kas Bilgi Rozeti (Alt Bölüm)
                Positioned(
                  bottom: 8,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedSub != null && selectedSub.rank != MuscleRank.unranked
                            ? selectedSub.rank.color
                            : const Color(0xFF38BDF8),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selectedSub != null && selectedSub.rank != MuscleRank.unranked
                                    ? selectedSub.rank.color
                                    : const Color(0xFF38BDF8),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  selectedSub != null
                                      ? '${selectedParentGroup?.name} • ${selectedSub.name}'
                                      : 'Kas Bölgesine Dokunun',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                                ),
                                Text(
                                  selectedSub != null
                                      ? (selectedSub.rank == MuscleRank.unranked
                                          ? 'Rütbe: Başlangıç (0 Seviye • Boyasız)'
                                          : 'Rütbe: ${selectedSub.rank.title} (${selectedSub.volumeKg.toInt()} kg)')
                                      : 'Ön veya arka modelden bir kasa dokunun',
                                  style: TextStyle(
                                    color: selectedSub != null && selectedSub.rank != MuscleRank.unranked
                                        ? selectedSub.rank.color
                                        : const Color(0xFF94A3B8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (selectedSub != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (selectedSub.rank == MuscleRank.unranked
                                      ? const Color(0xFF64748B)
                                      : selectedSub.rank.color)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: selectedSub.rank == MuscleRank.unranked
                                    ? const Color(0xFF64748B)
                                    : selectedSub.rank.color,
                              ),
                            ),
                            child: Text(
                              selectedSub.rank.title,
                              style: TextStyle(
                                color: selectedSub.rank == MuscleRank.unranked
                                    ? const Color(0xFF94A3B8)
                                    : selectedSub.rank.color,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // 4. KAS GRUPLARI LİSTESİ (Akordeon: Ana Grup Tıklanınca Ara Gruplar Açılır)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'KAS GRUBU HİYERARŞİSİ & RÜTBELER',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.8),
            ),
          ),
          const SizedBox(height: 10),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _groups.length,
            itemBuilder: (ctx, idx) {
              final group = _groups[idx];
              final isExpanded = _expandedMainGroupId == group.id;
              final avgRank = group.averageRank;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF131722),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isExpanded ? avgRank.color.withOpacity(0.8) : const Color(0xFF22283A),
                    width: isExpanded ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    // Ana Kas Grubu Başlığı (Tıklanınca Ara Grupları Açar)
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        setState(() {
                          _expandedMainGroupId = isExpanded ? null : group.id;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: avgRank.color.withOpacity(0.16),
                                shape: BoxShape.circle,
                              ),
                              child: Text(group.emoji, style: const TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        group.name,
                                        style: TextStyle(
                                          color: isExpanded ? avgRank.color : Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${group.subMuscles.length} ara grup)',
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ortalama Rütbe: ${avgRank.title} • ${group.totalVolume.toInt()} kg',
                                    style: TextStyle(color: avgRank.color, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: avgRank.color.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: avgRank.color.withOpacity(0.5)),
                              ),
                              child: Text(
                                avgRank.title,
                                style: TextStyle(color: avgRank.color, fontWeight: FontWeight.w900, fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Ara Gruplar Listesi (Akordeon İçeriği)
                    if (isExpanded) ...[
                      const Divider(height: 1, color: Color(0xFF1E2536)),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0C101A),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                        ),
                        child: Column(
                          children: group.subMuscles.map((sub) {
                            final isSubSelected = _selectedSubMuscleId == sub.id;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedSubMuscleId = sub.id;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSubSelected ? sub.rank.color.withOpacity(0.18) : const Color(0xFF161C2A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSubSelected ? sub.rank.color : const Color(0xFF242C3E),
                                    width: isSubSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: sub.rank.color),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sub.name,
                                            style: TextStyle(
                                              color: isSubSelected ? sub.rank.color : Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            '${sub.volumeKg.toInt()} kg • ${sub.sets} set',
                                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      sub.rankDisplayName,
                                      style: TextStyle(color: sub.rank.color, fontWeight: FontWeight.w900, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _handleFrontTap(Offset localPos, Size boxSize) {
    // 512 x 944 görsel alanına normalize et
    final scale = boxSize.height / 944.0;
    final imageWidth = 512.0 * scale;
    final offsetX = (boxSize.width - imageWidth) / 2.0;

    // Dokunulan noktanın 512 x 944 koordinat karşılığı
    final px = (localPos.dx - offsetX) / scale;
    final py = localPos.dy / scale;

    if (px < 0 || px > 512 || py < 0 || py > 944) return;

    // Omuzlar, Kollar, Göğüs (py: 190 .. 330)
    if (py >= 190 && py <= 330) {
      if (px >= 165 && px <= 347) {
        // Göğüs
        if (py < 266) {
          _selectSub('chest_upper', 'chest');
        } else {
          _selectSub('chest_lower', 'chest');
        }
      } else if (px < 165) {
        // Sol Kol / Omuz
        if (py < 275) {
          if (px < 140) {
            _selectSub('shoulder_lateral', 'shoulders');
          } else {
            _selectSub('shoulder_front', 'shoulders');
          }
        } else {
          _selectSub('arm_biceps', 'arms');
        }
      } else {
        // Sağ Kol / Omuz
        if (py < 275) {
          if (px > 372) {
            _selectSub('shoulder_lateral', 'shoulders');
          } else {
            _selectSub('shoulder_front', 'shoulders');
          }
        } else {
          _selectSub('arm_biceps', 'arms');
        }
      }
    } else if (py > 330 && py <= 440) {
      // Karın veya Ön Kol / Bilek
      if (px < 165 || px > 347) {
        _selectSub('arm_wrists', 'arms');
      } else if (px >= 215 && px <= 297) {
        _selectSub('core_abs', 'core');
      } else {
        _selectSub('core_obliques', 'core');
      }
    } else if (py > 440 && py <= 620) {
      // Bacaklar: Quads, Adductorlar, Abductorlar
      if (px >= 236 && px <= 276 && py <= 530) {
        _selectSub('leg_adductors', 'legs');
      } else if (px < 185 || px > 327) {
        _selectSub('leg_abductors', 'legs');
      } else {
        _selectSub('leg_quads', 'legs');
      }
    } else if (py > 620 && py <= 830) {
      // Ön Kaval / Kalfler
      _selectSub('leg_calves', 'legs');
    }
  }

  void _handleBackTap(Offset localPos, Size boxSize) {
    final scale = boxSize.height / 944.0;
    final imageWidth = 512.0 * scale;
    final offsetX = (boxSize.width - imageWidth) / 2.0;

    final px = (localPos.dx - offsetX) / scale;
    final py = localPos.dy / scale;

    if (px < 0 || px > 512 || py < 0 || py > 944) return;

    if (py >= 160 && py <= 295) {
      // Üst Bölge: Trapez, Arka Omuz veya Üst Sırt
      if (px < 155 || px > 355) {
        if (py < 265) {
          _selectSub('shoulder_rear', 'shoulders');
        } else {
          _selectSub('arm_triceps', 'arms');
        }
      } else if (px >= 200 && px <= 312 && py < 240) {
        _selectSub('back_traps', 'back');
      } else {
        _selectSub('back_upper', 'back');
      }
    } else if (py > 295 && py <= 380) {
      // Kanatlar veya Triceps
      if (px < 155 || px > 355) {
        _selectSub('arm_triceps', 'arms');
      } else {
        _selectSub('back_lats', 'back');
      }
    } else if (py > 380 && py <= 445) {
      // Alt Sırt veya Ön Kol / Bilekler
      if (px < 155 || px > 355) {
        _selectSub('arm_wrists', 'arms');
      } else {
        _selectSub('back_lower', 'back');
      }
    } else if (py > 445 && py <= 515) {
      // Kalça (Glutes)
      _selectSub('leg_glutes', 'legs');
    } else if (py > 515 && py <= 640) {
      // Hamstringler (Arka Bacak)
      _selectSub('leg_hamstrings', 'legs');
    } else if (py > 640 && py <= 830) {
      // Kalflar (Arka Baldır)
      _selectSub('leg_calves', 'legs');
    }
  }

  Widget _buildMuscleMaskLayer(String subId, String assetPath) {
    final isSelected = _selectedSubMuscleId == subId;
    final subData = _getSubData(subId);
    final isUnranked = subData == null || subData.rank == MuscleRank.unranked;
    final color = _getSubColor(subId);

    // Seviye 0 ise ve seçili değilse tamamen boyasız (görünmez)
    if (isUnranked && !isSelected) {
      return const SizedBox.shrink();
    }

    // Seçiliyse ve henüz rütbesi yoksa açık mavi vurgu rengi al, rütbesi varsa kendi rütbe rengini al
    final effectiveColor = isUnranked ? const Color(0xFF38BDF8) : color;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Seçiliyse arkada neon parlama
        if (isSelected)
          Image.asset(
            assetPath,
            fit: BoxFit.contain,
            color: effectiveColor.withOpacity(0.55),
            colorBlendMode: BlendMode.srcIn,
          ),
        // Canlı kas dolgusu
        Opacity(
          opacity: isSelected ? 0.95 : 0.85,
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            color: effectiveColor,
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
      ],
    );
  }

  void _selectSub(String subId, String groupId) {
    setState(() {
      _selectedSubMuscleId = subId;
      _expandedMainGroupId = groupId;
    });
  }

  Widget _buildRankLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// 🌐 Şık Arka Plan Izgarası
class _BodyGridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF1E283C).withOpacity(0.4)
      ..strokeWidth = 1.0;

    const double step = 26.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
