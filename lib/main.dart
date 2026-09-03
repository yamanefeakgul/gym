import 'dart:convert';
import 'package:flutter/material.dart';
import 'models/user_profile.dart';
import 'models/exercise.dart';
import 'services/exercise_database.dart';
import 'services/auth_service.dart';
import 'services/program_service.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'services/update_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/exercise_library_screen.dart';
import 'screens/progress_analytics_screen.dart';
import 'screens/skills/calisthenics_skill_tree_screen.dart';
import 'screens/community/ranks_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/cardio/cardio_screen.dart';
import 'services/sleep_tracking_service.dart';
import 'services/health_tracking_service.dart';
import 'services/cardio_tracking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  await ProgramService.init();
  await SleepTrackingService.init();
  await HealthTrackingService.init();
  await CardioTrackingService.init();
  runApp(const GymPulseApp());
}

class GymPulseApp extends StatelessWidget {
  const GymPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GYM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _isLoggedIn = AuthService.currentUser != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. İzinleri Kontrol Et (Bilinmeyen kaynaklardan yükleme + Bildirimler)
      await UpdateService.checkRequiredPermissions(context);
      // 2. Güncellemeleri Denetle
      if (mounted) {
        UpdateService.checkForUpdates(context);
      }
    });
  }

  void _onAuthStateChanged() {
    setState(() {
      _isLoggedIn = AuthService.currentUser != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen(onLoginSuccess: _onAuthStateChanged);
    }
    return MainNavigationScreen(onLogout: _onAuthStateChanged);
  }
}

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const MainNavigationScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late UserProfile _profile;
  late List<Exercise> _exercises;

  @override
  void initState() {
    super.initState();
    final activeUser = AuthService.currentUser;
    _profile = UserProfile(
      name: activeUser?.username ?? 'Sporcu',
      level: activeUser?.level ?? 1,
      currentXP: activeUser?.currentXP ?? 0,
      targetXP: activeUser?.targetXP ?? 500,
      streakDays: activeUser?.streakDays ?? 0,
      totalWorkoutsCompleted: activeUser?.totalWorkoutsCompleted ?? 0,
      totalTonnageLiftedKg: activeUser?.totalTonnageLiftedKg ?? 0.0,
      unlockedBadges: activeUser?.unlockedBadges ?? [],
      activityCalendar: activeUser?.activityCalendar ?? {},
    );
    _exercises = ExerciseDatabase.getAllExercises();

    _loadCloudOrLocalData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SleepTrackingService.checkInactivityOnStartup(context, _profile);
    });
  }

  void _loadCloudOrLocalData() async {
    // 1. Önce yerel hafızadan yükle (hızlı açılış)
    final savedProfile = await StorageService.loadUserProfile();
    if (savedProfile != null) {
      savedProfile.recalculateStreak();
      setState(() {
        _profile = savedProfile;
      });
    } else {
      _profile.recalculateStreak();
      setState(() {});
    }
    await StorageService.loadExercisesHistory(_exercises);
    setState(() {});
  }

  void _onLogWeight(String exerciseId, double weight, int reps, int sets) {
    setState(() {
      final exercise = _exercises.firstWhere((e) => e.id == exerciseId);
      final newEntry = WeightLogEntry(
        date: DateTime.now(),
        weightKg: weight,
        reps: reps,
        sets: sets,
      );
      exercise.history.add(newEntry);

      final addedTonnage = weight * reps * sets;
      _profile.totalTonnageLiftedKg += addedTonnage;
      _profile.totalWorkoutsCompleted += 1;

      final now = DateTime.now();
      final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _profile.activityCalendar[dateKey] = 'completed';
      _profile.recalculateStreak();

      final xpGained = (50 + (weight * 0.2)).toInt();
      _profile.currentXP += xpGained;

      if (_profile.currentXP >= _profile.targetXP) {
        _profile.currentXP -= _profile.targetXP;
        _profile.level += 1;
        _profile.targetXP = (_profile.targetXP * 1.4).toInt();
        _showLevelUpDialog(_profile.level);
      }

      if (weight >= 100 && !_profile.unlockedBadges.contains('heavy_lifter')) {
        _profile.unlockedBadges.add('heavy_lifter');
      }
      if (_profile.totalTonnageLiftedKg >= 10000 && !_profile.unlockedBadges.contains('ten_ton')) {
        _profile.unlockedBadges.add('ten_ton');
      }
      if (_profile.totalWorkoutsCompleted == 1 && !_profile.unlockedBadges.contains('first_lift')) {
        _profile.unlockedBadges.add('first_lift');
      }
      if (_profile.streakDays >= 3 && !_profile.unlockedBadges.contains('streak_3')) {
        _profile.unlockedBadges.add('streak_3');
      }

      // 1. Çevrimdışı koruma için yerel kaydet
      StorageService.saveUserProfile(_profile);
      StorageService.saveExercisesHistory(_exercises);

      // 2. TÜM VERİYİ VDS BULUT SUNUCUSUNA CANLI GÖNDER (SUNUCUDA DEPOLANIR)
      final user = AuthService.currentUser;
      if (user != null) {
        ApiService.syncUserData(
          user.id,
          _profile,
          ProgramService.activeProgramId,
          _exercises,
          _profile.unlockedBadges,
          customPrograms: ProgramService.customPrograms,
        );
      }
    });
  }

  void _showLevelUpDialog(int newLevel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.purpleXP, width: 2),
        ),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎉 TEBRİKLER! 🎉', style: TextStyle(color: AppTheme.goldRank, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥 SEVİYE ATLADIN! 🔥', style: TextStyle(color: AppTheme.primaryNeon, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.purpleXP.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Yeni Seviye: $newLevel',
                style: const TextStyle(color: AppTheme.purpleXP, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Unvan: ${_profile.rankTitle}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNeon,
                foregroundColor: AppTheme.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('GÜCÜ HİSSET', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        profile: _profile,
        exercises: _exercises,
        onLogWeight: _onLogWeight,
        onNavigateToPrograms: () {
          setState(() {
            _currentIndex = 1;
          });
        },
        onNavigateToProfile: () {
          setState(() {
            _currentIndex = 5; // Profil Sekmesi
          });
        },
      ),
      LibraryScreenContainer(
        exercises: _exercises,
        onLogWeight: _onLogWeight,
        onProgramChanged: () {
          setState(() {});
          final user = AuthService.currentUser;
          if (user != null) {
            ApiService.syncUserData(user.id, _profile, ProgramService.activeProgramId, _exercises, _profile.unlockedBadges);
          }
        },
      ),
      CalisthenicsSkillTreeScreen(
        profile: _profile,
      ),
      CardioScreen(
        currentProfile: _profile,
      ),
      RanksScreen(
        currentProfile: _profile,
        exercises: _exercises,
      ),
      ProfileScreen(
        profile: _profile,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: const Border(
            top: BorderSide(color: AppTheme.surfaceBorder, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryNeon,
          unselectedItemColor: AppTheme.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 9),
          items: const [
            BottomNavigationBarItem(
              icon: Text('🏠', style: TextStyle(fontSize: 18)),
              activeIcon: Text('🏠', style: TextStyle(fontSize: 20)),
              label: 'Ana Sayfa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: 'Kütüphane',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_tree_rounded),
              label: 'Skill Tree',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_run_rounded),
              label: 'Kardiyo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.military_tech_rounded),
              label: 'Rank',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
