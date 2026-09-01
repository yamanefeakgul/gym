class SleepLog {
  final DateTime sleepStart;
  final DateTime sleepEnd;
  final double durationHours;
  final String qualityScore; // 'Yetersiz 😴', 'İyi 😊', 'Mükemmel ⚡ (Titan)'
  final String recoveryBonus; // '+%0', '+%10', '+%20 Toparlanma & XP'
  final String advice;

  SleepLog({
    required this.sleepStart,
    required this.sleepEnd,
    required this.durationHours,
    required this.qualityScore,
    required this.recoveryBonus,
    required this.advice,
  });

  Map<String, dynamic> toJson() => {
        'sleepStart': sleepStart.toIso8601String(),
        'sleepEnd': sleepEnd.toIso8601String(),
        'durationHours': durationHours,
        'qualityScore': qualityScore,
        'recoveryBonus': recoveryBonus,
        'advice': advice,
      };

  factory SleepLog.fromJson(Map<String, dynamic> json) => SleepLog(
        sleepStart: DateTime.parse(json['sleepStart']),
        sleepEnd: DateTime.parse(json['sleepEnd']),
        durationHours: (json['durationHours'] as num).toDouble(),
        qualityScore: json['qualityScore'] ?? 'İyi 😊',
        recoveryBonus: json['recoveryBonus'] ?? '+%10',
        advice: json['advice'] ?? '',
      );

  static SleepLog evaluate(DateTime start, DateTime end) {
    final diffMins = end.difference(start).inMinutes;
    final hours = diffMins / 60.0;

    String score;
    String bonus;
    String advice;

    if (hours < 5.0) {
      score = 'Yetersiz & Kritik 😴';
      bonus = '%0 (Toparlanma Zayıf)';
      advice = 'Az uyku kortizolü artırır ve kas yıkımını tetikler. Bugün antrenmanda aşırı ağır kilolardan kaçın!';
    } else if (hours < 7.0) {
      score = 'Orta & İdare Eder 🥱';
      bonus = '+%5 Toparlanma';
      advice = 'Toparlanma sürecin fena değil ama hipertrofi ve güç artışı için 7.5 saatin üzerine çıkmalısın.';
    } else if (hours <= 9.0) {
      score = 'Mükemmel & Titan ⚡';
      bonus = '+%20 Toparlanma & +100 Bonus XP';
      advice = 'Derin uyku ve büyüme hormonu (GH) zirvede! Bugün salonda PR (Kişisel Rekor) kırmak için harika bir gün!';
    } else {
      score = 'Fazla & Derin Dinlenme 🛌';
      bonus = '+%10 Toparlanma';
      advice = 'Vücut tamamen dinlendi. Vücudu uyandırmak için antrenman öncesi iyi bir dinamik ısınma yap.';
    }

    return SleepLog(
      sleepStart: start,
      sleepEnd: end,
      durationHours: double.parse(hours.toStringAsFixed(1)),
      qualityScore: score,
      recoveryBonus: bonus,
      advice: advice,
    );
  }
}
