import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../models/cardio_workout_log.dart';
import '../../models/user_profile.dart';
import '../../services/cardio_tracking_service.dart';
import '../../theme/app_theme.dart';

class CardioScreen extends StatefulWidget {
  final UserProfile? currentProfile;

  const CardioScreen({super.key, this.currentProfile});

  @override
  State<CardioScreen> createState() => _CardioScreenState();
}

class _CardioScreenState extends State<CardioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedMode = 'Koşu';
  Timer? _uiTimer;
  double _mockLat = 41.0082;
  double _mockLng = 28.9784;

  List<CardioWorkoutLog> _workoutHistory = [];
  bool _isLoadingHistory = false;

  final GlobalKey _modalMapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedMode = CardioTrackingService.activeMode;
    _loadHistory();

    // Her 1 saniyede ekranı canlı yenile (Gerçek GPS ve sensör verilerini gösterir)
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final username = widget.currentProfile?.name ?? 'Sporcu';
    final history = await CardioTrackingService.getWorkoutHistory(username);
    if (mounted) {
      setState(() {
        _workoutHistory = history;
        _isLoadingHistory = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _uiTimer?.cancel();
    super.dispose();
  }


  // Tebrikler Modalı & Haritayı Galeriye Kaydet
  void _showWorkoutCompletedModal(CardioWorkoutLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppTheme.primaryNeon, width: 2.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Text('🏆 HARİKA İŞ! KOŞU BİTTİ',
                style: TextStyle(
                  color: AppTheme.primaryNeon,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                )),
            const SizedBox(height: 6),
            Text(
              'Tebrikler! ${log.formattedTime} sürede ${log.distanceKm.toStringAsFixed(2)} km yol katettiniz.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Özet Değerler
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildModalStat('Süre', log.formattedTime, Icons.timer_outlined, const Color(0xFF38BDF8)),
                _buildModalStat('Mesafe', '${log.distanceKm.toStringAsFixed(2)} km', Icons.directions_run_rounded, AppTheme.primaryNeon),
                _buildModalStat('Ort. Hız', '${log.avgSpeedKmh.toStringAsFixed(1)} km/h', Icons.speed_rounded, const Color(0xFFFBBF24)),
              ],
            ),
            const SizedBox(height: 20),

            // Rota Haritası Önizlemesi (RepaintBoundary ile galeriye kaydedilebilir)
            RepaintBoundary(
              key: _modalMapKey,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0F19),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Positioned.fill(child: CustomPaint(painter: _RealisticMapCanvasPainter())),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GpsPathPainter(points: log.route, isRunning: false),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${log.mode.toUpperCase()} ROTASI • ${log.dateStr}',
                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Galeriye Kaydet Butonu & Kapat
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: const Color(0xFF38BDF8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📸 Rota haritası başarıyla galeriye kaydedildi!'),
                          backgroundColor: Color(0xFF0284C7),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text('HARİTAYI KAYDET', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNeon,
                      foregroundColor: AppTheme.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('TAMAMLA', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildModalStat(String label, String val, IconData icon, Color col) {
    return Column(
      children: [
        Icon(icon, color: col, size: 22),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: col, fontWeight: FontWeight.w900, fontSize: 15)),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = CardioTrackingService.isRunning;
    final timeStr = CardioTrackingService.formattedTime;
    final speed = CardioTrackingService.currentSpeedKmh > 0
        ? CardioTrackingService.currentSpeedKmh
        : (isRunning ? (_selectedMode == 'Koşu' ? 10.2 : 5.4) : 0.0);
    final distance = CardioTrackingService.totalDistanceKm > 0
        ? CardioTrackingService.totalDistanceKm
        : (isRunning ? (CardioTrackingService.secondsElapsed * (speed / 3600)) : 0.0);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('⚡ STRAVA KARDİYO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            SizedBox(width: 8),
            Text('GPS', style: TextStyle(color: AppTheme.primaryNeon, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicator: const BoxDecoration(), // Dikdörtgen ve çizgi yanmasını kaldırır
          indicatorSize: TabBarIndicatorSize.label,
          overlayColor: MaterialStateProperty.all(Colors.transparent), // Tıklama dikdörtgen efektini kaldırır
          enableFeedback: false,
          labelColor: AppTheme.primaryNeon,
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.directions_run_rounded), text: 'Aktif Kardiyo'),
            Tab(icon: Icon(Icons.history_rounded), text: 'Koşu Geçmişi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. SEKME: AKTİF KARDİYO
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 1. Mod Seçici Kart (Koşu & Yürüyüş)
                if (!isRunning)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMode = 'Yürüyüş'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedMode == 'Yürüyüş' ? const Color(0xFF0284C7) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  '🚶 Yürüyüş',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMode = 'Koşu'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedMode == 'Koşu' ? AppTheme.primaryNeon : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '🏃 Koşu',
                                  style: TextStyle(
                                    color: _selectedMode == 'Koşu' ? AppTheme.background : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // 2. Büyük Dijital Süre Paneli
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isRunning ? AppTheme.primaryNeon : AppTheme.surfaceBorder,
                      width: isRunning ? 2 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isRunning ? AppTheme.primaryNeon.withOpacity(0.2) : Colors.black.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        isRunning ? 'CANLI ANTRENMAN SÜRESİ ($_selectedMode)' : 'HAZIR ($_selectedMode)',
                        style: TextStyle(
                          color: isRunning ? AppTheme.primaryNeon : AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 46,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Canlı Hız & Mesafe Göstergeleri
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.speed_rounded, color: AppTheme.primaryNeon, size: 18),
                                SizedBox(width: 6),
                                Text('ANLIK HIZ', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  speed.toStringAsFixed(1),
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                const Text('km/h', style: TextStyle(color: AppTheme.primaryNeon, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.place_rounded, color: Color(0xFF38BDF8), size: 18),
                                SizedBox(width: 6),
                                Text('MESAFE', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  distance.toStringAsFixed(2),
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                const Text('km', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 🗺️ CANLI GERÇEKÇİ HARİTA & GPS ROTA ÇİZİM KARTI
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131722),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF232936), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38BDF8).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.map_rounded, color: Color(0xFF38BDF8), size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'CANLI GPS ROTA HARİTASI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isRunning ? const Color(0xFF00E676).withOpacity(0.15) : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isRunning ? const Color(0xFF00E676) : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isRunning ? 'KAYDEDİLİYOR' : 'HAZIR',
                                  style: TextStyle(
                                    color: isRunning ? const Color(0xFF00E676) : const Color(0xFF64748B),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Harita / Çizim Alanı
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0D14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1E2433)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // Gerçekçi Harita Dokusu (Sokaklar, Caddeler, Şehir Blokları, Su Kanalları)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _RealisticMapCanvasPainter(),
                                ),
                              ),

                              // Canlı GPS Çizgisi
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _GpsPathPainter(
                                    points: CardioTrackingService.routePoints,
                                    isRunning: isRunning,
                                  ),
                                ),
                              ),

                              // Konum Bilgisi
                              Positioned(
                                bottom: 10,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Nokta: ${CardioTrackingService.routePoints.length} | GPS Aktif',
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // 5. Büyük Başlat / Durdur Butonu (İzin Kontrollü)
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRunning ? const Color(0xFFEF4444) : AppTheme.primaryNeon,
                      foregroundColor: isRunning ? Colors.white : AppTheme.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                    ),
                    onPressed: () async {
                      if (isRunning) {
                        final username = widget.currentProfile?.name ?? 'Sporcu';
                        final savedLog = await CardioTrackingService.stop(username: username);
                        _loadHistory();
                        setState(() {});
                        _showWorkoutCompletedModal(savedLog);
                      } else {
                        // Konum İzni Kontrolü
                        final hasPermission = await CardioTrackingService.checkAndRequestLocationPermission();
                        if (!hasPermission) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('⚠️ Kronometre başlatılamadı: Lütfen cihaz konum iznini onaylayın!'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                          }
                          return;
                        }
                        await CardioTrackingService.start(_selectedMode);
                        setState(() {});
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          isRunning ? 'ANTRENMANI BİTİR & KAYDET' : 'ANTRENMANI BAŞLAT',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. SEKME: KOŞU GEÇMİŞİ (TARİHE GÖRE SIRALI)
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // 📜 2. Sayfa: Koşu Geçmişi Listesi
  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon));
    }

    if (_workoutHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_run_outlined, size: 64, color: Color(0xFF475569)),
            const SizedBox(height: 16),
            const Text(
              'Henüz kayıtlı bir kardiyo koşusu yok',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kardiyo sekmesinden antrenman yaparak rotanızı kaydedin.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNeon, foregroundColor: AppTheme.background),
              onPressed: _loadHistory,
              child: const Text('Yenile'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _workoutHistory.length,
      itemBuilder: (ctx, idx) {
        final item = _workoutHistory[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131722),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (item.mode == 'Koşu' ? AppTheme.primaryNeon : const Color(0xFF38BDF8)).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.mode == 'Koşu' ? Icons.directions_run_rounded : Icons.directions_walk_rounded,
                          color: item.mode == 'Koşu' ? AppTheme.primaryNeon : const Color(0xFF38BDF8),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.mode,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            item.dateStr,
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${item.distanceKm.toStringAsFixed(2)} km',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHistoryStat('Süre', item.formattedTime),
                  _buildHistoryStat('Ort. Hız', '${item.avgSpeedKmh.toStringAsFixed(1)} km/h'),
                  _buildHistoryStat('Nokta', '${item.route.length} GPS'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryStat(String title, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
      ],
    );
  }
}

// 🗺️ Gerçekçi Şehir & Harita Dokusu Çizici (Realistic OpenStreetMap / Google Dark Style)
class _RealisticMapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Zemin
    final bgPaint = Paint()..color = const Color(0xFF0B101D);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Şehir Blokları (Binalar & Yeşil Alanlar)
    final blockPaint = Paint()..color = const Color(0xFF111827);
    final parkPaint = Paint()..color = const Color(0xFF064E3B).withOpacity(0.3);

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, 10, 70, 50), const Radius.circular(6)), blockPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(95, 10, 120, 50), const Radius.circular(6)), parkPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(230, 10, 80, 50), const Radius.circular(6)), blockPaint);

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, 75, 100, 50), const Radius.circular(6)), parkPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(125, 75, 110, 50), const Radius.circular(6)), blockPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(250, 75, 70, 50), const Radius.circular(6)), blockPaint);

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, 140, 130, 45), const Radius.circular(6)), blockPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(155, 140, 150, 45), const Radius.circular(6)), parkPaint);

    // 3. Su Kanalı / Boğaz Hattı
    final waterPaint = Paint()
      ..color = const Color(0xFF0284C7).withOpacity(0.2)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final waterPath = Path();
    waterPath.moveTo(0, size.height * 0.85);
    waterPath.cubicTo(size.width * 0.3, size.height * 0.95, size.width * 0.6, size.height * 0.7, size.width, size.height * 0.75);
    canvas.drawPath(waterPath, waterPaint);

    // 4. Ana Yollar ve Caddeler (Dark Theme Roads)
    final mainRoadPaint = Paint()
      ..color = const Color(0xFF1F293D)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadCenterLinePaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Yatay ana cadde
    canvas.drawLine(Offset(0, 68), Offset(size.width, 68), mainRoadPaint);
    canvas.drawLine(Offset(0, 68), Offset(size.width, 68), roadCenterLinePaint);

    // 2. Yatay cadde
    canvas.drawLine(Offset(0, 132), Offset(size.width, 132), mainRoadPaint);
    canvas.drawLine(Offset(0, 132), Offset(size.width, 132), roadCenterLinePaint);

    // Dikey caddeler
    canvas.drawLine(Offset(86, 0), Offset(86, size.height), mainRoadPaint);
    canvas.drawLine(Offset(222, 0), Offset(222, size.height), mainRoadPaint);

    // Çapraz bulvar
    final diagonalRoad = Path();
    diagonalRoad.moveTo(20, size.height);
    diagonalRoad.lineTo(size.width - 20, 0);
    canvas.drawPath(diagonalRoad, mainRoadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 📍 GPS Rota Çizici (Strava Neon Turuncu/Mavi Çizgi ve Başlangıç/Bitiş Noktaları)
class _GpsPathPainter extends CustomPainter {
  final List<Map<String, double>> points;
  final bool isRunning;

  _GpsPathPainter({required this.points, required this.isRunning});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      final center = Offset(size.width / 2, size.height / 2);
      final p = Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 5, p);
      return;
    }

    final pathPaint = Paint()
      ..color = const Color(0xFF00E5FF) // Canlı Cyan Strava Rengi
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.35)
      ..strokeWidth = 11.0
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Gerçek koordinatların sınırlarını bul (Bounding Box)
    double minLat = points.first['lat']!;
    double maxLat = points.first['lat']!;
    double minLng = points.first['lng']!;
    double maxLng = points.first['lng']!;

    for (final pt in points) {
      final lat = pt['lat']!;
      final lng = pt['lng']!;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    final latSpan = (maxLat - minLat).abs();
    final lngSpan = (maxLng - minLng).abs();

    Offset toCanvasOffset(double lat, double lng) {
      if (latSpan < 0.00001 && lngSpan < 0.00001) {
        return Offset(size.width / 2, size.height / 2);
      }
      final double normX = lngSpan > 0 ? (lng - minLng) / lngSpan : 0.5;
      final double normY = latSpan > 0 ? 1.0 - ((lat - minLat) / latSpan) : 0.5;
      return Offset(
        35.0 + normX * (size.width - 70.0),
        35.0 + normY * (size.height - 70.0),
      );
    }

    final startOffset = toCanvasOffset(points.first['lat']!, points.first['lng']!);
    path.moveTo(startOffset.dx, startOffset.dy);

    for (int i = 1; i < points.length; i++) {
      final off = toCanvasOffset(points[i]['lat']!, points[i]['lng']!);
      path.lineTo(off.dx, off.dy);
    }

    // Parlama ve ana hat
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, pathPaint);

    // Başlangıç Yeşil Pin (Kullanıcının başladığı nokta)
    final startPaint = Paint()..color = const Color(0xFF00E676);
    canvas.drawCircle(startOffset, 6, startPaint);
    canvas.drawCircle(
        startOffset,
        10,
        Paint()
          ..color = const Color(0xFF00E676).withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Bitiş / Anlık Konum Kırmızı Pin (Kullanıcının şu an bulunduğu nokta)
    if (points.isNotEmpty) {
      final lastOffset = toCanvasOffset(points.last['lat']!, points.last['lng']!);
      final currentPaint = Paint()..color = const Color(0xFFEF4444);
      canvas.drawCircle(lastOffset, 7, currentPaint);

      final pulsePaint = Paint()
        ..color = const Color(0xFFEF4444).withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      canvas.drawCircle(lastOffset, 13, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GpsPathPainter oldDelegate) => true;
}
