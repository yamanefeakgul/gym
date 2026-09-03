import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/exercise.dart';
import '../../theme/app_theme.dart';
import '../progress_analytics_screen.dart';
import '../streak_detail_screen.dart';
import 'leaderboard_fullscreen_modal.dart';
import 'body_graph_screen.dart';

class RanksScreen extends StatefulWidget {
  final UserProfile currentProfile;
  final List<Exercise> exercises;

  const RanksScreen({
    super.key,
    required this.currentProfile,
    this.exercises = const [],
  });

  @override
  State<RanksScreen> createState() => _RanksScreenState();
}

class _RanksScreenState extends State<RanksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openLeaderboardFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeaderboardFullscreenModal(
          currentProfile: widget.currentProfile,
          exercises: widget.exercises,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.currentProfile;
    final hasAvatar = profile.avatarBase64 != null && profile.avatarBase64!.isNotEmpty;
    final rankTier = profile.competitiveRankTier;
    final rankColor = profile.competitiveRankColor;

    // Placements: Toplam 10 yerleştirme rozeti. Kullanıcının tamamladığı antrenman sayısına göre
    final completedCount = (profile.totalWorkoutsCompleted).clamp(0, 10);
    final remainingCount = (10 - completedCount).clamp(0, 10);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Üst Bar: Ana Sayfa ile Birebir Aynı Tasarım (Sol: Avatar + Lv. X, Sağ: Tonaj + Streak)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sol: Avatar + Seviye
                  Row(
                    children: [
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
                          child: hasAvatar
                              ? Image.memory(base64Decode(profile.avatarBase64!), fit: BoxFit.cover)
                              : const Center(child: Text('⚔️', style: TextStyle(fontSize: 20))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Lv. ${profile.level}',
                                style: const TextStyle(
                                  color: AppTheme.primaryNeon,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${profile.currentXP}/${profile.targetXP} XP',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
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
                                value: profile.xpProgress,
                                backgroundColor: Colors.transparent,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryNeon),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                              '${(profile.totalTonnageLiftedKg / 1000).toStringAsFixed(1)} T',
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

                      // Spor Serisi Çipi (Streak)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StreakDetailScreen(profile: profile),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: profile.streakDays > 0 ? const Color(0xFFEF4444).withOpacity(0.6) : AppTheme.surfaceBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(profile.streakDays > 0 ? '🔥' : '⚪', style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                '${profile.streakDays}',
                                style: TextStyle(
                                  color: profile.streakDays > 0 ? const Color(0xFFFCA5A5) : AppTheme.textMuted,
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

            // 2. Sayfa Sekmeleri: Rütbeniz | BodyGraph | Gelişim & PR | Lig Sıralaması
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1E202E), width: 1.5)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: const BoxDecoration(), // Dikdörtgen ve çizgi yanmasını tamamen kaldırır
                indicatorSize: TabBarIndicatorSize.label,
                overlayColor: MaterialStateProperty.all(Colors.transparent), // Tıklama dikdörtgen efektini kaldırır
                enableFeedback: false,
                labelColor: const Color(0xFF38BDF8),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                tabs: const [
                  Tab(text: 'Rütbeniz'),
                  Tab(text: 'BodyGraph'),
                  Tab(text: 'Gelişim & PR'),
                  Tab(text: 'Lig Sıralaması'),
                ],
              ),
            ),

            // 3. Sekme İçerikleri
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Sekme 1: RÜTBENİZ
                  _buildYourRankTab(context, profile, rankTier, rankColor, completedCount, remainingCount),

                  // Sekme 2: BODYGRAPH (KAS RÜTBE ANATOMİSİ)
                  BodyGraphScreen(
                    profile: profile,
                    exercises: widget.exercises,
                  ),

                  // Sekme 3: GELİŞİM & PR İSTATİSTİKLERİ
                  ProgressAnalyticsContent(exercises: widget.exercises),

                  // Sekme 4: LİGLER BİLGİSİ
                  _buildLeaguesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourRankTab(
    BuildContext context,
    UserProfile profile,
    String rankTier,
    Color rankColor,
    int completedCount,
    int remainingCount,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      child: Column(
        children: [
          // 🛡️ BÜYÜK KANATLI AMBLEM (Görsel 2)
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: rankColor.withOpacity(0.35),
                        blurRadius: 36,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '🔱',
                          style: TextStyle(fontSize: 76, color: rankColor),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '🛡️',
                            style: TextStyle(fontSize: 48, color: rankColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tahmini Rütbe: $rankTier',
                  style: TextStyle(
                    color: const Color(0xFF94A3B8),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 🌈 YERLEŞTİRME ANTRENMANLARI (Görsel 2 - Gökkuşağı Borderlı Kart)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF13151F),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yerleştirme Aşaması',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  remainingCount > 0
                      ? 'Resmi lig rütbeni kazanmak için $remainingCount antrenman daha yap!'
                      : 'Tebrikler! Yerleştirme tamamlandı, $rankTier ligindesin!',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),

                // 10'lu Altıgen (Hexagon) Dizilimi (Görsel 2)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(10, (index) {
                    final isDone = index < completedCount;
                    return Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFFA855F7) : const Color(0xFF1E2130),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDone ? const Color(0xFFC084FC) : const Color(0xFF2E3349),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '⬡',
                          style: TextStyle(
                            color: isDone ? Colors.white : const Color(0xFF475569),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // Mavi Aksiyon Butonu: LİDERLİK TABLOSUNU AÇ
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _openLeaderboardFullscreen,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.leaderboard_rounded, size: 20, color: Color(0xFF0F172A)),
                        SizedBox(width: 8),
                        Text(
                          'LİDERLİK TABLOSUNU AÇ',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 🏆 RÜTBE SIRALAMASI KARTI
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF13151F),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF222638)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rütbe Durumu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: rankColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: rankColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        rankTier,
                        style: TextStyle(color: rankColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Yerleştirme antrenmanlarını bitirerek dünya sıralamasındaki yerini sabitle!',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),

                // Hızlı Metrikler
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickMetric('Kaldırış Tonajı', '${(profile.totalTonnageLiftedKg / 1000).toStringAsFixed(1)} Ton', Icons.fitness_center_rounded, const Color(0xFF38BDF8)),
                    _buildQuickMetric('Disiplin Serisi', '${profile.streakDays} Gün', Icons.local_fire_department_rounded, const Color(0xFFF97316)),
                    _buildQuickMetric('Bitirilen Antrenman', '${profile.totalWorkoutsCompleted}', Icons.check_circle_rounded, const Color(0xFF10B981)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
      ],
    );
  }

  Widget _buildLeaguesTab() {
    final tiers = [
      {'name': 'OLİMPİYATÇI (I - III)', 'min': '165000+ Puan', 'color': const Color(0xFF10B981), 'icon': '🏆'},
      {'name': 'TİTAN (I - III)', 'min': '85000 - 165000', 'color': const Color(0xFFEF4444), 'icon': '⚡'},
      {'name': 'ŞAMPİYON (I - III)', 'min': '48000 - 85000', 'color': const Color(0xFFEC4899), 'icon': '👑'},
      {'name': 'ELMAS (I - III)', 'min': '26000 - 48000', 'color': const Color(0xFFA855F7), 'icon': '💎'},
      {'name': 'PLAT (I - III)', 'min': '13500 - 26000', 'color': const Color(0xFF38BDF8), 'icon': '💠'},
      {'name': 'ALTIN (I - III)', 'min': '6000 - 13500', 'color': const Color(0xFFFBBF24), 'icon': '🥇'},
      {'name': 'GÜMÜŞ (I - III)', 'min': '2500 - 6000', 'color': const Color(0xFFCBD5E1), 'icon': '🥈'},
      {'name': 'BRONZ (I - III)', 'min': '800 - 2500', 'color': const Color(0xFFCD7F32), 'icon': '🥉'},
      {'name': 'ODUN (I - III)', 'min': '0 - 800', 'color': const Color(0xFF8D6E63), 'icon': '🪵'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tiers.length,
      itemBuilder: (context, index) {
        final t = tiers[index];
        final c = t['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF13151F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Text(t['icon'] as String, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['name'] as String,
                      style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Gereken: ${t['min']}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
