import 'package:flutter/material.dart';
import 'exercise.dart';

/// 🏅 9 Temel Rütbe (En Düşükten En Yükseğe)
enum RankTier {
  wood(0, 'Odun', '🪵', Color(0xFF8D6E63)),
  bronze(1, 'Bronz', '🥉', Color(0xFFCD7F32)),
  silver(2, 'Gümüş', '🥈', Color(0xFFCBD5E1)),
  gold(3, 'Altın', '🥇', Color(0xFFFBBF24)),
  plat(4, 'Plat', '💠', Color(0xFF38BDF8)),
  diamond(5, 'Elmas', '💎', Color(0xFFA855F7)),
  champion(6, 'Şampiyon', '👑', Color(0xFFEC4899)),
  titan(7, 'Titan', '⚡', Color(0xFFEF4444)),
  olympian(8, 'Olimpiyatçı', '🏆', Color(0xFF10B981));

  final int order;
  final String title;
  final String emoji;
  final Color color;

  const RankTier(this.order, this.title, this.emoji, this.color);
}

/// 🌟 Her Rütbenin 3 Kademesi (Örn: Gümüş I, Gümüş II, Gümüş III)
class GymRank {
  final RankTier tier;
  final int subLevel; // 1, 2 veya 3

  const GymRank({
    required this.tier,
    this.subLevel = 1,
  });

  String get romanNumeral {
    switch (subLevel) {
      case 1:
        return 'I';
      case 2:
        return 'II';
      case 3:
        return 'III';
      default:
        return 'I';
    }
  }

  /// Ekranda gösterilecek tam unvan (Örn: "Gümüş III", "Bronz I")
  String get displayName => '${tier.title} $romanNumeral';

  /// Ana rütbe rengi (kademeler arasında renk farkı yok)
  Color get color => tier.color;

  String get emoji => tier.emoji;

  /// Skor bazlı kademe hesaplama (Toplam 27 Kademe)
  static GymRank fromScore(double score) {
    if (score >= 260000) return const GymRank(tier: RankTier.olympian, subLevel: 3);
    if (score >= 200000) return const GymRank(tier: RankTier.olympian, subLevel: 2);
    if (score >= 150000) return const GymRank(tier: RankTier.olympian, subLevel: 1);

    if (score >= 120000) return const GymRank(tier: RankTier.titan, subLevel: 3);
    if (score >= 100000) return const GymRank(tier: RankTier.titan, subLevel: 2);
    if (score >= 85000) return const GymRank(tier: RankTier.titan, subLevel: 1);

    if (score >= 73000) return const GymRank(tier: RankTier.champion, subLevel: 3);
    if (score >= 62000) return const GymRank(tier: RankTier.champion, subLevel: 2);
    if (score >= 52000) return const GymRank(tier: RankTier.champion, subLevel: 1);

    if (score >= 43000) return const GymRank(tier: RankTier.diamond, subLevel: 3);
    if (score >= 35000) return const GymRank(tier: RankTier.diamond, subLevel: 2);
    if (score >= 28000) return const GymRank(tier: RankTier.diamond, subLevel: 1);

    if (score >= 22000) return const GymRank(tier: RankTier.plat, subLevel: 3);
    if (score >= 17000) return const GymRank(tier: RankTier.plat, subLevel: 2);
    if (score >= 13000) return const GymRank(tier: RankTier.plat, subLevel: 1);

    if (score >= 9500) return const GymRank(tier: RankTier.gold, subLevel: 3);
    if (score >= 7000) return const GymRank(tier: RankTier.gold, subLevel: 2);
    if (score >= 5000) return const GymRank(tier: RankTier.gold, subLevel: 1);

    if (score >= 3500) return const GymRank(tier: RankTier.silver, subLevel: 3);
    if (score >= 2400) return const GymRank(tier: RankTier.silver, subLevel: 2);
    if (score >= 1600) return const GymRank(tier: RankTier.silver, subLevel: 1);

    if (score >= 1000) return const GymRank(tier: RankTier.bronze, subLevel: 3);
    if (score >= 600) return const GymRank(tier: RankTier.bronze, subLevel: 2);
    if (score >= 300) return const GymRank(tier: RankTier.bronze, subLevel: 1);

    if (score >= 150) return const GymRank(tier: RankTier.wood, subLevel: 3);
    if (score > 0) return const GymRank(tier: RankTier.wood, subLevel: 2);
    return const GymRank(tier: RankTier.wood, subLevel: 1);
  }

  /// Bir egzersizin geçmişine göre rankını hesaplar
  static GymRank forExercise(Exercise exercise) {
    if (exercise.history.isEmpty) {
      return const GymRank(tier: RankTier.wood, subLevel: 1);
    }

    double totalVolume = 0;
    for (final h in exercise.history) {
      totalVolume += (h.weightKg * h.reps * h.sets);
    }
    final pr = exercise.personalRecordWeight;
    final score = (pr * 18.0) + (totalVolume * 0.85);

    return fromScore(score);
  }
}
