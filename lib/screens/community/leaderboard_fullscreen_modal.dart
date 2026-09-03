import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/auth_user.dart';
import '../../models/user_profile.dart';
import '../../models/exercise.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../progress_analytics_screen.dart';

class LeaderboardFullscreenModal extends StatefulWidget {
  final UserProfile currentProfile;
  final List<Exercise> exercises;

  const LeaderboardFullscreenModal({
    super.key,
    required this.currentProfile,
    this.exercises = const [],
  });

  @override
  State<LeaderboardFullscreenModal> createState() => _LeaderboardFullscreenModalState();
}

class _LeaderboardFullscreenModalState extends State<LeaderboardFullscreenModal> {
  int _selectedFilter = 1; // 0: Friends, 1: Global, 2: Regional
  int _selectedBottomTab = 1; // 0: Streaks, 1: Ranks, 2: Levels

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

  List<LeaderboardEntry> get _sortedLeaders {
    // Listede current user varsa widget.currentProfile ile güncelle
    final list = _leaders.map((item) {
      if (item.isCurrentUser || item.username == widget.currentProfile.name) {
        return LeaderboardEntry(
          rank: item.rank,
          userId: item.userId,
          username: widget.currentProfile.name,
          goal: item.goal,
          level: widget.currentProfile.level,
          currentXP: widget.currentProfile.currentXP,
          targetXP: widget.currentProfile.targetXP,
          rankTitle: widget.currentProfile.rankTitle,
          totalTonnage: widget.currentProfile.totalTonnageLiftedKg / 1000.0,
          totalTonnageKg: widget.currentProfile.totalTonnageLiftedKg,
          streakDays: widget.currentProfile.streakDays, // Kullanıcının gerçek serisi!
          totalWorkoutsCompleted: widget.currentProfile.totalWorkoutsCompleted,
          weightKg: widget.currentProfile.weightKg,
          gender: widget.currentProfile.gender,
          bodyFat: widget.currentProfile.bodyFat,
          isFatPercentage: widget.currentProfile.isFatPercentage,
          muscleMass: widget.currentProfile.muscleMass,
          isMusclePercentage: widget.currentProfile.isMusclePercentage,
          unlockedBadgesCount: widget.currentProfile.unlockedBadges.length,
          avatarBase64: widget.currentProfile.avatarBase64,
          isCurrentUser: true,
        );
      }
      return item;
    }).toList();

    if (_selectedBottomTab == 0) {
      // Seriler (Streaks): En çok serisi olan en üstte
      list.sort((a, b) => b.streakDays.compareTo(a.streakDays));
    } else if (_selectedBottomTab == 1) {
      // Rütbeler: Sahip olunan rekabetçi lig / rütbe puanına göre sırala
      list.sort((a, b) => b.competitiveRankScore.compareTo(a.competitiveRankScore));
    } else {
      // Seviyeler: En yüksek level ve XP'ye göre
      list.sort((a, b) {
        final cmp = b.level.compareTo(a.level);
        return cmp != 0 ? cmp : b.currentXP.compareTo(a.currentXP);
      });
    }

    // Sıralama numaralarını yeniden ata (rank 1, 2, 3...)
    return List.generate(list.length, (i) {
      final item = list[i];
      return LeaderboardEntry(
        rank: i + 1,
        userId: item.userId,
        username: item.username,
        goal: item.goal,
        level: item.level,
        currentXP: item.currentXP,
        targetXP: item.targetXP,
        rankTitle: item.rankTitle,
        totalTonnage: item.totalTonnage,
        totalTonnageKg: item.totalTonnageKg,
        streakDays: item.streakDays,
        totalWorkoutsCompleted: item.totalWorkoutsCompleted,
        weightKg: item.weightKg,
        gender: item.gender,
        bodyFat: item.bodyFat,
        isFatPercentage: item.isFatPercentage,
        muscleMass: item.muscleMass,
        isMusclePercentage: item.isMusclePercentage,
        unlockedBadgesCount: item.unlockedBadgesCount,
        avatarBase64: item.avatarBase64,
        isCurrentUser: item.isCurrentUser,
      );
    });
  }

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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppTheme.primaryNeon, AppTheme.primaryAccent]),
                border: Border.all(color: AppTheme.primaryNeon, width: 2),
              ),
              child: ClipOval(
                child: hasAvatar
                    ? Image.memory(base64Decode(athlete.avatarBase64!), fit: BoxFit.cover)
                    : const Center(child: Text('⚔️', style: TextStyle(fontSize: 32))),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              athlete.username,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Rütbe: ${athlete.competitiveRankTier} • Lv ${athlete.level}',
              style: const TextStyle(color: AppTheme.primaryNeon, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBadge('Kaldırılan Ağırlık', '${athlete.totalTonnage.toStringAsFixed(1)} Ton', Icons.line_weight_rounded, AppTheme.primaryAccent),
                _buildStatBadge('Disiplin Serisi', '${athlete.streakDays} Gün', Icons.local_fire_department_rounded, AppTheme.secondaryOrange),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedList = _sortedLeaders;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1017), // Koyu arka plan (Görsel 3)
      body: SafeArea(
        child: Column(
          children: [
            // 1. Üst Bar: Sol Üstte Geri Butonu + Ortada "Liderlik Tablosu" + Sağda Bilgi İkonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Liderlik Tablosu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 22),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // 2. Filtre Segmenti: Arkadaşlar | Global | Bölgesel (Görsel 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 46,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E202E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2B2E42)),
                ),
                child: Row(
                  children: [
                    _buildSegmentButton('Arkadaşlar', 0),
                    _buildSegmentButton('Global', 1),
                    _buildSegmentButton('Bölgesel ✨', 2),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 3. Podyum ve Sıralama Listesi
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                  : _buildLeaderboardBody(sortedList),
            ),

            // 4. Sabit Alt Kullanıcı Barı
            _buildCurrentUserBottomBar(sortedList),

            // 5. Alt 3 Tane Tablo Butonu: Seriler 🔥 | Rütbeler ⬡ | Seviyeler ✦
            Container(
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFF161822),
                border: Border(top: BorderSide(color: Color(0xFF26293A))),
              ),
              child: Row(
                children: [
                  _buildBottomNavTab('Seriler', '🔥', 0),
                  _buildBottomNavTab('Rütbeler', '⬡', 1),
                  _buildBottomNavTab('Seviyeler', '✦', 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String text, int index) {
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardBody(List<LeaderboardEntry> leadersList) {
    if (leadersList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text('Liderlik verisi bulunamadı.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: Colors.black),
              onPressed: _fetchLeaderboard,
              child: const Text('Yenile'),
            ),
          ],
        ),
      );
    }

    final top1 = leadersList.isNotEmpty ? leadersList[0] : null;
    final top2 = leadersList.length > 1 ? leadersList[1] : null;
    final top3 = leadersList.length > 2 ? leadersList[2] : null;
    final otherLeaders = leadersList.length > 3 ? leadersList.sublist(3) : <LeaderboardEntry>[];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Çelenkli Podyum (Görsel 3)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (top2 != null) _buildWreathPodiumSpot(top2, 2, const Color(0xFFCBD5E1), 90),
                if (top1 != null) _buildWreathPodiumSpot(top1, 1, const Color(0xFFFBBF24), 115),
                if (top3 != null) _buildWreathPodiumSpot(top3, 3, const Color(0xFFCD7F32), 85),
              ],
            ),
          ),
        ),

        // Kalan Sıralama Listesi (Görsel 3'teki 4, 5, 6, 7 satırları)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = otherLeaders[index];
                return _buildLeaderRow(entry);
              },
              childCount: otherLeaders.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
      ],
    );
  }

  // Çelenkli Podyum Şampiyonu (Görsel 3)
  Widget _buildWreathPodiumSpot(LeaderboardEntry entry, int rank, Color crownColor, double avatarSize) {
    final hasAvatar = entry.avatarBase64 != null && entry.avatarBase64!.isNotEmpty;
    final isTop1 = rank == 1;

    return GestureDetector(
      onTap: () => _showAthleteProfileModal(entry),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sporcu İsmi
          Text(
            entry.username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Çelenk + Profil Fotoğrafı Stack
          Stack(
            alignment: Alignment.center,
            children: [
              // Arka plan Çelenk Dairesi
              Container(
                width: isTop1 ? 100 : 80,
                height: isTop1 ? 100 : 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: crownColor.withOpacity(0.8), width: isTop1 ? 3 : 2),
                  boxShadow: [
                    BoxShadow(
                      color: crownColor.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),

              // Profil Avatarı
              Container(
                width: isTop1 ? 84 : 66,
                height: isTop1 ? 84 : 66,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: hasAvatar
                      ? Image.memory(base64Decode(entry.avatarBase64!), fit: BoxFit.cover)
                      : Container(
                          color: const Color(0xFF2A2B3D),
                          child: const Center(child: Text('⚔️', style: TextStyle(fontSize: 28))),
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Skor Değeri (Seçili Sekmeye Göre: Seri, Rütbe veya Seviye)
          _buildScoreBadge(entry),
        ],
      ),
    );
  }

  // 4, 5, 6... Sıralama Satırları (Görsel 3)
  Widget _buildLeaderRow(LeaderboardEntry entry) {
    final hasAvatar = entry.avatarBase64 != null && entry.avatarBase64!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser ? const Color(0xFF38BDF8).withOpacity(0.12) : const Color(0xFF1E202E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.isCurrentUser ? const Color(0xFF38BDF8) : const Color(0xFF2B2E42),
          width: entry.isCurrentUser ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Sıra Numarası
          SizedBox(
            width: 26,
            child: Text(
              '${entry.rank}',
              style: TextStyle(
                color: entry.isCurrentUser ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Avatar
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: hasAvatar
                  ? Image.memory(base64Decode(entry.avatarBase64!), fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFF2A2B3D),
                      child: const Center(child: Text('🏋️', style: TextStyle(fontSize: 16))),
                    ),
            ),
          ),

          // İsim
          Expanded(
            child: Text(
              entry.username,
              style: TextStyle(
                color: entry.isCurrentUser ? const Color(0xFF38BDF8) : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Değer
          _buildScoreBadge(entry),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(LeaderboardEntry entry) {
    if (_selectedBottomTab == 0) {
      // Seriler
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${entry.streakDays}',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 4),
          const Text('🔥', style: TextStyle(fontSize: 13)),
        ],
      );
    } else if (_selectedBottomTab == 1) {
      // Rütbeler
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⬡', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Text(
              entry.competitiveRankTier,
              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else {
      // Seviyeler
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Lv. ${entry.level}',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 4),
          const Text('✦', style: TextStyle(fontSize: 13, color: Color(0xFFFBBF24))),
        ],
      );
    }
  }

  // Sabit Alt Kullanıcı Barı (Görsel 3 - Mavi Vurgulu Yaman Kartı)
  Widget _buildCurrentUserBottomBar(List<LeaderboardEntry> sortedList) {
    final hasAvatar = widget.currentProfile.avatarBase64 != null && widget.currentProfile.avatarBase64!.isNotEmpty;
    final myRankEntry = sortedList.where((e) => e.isCurrentUser).toList();
    // Eğer sıralamada bulunamazsa listenin sonuna konur, doğrudan 1. gösterilmez!
    final myRankNumber = myRankEntry.isNotEmpty ? myRankEntry.first.rank : (sortedList.length + 1);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF38BDF8), // Canlı Açık Mavi (Görsel 3)
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '#$myRankNumber',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: hasAvatar
                  ? Image.memory(base64Decode(widget.currentProfile.avatarBase64!), fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFF0F172A),
                      child: const Center(child: Text('⚔️', style: TextStyle(fontSize: 18))),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.currentProfile.name,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${widget.currentProfile.competitiveRankTier} • Lv. ${widget.currentProfile.level}',
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Kullanıcının değeri (0 ise 0 gösterir, zorla 1 yapmaz)
          if (_selectedBottomTab == 0) ...[
            Text(
              '${widget.currentProfile.streakDays}',
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 4),
            const Text('🔥', style: TextStyle(fontSize: 14)),
          ] else if (_selectedBottomTab == 1) ...[
            Text(
              widget.currentProfile.competitiveRankTier,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ] else ...[
            Text(
              'Lv. ${widget.currentProfile.level}',
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ],
        ],
      ),
    );
  }

  // Alt 3'lü Buton: Streaks | Ranks | Levels (Görsel 3)
  Widget _buildBottomNavTab(String title, String icon, int index) {
    final isSelected = _selectedBottomTab == index;
    final color = isSelected ? const Color(0xFFFBBF24) : const Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedBottomTab = index);
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: TextStyle(fontSize: 16, color: color)),
              const SizedBox(height: 3),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
