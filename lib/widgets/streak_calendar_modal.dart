import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';

class StreakCalendarModal extends StatelessWidget {
  final UserProfile profile;

  const StreakCalendarModal({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final calendar = profile.activityCalendar;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('🔥', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STREAK AKTİVİTE TAKVİMİ',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        '${profile.streakDays} Gün Kesintisiz Seri!',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppTheme.surfaceBorder),
          const SizedBox(height: 10),

          // Açıklama Lejantı (Legend)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Antrenman', Colors.redAccent, '🔥'),
              _buildLegendItem('Dinlenme (Buz)', const Color(0xFF00D1FF), '❄️'),
              _buildLegendItem('Kaçırıldı', AppTheme.surfaceBorder, '⚪'),
            ],
          ),

          const SizedBox(height: 16),

          // Son 28 Günün Grid Görünümü (Haftalık sütunlar)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: 28,
              itemBuilder: (context, index) {
                final date = now.subtract(Duration(days: 27 - index));
                final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                final status = calendar[dateKey] ?? 'missed';

                Color bgColor = AppTheme.surfaceLight;
                Color borderColor = AppTheme.surfaceBorder;
                String emoji = '';

                if (status == 'completed') {
                  bgColor = Colors.redAccent.withOpacity(0.25);
                  borderColor = Colors.redAccent;
                  emoji = '🔥';
                } else if (status == 'rest') {
                  bgColor = const Color(0xFF00D1FF).withOpacity(0.25);
                  borderColor = const Color(0xFF00D1FF);
                  emoji = '❄️';
                } else {
                  bgColor = AppTheme.surfaceLight.withOpacity(0.5);
                  borderColor = AppTheme.surfaceBorder;
                }

                return Tooltip(
                  message: '${date.day}/${date.month} - ${status == 'completed' ? 'Antrenman Yapıldı' : (status == 'rest' ? 'Dinlenme Günü (Donduruldu)' : 'Kaçırıldı')}',
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor, width: 1.2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: status == 'completed' ? Colors.redAccent : (status == 'rest' ? const Color(0xFF00D1FF) : AppTheme.textMuted),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (emoji.isNotEmpty)
                          Text(emoji, style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Dinlenme günlerinde streak kaybolmaz, buz korumasıyla dondurulur! 🛡️❄️',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF00D1FF), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
