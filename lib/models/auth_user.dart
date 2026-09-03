class AuthUser {
  final String id;
  final String username;
  final String email;
  final String goal;
  final int level;
  final int currentXP;
  final int targetXP;
  final int streakDays;
  final int totalWorkoutsCompleted;
  final double totalTonnageLiftedKg;
  final List<String> unlockedBadges;
  final Map<String, String> activityCalendar;
  final String? activeProgramId;
  final String? avatarBase64;

  AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.goal,
    this.level = 1,
    this.currentXP = 0,
    this.targetXP = 500,
    this.streakDays = 0,
    this.totalWorkoutsCompleted = 0,
    this.totalTonnageLiftedKg = 0.0,
    this.unlockedBadges = const [],
    this.activityCalendar = const {},
    this.activeProgramId,
    this.avatarBase64,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'goal': goal,
        'level': level,
        'currentXP': currentXP,
        'targetXP': targetXP,
        'streakDays': streakDays,
        'totalWorkoutsCompleted': totalWorkoutsCompleted,
        'totalTonnageLiftedKg': totalTonnageLiftedKg,
        'unlockedBadges': unlockedBadges,
        'activityCalendar': activityCalendar,
        'activeProgramId': activeProgramId,
        'avatarBase64': avatarBase64,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] ?? '',
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        goal: json['goal'] ?? '',
        level: json['level'] ?? 1,
        currentXP: json['currentXP'] ?? 0,
        targetXP: json['targetXP'] ?? 500,
        streakDays: json['streakDays'] ?? 0,
        totalWorkoutsCompleted: json['totalWorkoutsCompleted'] ?? 0,
        totalTonnageLiftedKg: (json['totalTonnageLiftedKg'] as num?)?.toDouble() ?? 0.0,
        unlockedBadges: List<String>.from(json['unlockedBadges'] ?? []),
        activityCalendar: Map<String, String>.from(json['activityCalendar'] ?? {}),
        activeProgramId: json['activeProgramId'],
        avatarBase64: json['avatarBase64'],
      );
}

class LeaderboardEntry {
  final int rank;
  final String? userId;
  final String username;
  final String goal;
  final int level;
  final int currentXP;
  final int targetXP;
  final String rankTitle;
  final double totalTonnage;
  final double totalTonnageKg;
  final int streakDays;
  final int totalWorkoutsCompleted;
  final double weightKg;
  final String gender;
  final double bodyFat;
  final bool isFatPercentage;
  final double muscleMass;
  final bool isMusclePercentage;
  final int unlockedBadgesCount;
  final String? avatarBase64;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    this.userId,
    required this.username,
    this.goal = 'Kas ve Güç Kazanımı',
    required this.level,
    this.currentXP = 0,
    this.targetXP = 500,
    required this.rankTitle,
    required this.totalTonnage,
    this.totalTonnageKg = 0.0,
    required this.streakDays,
    this.totalWorkoutsCompleted = 0,
    this.weightKg = 75.0,
    this.gender = 'Erkek',
    this.bodyFat = 15.0,
    this.isFatPercentage = true,
    this.muscleMass = 35.0,
    this.isMusclePercentage = false,
    this.unlockedBadgesCount = 0,
    this.avatarBase64,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, {bool isCurrentUser = false}) =>
      LeaderboardEntry(
        rank: json['rank'] ?? 1,
        userId: json['userId'],
        username: json['username'] ?? '',
        goal: json['goal'] ?? 'Kas ve Güç Kazanımı',
        level: json['level'] ?? 1,
        currentXP: json['currentXP'] ?? 0,
        targetXP: json['targetXP'] ?? 500,
        rankTitle: json['rankTitle'] ?? 'Gym Çaylağı',
        totalTonnage: (json['totalTonnage'] as num?)?.toDouble() ?? 0.0,
        totalTonnageKg: (json['totalTonnageKg'] as num?)?.toDouble() ?? 0.0,
        streakDays: json['streakDays'] ?? 0,
        totalWorkoutsCompleted: json['totalWorkoutsCompleted'] ?? 0,
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 75.0,
        gender: json['gender'] ?? 'Erkek',
        bodyFat: (json['bodyFat'] as num?)?.toDouble() ?? 15.0,
        isFatPercentage: json['isFatPercentage'] ?? true,
        muscleMass: (json['muscleMass'] as num?)?.toDouble() ?? 35.0,
        isMusclePercentage: json['isMusclePercentage'] ?? false,
        unlockedBadgesCount: json['unlockedBadgesCount'] ?? 0,
        avatarBase64: json['avatarBase64'],
        isCurrentUser: isCurrentUser,
      );

  double get competitiveRankScore {
    return (totalTonnage * 10) + (level * 150) + (streakDays * 25) + (totalWorkoutsCompleted * 50);
  }

  String get competitiveRankTier {
    final score = competitiveRankScore;
    if (score < 400) return 'BRONZE I';
    if (score < 800) return 'BRONZE II';
    if (score < 1400) return 'SILVER I';
    if (score < 2200) return 'SILVER II';
    if (score < 3500) return 'GOLD I';
    if (score < 5000) return 'GOLD II';
    if (score < 7500) return 'PLATINUM I';
    if (score < 10000) return 'PLATINUM II';
    if (score < 15000) return 'DIAMOND';
    return 'TITAN OLYMPIA';
  }
}
