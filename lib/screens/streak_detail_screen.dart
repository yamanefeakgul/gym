import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';

class StreakDetailScreen extends StatefulWidget {
  final UserProfile profile;

  const StreakDetailScreen({
    super.key,
    required this.profile,
  });

  @override
  State<StreakDetailScreen> createState() => _StreakDetailScreenState();
}

class _StreakDetailScreenState extends State<StreakDetailScreen> with SingleTickerProviderStateMixin {
  late DateTime _selectedMonth;
  late AnimationController _flameController;
  late Animation<double> _flameScale;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _flameScale = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = widget.profile.streakDays;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117), // Koyu arka plan
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Üst Turuncu Hero Banner (Görsel 1 Tarzı)
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFE8590C), // Canlı Turuncu
                      Color(0xFFD9480F),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66E8590C),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Üst Navigasyon Barı: Geri Butonu + "Streaks" + Sağ Butonlar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Streaks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.history_rounded, color: Colors.white, size: 24),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 22),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Büyük Streak Sayısı ve Alev
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$streak',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 68,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'current streak!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          ScaleTransition(
                            scale: _flameScale,
                            child: const Text(
                              '🔥',
                              style: TextStyle(fontSize: 72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Season Calendar Başlığı & Takvim Kartı (Görsel 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Season Calendar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Takvim Kutusu (Koyu Gece Mavisi Zemin)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2D),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF2E2E42), width: 1.2),
                      ),
                      child: Column(
                        children: [
                          // Ay & Yıl Başlığı
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatMonthYear(_selectedMonth),
                                style: const TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Gün İsimleri (Su, Mo, Tu, We, Th, Fr, Sa)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const [
                              _DayHeader('Su'),
                              _DayHeader('Mo'),
                              _DayHeader('Tu'),
                              _DayHeader('We'),
                              _DayHeader('Th'),
                              _DayHeader('Fr'),
                              _DayHeader('Sa'),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Ayın Günleri Grid'i
                          _buildMonthGrid(widget.profile, _selectedMonth, now),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seri İpuçları & Motivasyon Kartı
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161822),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF26293A)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8590C).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('💪', style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Serini Asla Bozma!',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Her antrenman ve dinlenme günü kaydında serin korunur ve seviye atlaman hızlanır.',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildMonthGrid(UserProfile profile, DateTime month, DateTime now) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Pazar: 0, Pzt: 1 ... Cmt: 6
    final int startWeekday = firstDayOfMonth.weekday % 7; 

    final List<Widget> dayWidgets = [];

    // Önceki aydan kalan boşluklar
    for (int i = 0; i < startWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    // Bu ayın günleri
    for (int day = 1; day <= daysInMonth; day++) {
      final currentDayDate = DateTime(month.year, month.month, day);
      final key = '${currentDayDate.year}-${currentDayDate.month.toString().padLeft(2, '0')}-${currentDayDate.day.toString().padLeft(2, '0')}';
      final status = profile.activityCalendar[key];
      final isToday = currentDayDate.year == now.year && currentDayDate.month == now.month && currentDayDate.day == now.day;

      final isCompleted = status == 'completed';
      final isRest = status == 'rest';

      Widget content;
      BoxDecoration decoration;

      if (isCompleted) {
        // Tamamlandı: Kas / Pazı simgesi sarı daire içinde (Görsel 1'deki 💪 ikonu)
        decoration = const BoxDecoration(
          color: Color(0xFFFBBF24), // Sarı zemin
          shape: BoxShape.circle,
        );
        content = const Center(
          child: Text('💪', style: TextStyle(fontSize: 16)),
        );
      } else if (isRest) {
        // Dinlenme günü (Buz)
        decoration = const BoxDecoration(
          color: Color(0xFF38BDF8),
          shape: BoxShape.circle,
        );
        content = const Center(
          child: Text('❄️', style: TextStyle(fontSize: 14)),
        );
      } else if (isToday) {
        // Bugün: Sarı halkalı çerçeve (Görsel 1'deki 3 günü gibi)
        decoration = BoxDecoration(
          color: const Color(0xFF2A2B3D),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFBBF24), width: 2.2),
        );
        content = Center(
          child: Text(
            '$day',
            style: const TextStyle(
              color: Color(0xFFFBBF24),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        );
      } else {
        // Normal veya geçmiş gün
        decoration = const BoxDecoration(
          color: Color(0xFF2A2B3D), // Koyu yuvarlak buton
          shape: BoxShape.circle,
        );
        content = Center(
          child: Text(
            '$day',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        );
      }

      dayWidgets.add(
        Container(
          margin: const EdgeInsets.all(4),
          decoration: decoration,
          child: content,
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.0,
      children: dayWidgets,
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String label;
  const _DayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
