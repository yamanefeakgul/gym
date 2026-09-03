import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_user.dart';
import '../models/workout_program.dart';
import '../models/user_profile.dart';
import '../models/exercise.dart';
import '../models/cardio_workout_log.dart';
import '../models/body_measurement.dart';

class ApiService {
  static String baseUrl = 'http://166.1.94.116:3000';

  // 1. KAYIT OL (VDS Server DB)
  static Future<AuthUser?> register(String username, String email, String password, String goal) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'goal': goal,
        }),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return AuthUser.fromJson(data['user']);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // 2. GİRİŞ YAP (VDS Server DB - Profil, Ağırlık Geçmişi ve Programlar Buluttan Gelir)
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // 3. KULLANICI PROFİLİ, ÖZEL PROGRAMLAR, AĞIRLIK GEÇMİŞİ VE AVATAR CANLI VDS BULUT SENKRONİZASYONU
  static Future<void> syncUserData(
    String userId,
    UserProfile profile,
    String? activeProgramId,
    List<Exercise> exercises,
    List<String> masteredSkills, {
    List<WorkoutProgram>? customPrograms,
  }) async {
    try {
      final Map<String, dynamic> historyMap = {};
      for (var ex in exercises) {
        if (ex.history.isNotEmpty) {
          historyMap[ex.id] = ex.history.map((h) => h.toJson()).toList();
        }
      }

      final List<Map<String, dynamic>>? progsList = customPrograms?.map((p) => p.toJson()).toList();

      await http.post(
        Uri.parse('$baseUrl/api/user/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'profile': {
            'level': profile.level,
            'currentXP': profile.currentXP,
            'targetXP': profile.targetXP,
            'streakDays': profile.streakDays,
            'totalWorkoutsCompleted': profile.totalWorkoutsCompleted,
            'totalTonnageLiftedKg': profile.totalTonnageLiftedKg,
            'unlockedBadges': profile.unlockedBadges,
            'activityCalendar': profile.activityCalendar,
            'activeProgramId': activeProgramId,
            'calisthenicsMasteredSkills': masteredSkills,
            'weightKg': profile.weightKg,
            'gender': profile.gender,
            'bodyFat': profile.bodyFat,
            'isFatPercentage': profile.isFatPercentage,
            'muscleMass': profile.muscleMass,
            'isMusclePercentage': profile.isMusclePercentage,
            'avatarBase64': profile.avatarBase64,
          },
          'customPrograms': progsList,
          'exercisesHistory': historyMap,
          'avatarBase64': profile.avatarBase64,
        }),
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      // ignore
    }
  }

  // 4. PROGRAMI VDS SUNUCUSUNA KAYDET
  static Future<bool> saveProgramToCloud(WorkoutProgram program) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/programs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(program.toJson()),
      ).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 5. VDS SUNUCUSUNDAKİ TÜM PROGRAMLARI ÇEK
  static Future<List<WorkoutProgram>> fetchCloudPrograms() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/programs')).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => WorkoutProgram.fromJson(e)).toList();
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  // 6. LİDERLİK TABLOSU
  static Future<List<LeaderboardEntry>> fetchLeaderboard(String currentUsername) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/leaderboard')).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((item) {
          return LeaderboardEntry.fromJson(item, isCurrentUser: item['username'] == currentUsername);
        }).toList();
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  // 7. KARDİYO KOŞU GEÇMİŞİNİ SUNUCUYA KAYDET
  static Future<bool> saveCardioLog(String username, CardioWorkoutLog log) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/cardio'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'log': log.toJson(),
        }),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 8. KARDİYO KOŞU GEÇMİŞİNİ ÇEK
  static Future<List<CardioWorkoutLog>> fetchCardioLogs(String username) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/cardio/$username'),
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => CardioWorkoutLog.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // 9. BODYGRAPH VÜCUT ÖLÇÜM GEÇMİŞİNİ SUNUCUYA KAYDET
  static Future<bool> saveBodyMeasurements(String username, List<BodyMeasurementEntry> entries) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/bodygraph'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'measurements': entries.map((e) => e.toJson()).toList(),
        }),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 10. BODYGRAPH VÜCUT ÖLÇÜM GEÇMİŞİNİ ÇEK
  static Future<List<BodyMeasurementEntry>> fetchBodyMeasurements(String username) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/bodygraph/$username'),
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => BodyMeasurementEntry.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }
}
