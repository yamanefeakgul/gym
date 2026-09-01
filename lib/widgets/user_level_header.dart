import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import 'streak_calendar_modal.dart';

class UserLevelHeader extends StatelessWidget {
  final UserProfile profile;

  const UserLevelHeader({
    super.key,
    required this.profile,
  });

  void _openStreakModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StreakCalendarModal(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = profile.avatarBase64 != null && profile.avatarBase64!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surface,
            AppTheme.surfaceLight.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar & Level Badge (Dinamik Fotoğraf Desteği)
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryNeon, AppTheme.primaryAccent],
                      ),
                      border: Border.all(color: AppTheme.primaryNeon, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryNeon.withOpacity(0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: hasAvatar
                          ? Image.memory(
                              base64Decode(profile.avatarBase64!),
                              fit: BoxFit.cover,
                            )
                          : const Center(
                              child: Text(
                                '⚔️',
                                style: TextStyle(fontSize: 28),
                              ),
                            ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.purpleXP,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.background, width: 1.5),
                    ),
                    child: Text(
                      'LV ${profile.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Name, Title and Streak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Streak Flame Action
                        InkWell(
                          onTap: () => _openStreakModal(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: profile.streakDays > 0
                                  ? const Color(0xFFEF4444).withOpacity(0.15)
                                  : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: profile.streakDays > 0
                                    ? const Color(0xFFEF4444).withOpacity(0.5)
                                    : AppTheme.surfaceBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  profile.streakDays > 0 ? '🔥' : '⚪',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${profile.streakDays} Gün',
                                  style: TextStyle(
                                    color: profile.streakDays > 0
                                        ? const Color(0xFFEF4444)
                                        : AppTheme.textMuted,
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
                    const SizedBox(height: 2),
                    Text(
                      profile.rankTitle,
                      style: const TextStyle(
                        color: AppTheme.goldRank,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // XP Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SEVİYE İLERLEMESİ',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '${profile.currentXP} / ${profile.targetXP} XP',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 8,
                  child: LinearProgressIndicator(
                    value: profile.xpProgress,
                    backgroundColor: AppTheme.surfaceBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryNeon),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
