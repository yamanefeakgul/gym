enum DayActivityStatus {
  completed,
  restFreeze,
  missed,
}

class UserProfile {
  String name;
  int level;
  int currentXP;
  int targetXP;
  int streakDays;
  int totalWorkoutsCompleted;
  double totalTonnageLiftedKg;
  List<String> unlockedBadges;
  Map<String, String> activityCalendar;

  // Vücut Kompozisyonu & Profil Alanları
  double weightKg;
  String gender; // 'Erkek', 'Kadın', 'Belirtilmemiş'
  double bodyFat; // Yağ değeri
  bool isFatPercentage; // true: %, false: kg
  double muscleMass; // Kas değeri
  bool isMusclePercentage; // true: %, false: kg
  String? avatarBase64; // Profil Fotoğrafı Base64 verisi

  UserProfile({
    required this.name,
    this.level = 1,
    this.currentXP = 0,
    this.targetXP = 500,
    this.streakDays = 0,
    this.totalWorkoutsCompleted = 0,
    this.totalTonnageLiftedKg = 0.0,
    List<String>? unlockedBadges,
    Map<String, String>? activityCalendar,
    this.weightKg = 75.0,
    this.gender = 'Erkek',
    this.bodyFat = 15.0,
    this.isFatPercentage = true,
    this.muscleMass = 35.0,
    this.isMusclePercentage = false,
    this.avatarBase64,
  })  : unlockedBadges = unlockedBadges ?? [],
        activityCalendar = activityCalendar ?? {};

  String get rankTitle {
    if (level < 3) return 'Gym Çaylağı';
    if (level < 6) return 'Demir Savaşçısı';
    if (level < 10) return 'Ağırlık Canavarı';
    if (level < 15) return 'Titan';
    return 'Olympia Şampiyonu';
  }

  double get xpProgress => targetXP > 0 ? (currentXP / targetXP).clamp(0.0, 1.0) : 0.0;

  // 🌟 Gerçek Takvim Tarihlerine Göre Streak'i Yeniden Hesapla
  void recalculateStreak() {
    final now = DateTime.now();
    int currentStreak = 0;
    
    // Bugün antrenman yapıldı mı?
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final hasToday = activityCalendar[todayKey] == 'completed' || activityCalendar[todayKey] == 'rest';

    // Dünden geriye doğru say (Bugün henüz yapılmadıysa dün yapıldıysa seri bozulmamıştır)
    int offset = hasToday ? 0 : 1;

    while (true) {
      final checkDate = now.subtract(Duration(days: offset));
      final key = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      final status = activityCalendar[key];

      if (status == 'completed' || status == 'rest') {
        currentStreak++;
        offset++;
      } else {
        break; // Seri kırıldı
      }
    }

    streakDays = currentStreak;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'level': level,
        'currentXP': currentXP,
        'targetXP': targetXP,
        'streakDays': streakDays,
        'totalWorkoutsCompleted': totalWorkoutsCompleted,
        'totalTonnageLiftedKg': totalTonnageLiftedKg,
        'unlockedBadges': unlockedBadges,
        'activityCalendar': activityCalendar,
        'weightKg': weightKg,
        'gender': gender,
        'bodyFat': bodyFat,
        'isFatPercentage': isFatPercentage,
        'muscleMass': muscleMass,
        'isMusclePercentage': isMusclePercentage,
        'avatarBase64': avatarBase64,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] ?? 'Sporcu',
        level: json['level'] ?? 1,
        currentXP: json['currentXP'] ?? 0,
        targetXP: json['targetXP'] ?? 500,
        streakDays: json['streakDays'] ?? 0,
        totalWorkoutsCompleted: json['totalWorkoutsCompleted'] ?? 0,
        totalTonnageLiftedKg: (json['totalTonnageLiftedKg'] as num?)?.toDouble() ?? 0.0,
        unlockedBadges: List<String>.from(json['unlockedBadges'] ?? []),
        activityCalendar: Map<String, String>.from(json['activityCalendar'] ?? {}),
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 75.0,
        gender: json['gender'] ?? 'Erkek',
        bodyFat: (json['bodyFat'] as num?)?.toDouble() ?? 15.0,
        isFatPercentage: json['isFatPercentage'] ?? true,
        muscleMass: (json['muscleMass'] as num?)?.toDouble() ?? 35.0,
        isMusclePercentage: json['isMusclePercentage'] ?? false,
        avatarBase64: json['avatarBase64'],
      );
}

class BadgeItem {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;

  const BadgeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
  });
}

final List<BadgeItem> allBadges = [
  const BadgeItem(
    id: 'first_lift',
    title: 'İlk Kaldırış',
    description: 'İlk ağırlık setini başarıyla kaydettin!',
    iconEmoji: '🥉',
  ),
  const BadgeItem(
    id: 'streak_3',
    title: '3 Günlük Seri',
    description: '3 gün boyunca antrenman disiplinini korudun.',
    iconEmoji: '🔥',
  ),
  const BadgeItem(
    id: 'heavy_lifter',
    title: '100KG Kulübü',
    description: 'Herhangi bir harekette 100 kg ve üzeri rekor kırdın.',
    iconEmoji: '🦍',
  ),
  const BadgeItem(
    id: 'ten_ton',
    title: '10 Ton Kulübü',
    description: 'Toplam 10.000 kg ağırlık hacmine ulaştın.',
    iconEmoji: '⚡',
  ),
  const BadgeItem(
    id: 'consistency_king',
    title: 'Süreklilik Kralı',
    description: '7 günlük kesintisiz streak elde ettin.',
    iconEmoji: '👑',
  ),
];
