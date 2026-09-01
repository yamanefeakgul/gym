import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart';
import '../models/workout_program.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'program_service.dart';

class AuthService {
  static const String _userKey = 'gym_active_user';
  static AuthUser? currentUser;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      try {
        currentUser = AuthUser.fromJson(jsonDecode(userStr));
      } catch (_) {}
    }
  }

  // VDS Server Doğrudan Giriş
  static Future<bool> login(String email, String password) async {
    final res = await ApiService.login(email, password);
    if (res != null && res['success'] == true && res['user'] != null) {
      currentUser = AuthUser.fromJson(res['user']);
      await _saveUser();

      // VDS'ten gelen özel programları geri yükle
      if (res['customPrograms'] != null) {
        final List list = res['customPrograms'];
        final programs = list.map((e) => WorkoutProgram.fromJson(e)).toList();
        await StorageService.saveCustomPrograms(programs);
        ProgramService.customPrograms = programs;
      }

      // VDS'ten gelen ağırlık geçmişini geri yükle
      if (res['exercisesHistory'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('gym_exercises_history', jsonEncode(res['exercisesHistory']));
      }

      return true;
    }
    return false;
  }

  // VDS Server Doğrudan Kayıt
  static Future<bool> register(String username, String email, String password, String goal) async {
    final user = await ApiService.register(username, email, password, goal);
    if (user != null) {
      currentUser = user;
      await _saveUser();
      return true;
    }
    return false;
  }

  static Future<void> logout() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  static Future<void> _saveUser() async {
    if (currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(currentUser!.toJson()));
    }
  }
}
