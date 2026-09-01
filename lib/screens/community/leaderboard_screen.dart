import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/auth_user.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  final UserProfile currentProfile;

  const LeaderboardScreen({
    super.key,
    required this.currentProfile,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardEntry> _leaders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  void _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    final list = await ApiService.fetchLeaderboard(widget.currentProfile.name);
    if (mounted) {
      setState(() {
        _leaders = list;
        _isLoading = false;
      });
    }
  }

  // 🌟 Liderlik tablosundaki sporcunun profiline tıklanınca açılan detaylı modal
  void _showAthleteProfileModal(LeaderboardEntry athlete) {
    final hasAvatar = athlete.avatarBase64 != null && athlete.avatarBase64!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppTheme.primaryNeon, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sürükleme Tutamacı
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Sporcu Avatarı & İsmi
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryNeon, width: 2),
                    gradient: const LinearGradient(colors: [AppTheme.primaryNeon, AppTheme.primaryAccent]),
                  ),
                  child: ClipOval(
                    child: hasAvatar
                        ? Image.memory(
                            base64Decode(athlete.avatarBase64!),
                            fit: BoxFit.cover,
                          )
                        : const Center(child: Text('⚔️', style: TextStyle(fontSize: 28))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            athlete.username,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (athlete.isCurrentUser) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryNeon,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('SEN', style: TextStyle(color: AppTheme.background, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '🏆 Sıralama: #${athlete.rank} • LV ${athlete.level} ${athlete.rankTitle}',
                        style: const TextStyle(color: AppTheme.goldRank, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hedef: ${athlete.goal}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Divider(color: AppTheme.surfaceBorder, height: 1),
            const SizedBox(height: 16),

            // İstatistik Kartları Grid
            Row(
              children: [
                Expanded(
                  child: _buildModalStat(
                    title: 'Toplam Tonaj',
                    value: '${athlete.totalTonnage.toStringAsFixed(1)} Ton',
                    icon: Icons.line_weight_rounded,
                    color: AppTheme.primaryNeon,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildModalStat(
                    title: 'Disiplin Serisi',
                    value: '${athlete.streakDays} Gün',
                    icon: Icons.local_fire_department_rounded,
                    color: AppTheme.secondaryOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildModalStat(
                    title: 'Vücut Ağırlığı',
                    value: '${athlete.weightKg.toStringAsFixed(1)} KG (${athlete.gender})',
                    icon: Icons.monitor_weight_outlined,
                    color: AppTheme.primaryAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildModalStat(
                    title: 'Yağ / Kas',
                    value: '${athlete.bodyFat}${athlete.isFatPercentage ? '%' : 'kg'} / ${athlete.muscleMass}${athlete.isMusclePercentage ? '%' : 'kg'}',
                    icon: Icons.fitness_center_rounded,
                    color: AppTheme.purpleXP,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildModalStat(
                    title: 'Tamamlanan Antrenman',
                    value: '${athlete.totalWorkoutsCompleted} Seans',
                    icon: Icons.check_circle_outline_rounded,
                    color: Colors.tealAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildModalStat(
                    title: 'Açılan Rozetler',
                    value: '${athlete.unlockedBadgesCount} Rozet 🎖️',
                    icon: Icons.military_tech_rounded,
                    color: AppTheme.goldRank,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceLight,
                  foregroundColor: AppTheme.textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('KAPAT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalStat({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canlı Liderlik Tablosu'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryNeon),
            onPressed: _fetchLeaderboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon))
          : _leaders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'VDS Sunucusuna bağlanılamadı.',
                        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNeon, foregroundColor: AppTheme.background),
                        onPressed: _fetchLeaderboard,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Podyum (İlk 3 Sporcu)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.purpleXP.withOpacity(0.4)),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '🏆 CANLI GÜÇ ŞAMPİYONLARI (VDS SERVER)',
                                style: TextStyle(
                                  color: AppTheme.goldRank,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (_leaders.length > 1) _buildPodiumSpot(_leaders[1], '🥈', 75, Colors.blueGrey),
                                  if (_leaders.isNotEmpty) _buildPodiumSpot(_leaders[0], '👑', 95, AppTheme.goldRank),
                                  if (_leaders.length > 2) _buildPodiumSpot(_leaders[2], '🥉', 65, const Color(0xFFCD7F32)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'TÜM SIRALAMA (Profili Görmek İçin Tıklayın)',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = _leaders[index];
                            final hasAvatar = entry.avatarBase64 != null && entry.avatarBase64!.isNotEmpty;

                            return GestureDetector(
                              onTap: () => _showAthleteProfileModal(entry),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: entry.isCurrentUser ? AppTheme.primaryNeon.withOpacity(0.12) : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: entry.isCurrentUser ? AppTheme.primaryNeon : AppTheme.surfaceBorder,
                                    width: entry.isCurrentUser ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '#${entry.rank}',
                                        style: TextStyle(
                                          color: entry.rank <= 3 ? AppTheme.goldRank : AppTheme.textSecondary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    // Mini Avatar
                                    Container(
                                      width: 36,
                                      height: 36,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.6)),
                                      ),
                                      child: ClipOval(
                                        child: hasAvatar
                                            ? Image.memory(base64Decode(entry.avatarBase64!), fit: BoxFit.cover)
                                            : const Center(child: Text('⚔️', style: TextStyle(fontSize: 16))),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                entry.username,
                                                style: TextStyle(
                                                  color: entry.isCurrentUser ? AppTheme.primaryNeon : AppTheme.textPrimary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (entry.isCurrentUser) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryNeon,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'SEN',
                                                    style: TextStyle(color: AppTheme.background, fontSize: 9, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'LV ${entry.level} • ${entry.rankTitle}',
                                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${entry.totalTonnage.toStringAsFixed(1)} Ton',
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Text('🔥', style: TextStyle(fontSize: 10)),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${entry.streakDays} gün',
                                              style: const TextStyle(color: AppTheme.secondaryOrange, fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _leaders.length,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPodiumSpot(LeaderboardEntry entry, String medal, double height, Color color) {
    final hasAvatar = entry.avatarBase64 != null && entry.avatarBase64!.isNotEmpty;

    return GestureDetector(
      onTap: () => _showAthleteProfileModal(entry),
      child: Column(
        children: [
          Text(medal, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: ClipOval(
              child: hasAvatar
                  ? Image.memory(base64Decode(entry.avatarBase64!), fit: BoxFit.cover)
                  : const Center(child: Text('⚔️', style: TextStyle(fontSize: 20))),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.username,
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            '${entry.totalTonnage.toStringAsFixed(1)}T',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            width: 65,
            height: height,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
