import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/update_service.dart';
import '../services/exercise_database.dart';
import '../services/program_service.dart';
import '../services/sleep_tracking_service.dart';
import '../models/sleep_log.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _weightController;
  late TextEditingController _fatController;
  late TextEditingController _muscleController;
  late String _selectedGender;
  late bool _isFatPercentage;
  late bool _isMusclePercentage;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: '${widget.profile.weightKg}');
    _fatController = TextEditingController(text: '${widget.profile.bodyFat}');
    _muscleController = TextEditingController(text: '${widget.profile.muscleMass}');
    _selectedGender = widget.profile.gender;
    _isFatPercentage = widget.profile.isFatPercentage;
    _isMusclePercentage = widget.profile.isMusclePercentage;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _fatController.dispose();
    _muscleController.dispose();
    super.dispose();
  }

  void _saveBodyMetrics() {
    final w = double.tryParse(_weightController.text) ?? widget.profile.weightKg;
    final f = double.tryParse(_fatController.text) ?? widget.profile.bodyFat;
    final m = double.tryParse(_muscleController.text) ?? widget.profile.muscleMass;

    setState(() {
      widget.profile.weightKg = w;
      widget.profile.bodyFat = f;
      widget.profile.muscleMass = m;
      widget.profile.gender = _selectedGender;
      widget.profile.isFatPercentage = _isFatPercentage;
      widget.profile.isMusclePercentage = _isMusclePercentage;
    });

    StorageService.saveUserProfile(widget.profile);

    final user = AuthService.currentUser;
    if (user != null) {
      final allExercises = ExerciseDatabase.getAllExercises();
      ApiService.syncUserData(
        user.id,
        widget.profile,
        ProgramService.activeProgramId,
        allExercises,
        widget.profile.unlockedBadges,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '✅ Vücut ölçüleri ve profil bilgileri kaydedildi!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF16A34A), // Canlı Yeşil
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (file == null) return;

      // Dosyayı oku ve PNG/JPEG kontrolü yap
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('⚠️ Geçersiz fotoğraf formatı! Lütfen PNG veya JPEG seçin.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }

      // Optimize et (200x200 kare avatar, kaliteli JPEG sıkıştırma)
      final resized = img.copyResizeCropSquare(decoded, size: 200);
      final compressedBytes = img.encodeJpg(resized, quality: 80);
      final base64String = base64Encode(compressedBytes);

      setState(() {
        widget.profile.avatarBase64 = base64String;
      });

      await StorageService.saveUserProfile(widget.profile);

      // VDS Sunucusuna anında senkronize et
      final user = AuthService.currentUser;
      if (user != null) {
        final allExercises = ExerciseDatabase.getAllExercises();
        await ApiService.syncUserData(
          user.id,
          widget.profile,
          ProgramService.activeProgramId,
          allExercises,
          widget.profile.unlockedBadges,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🖼️ Profil fotoğrafınız başarıyla güncellendi!'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Fotoğraf yüklenirken hata: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUser = AuthService.currentUser;
    final hasAvatar = widget.profile.avatarBase64 != null && widget.profile.avatarBase64!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sporcu Profili & RPG Seviyesi'),
        actions: [
          IconButton(
            tooltip: 'Güncellemeleri Denetle',
            icon: const Icon(Icons.system_update_alt_rounded, color: AppTheme.primaryNeon),
            onPressed: () {
              UpdateService.checkForUpdates(context, showNoUpdateDialog: true);
            },
          ),
          IconButton(
            tooltip: 'Çıkış Yap',
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await AuthService.logout();
              widget.onLogout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        child: Column(
          children: [
            // Profil Kartı
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.surface, AppTheme.surfaceLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                children: [
                  // Tıklanabilir Profil Fotoğrafı Alanı
                  GestureDetector(
                    onTap: _pickAndUploadAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [AppTheme.primaryNeon, AppTheme.primaryAccent]),
                            border: Border.all(color: AppTheme.primaryNeon, width: 2),
                          ),
                          child: ClipOval(
                            child: hasAvatar
                                ? Image.memory(
                                    base64Decode(widget.profile.avatarBase64!),
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                  )
                                : const Center(
                                    child: Text('⚔️', style: TextStyle(fontSize: 38)),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryNeon,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: AppTheme.background, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    activeUser?.username ?? widget.profile.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (activeUser?.email != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      activeUser!.email,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNeon.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Unvan: ${widget.profile.rankTitle}',
                      style: const TextStyle(
                        color: AppTheme.primaryNeon,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Seviye ve XP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SEVİYE ${widget.profile.level}',
                        style: const TextStyle(
                          color: AppTheme.purpleXP,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${widget.profile.currentXP} / ${widget.profile.targetXP} XP',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: widget.profile.xpProgress,
                      minHeight: 10,
                      backgroundColor: AppTheme.background,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.purpleXP),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 🌟 YENİ: Vücut Kompozisyonu ve Ölçüm Kartı (Kilo, Cinsiyet, Yağ %, Kas %)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.monitor_weight_outlined, color: AppTheme.primaryNeon, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'VÜCUT ÖLÇÜMLERİ & BİLGİLERİ',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryNeon,
                          foregroundColor: AppTheme.background,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _saveBodyMetrics,
                        child: const Text('KAYDET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Cinsiyet Seçimi
                  Row(
                    children: [
                      const Text('Cinsiyet:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Erkek ♂', style: TextStyle(fontSize: 12)),
                        selected: _selectedGender == 'Erkek',
                        selectedColor: AppTheme.primaryNeon.withOpacity(0.25),
                        backgroundColor: AppTheme.surfaceLight,
                        onSelected: (val) => setState(() => _selectedGender = 'Erkek'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Kadın ♀', style: TextStyle(fontSize: 12)),
                        selected: _selectedGender == 'Kadın',
                        selectedColor: AppTheme.primaryNeon.withOpacity(0.25),
                        backgroundColor: AppTheme.surfaceLight,
                        onSelected: (val) => setState(() => _selectedGender = 'Kadın'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Kilo Alanı
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Vücut Ağırlığı (KG)', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.surfaceBorder),
                              ),
                              child: TextField(
                                controller: _weightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(border: InputBorder.none, suffixText: 'kg'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Yağ ve Kas Alanları (Yüzde veya KG seçmeli)
                  Row(
                    children: [
                      // Yağ Oranı
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Yağ Oranı', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                GestureDetector(
                                  onTap: () => setState(() => _isFatPercentage = !_isFatPercentage),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _isFatPercentage ? '% (Yüzde)' : 'KG',
                                      style: const TextStyle(color: AppTheme.primaryAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.surfaceBorder),
                              ),
                              child: TextField(
                                controller: _fatController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  suffixText: _isFatPercentage ? '%' : 'kg',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Kas Kütlesi
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Kas Kütlesi', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                GestureDetector(
                                  onTap: () => setState(() => _isMusclePercentage = !_isMusclePercentage),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _isMusclePercentage ? '% (Yüzde)' : 'KG',
                                      style: const TextStyle(color: AppTheme.primaryAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.surfaceBorder),
                              ),
                              child: TextField(
                                controller: _muscleController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  suffixText: _isMusclePercentage ? '%' : 'kg',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 🌙 YENİ: Uyku Kalitesi & Toparlanma Analiz Grafiği
            _buildSleepQualitySection(),

            const SizedBox(height: 16),

            // RPG İstatistikleri / Toplam Başarılar
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Antrenman',
                    value: '${widget.profile.totalWorkoutsCompleted}',
                    subtitle: 'Tamamlandı',
                    icon: Icons.check_circle_outline,
                    color: AppTheme.primaryNeon,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Kaldırılan Tonaj',
                    value: (widget.profile.totalTonnageLiftedKg / 1000).toStringAsFixed(1),
                    subtitle: 'Toplam Ton',
                    icon: Icons.line_weight_rounded,
                    color: AppTheme.primaryAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Başarım Rozetleri (Badges)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BAŞARIM ROZETLERİ (ACHIEVEMENTS)',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  '${widget.profile.unlockedBadges.length} / ${allBadges.length}',
                  style: const TextStyle(
                    color: AppTheme.goldRank,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allBadges.length,
              itemBuilder: (context, index) {
                final badge = allBadges[index];
                final isUnlocked = widget.profile.unlockedBadges.contains(badge.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isUnlocked ? AppTheme.goldRank.withOpacity(0.5) : AppTheme.surfaceBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUnlocked ? AppTheme.goldRank.withOpacity(0.15) : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge.iconEmoji,
                          style: TextStyle(
                            fontSize: 22,
                            color: isUnlocked ? null : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              badge.title,
                              style: TextStyle(
                                color: isUnlocked ? AppTheme.textPrimary : AppTheme.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              badge.description,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUnlocked)
                        const Icon(Icons.check_circle, color: AppTheme.goldRank, size: 20)
                      else
                        const Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 20),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepQualitySection() {
    final history = SleepTrackingService.sleepHistory;
    final latest = history.isNotEmpty ? history.last : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('🌙', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(
                    'UYKU & DİNLENME PLANI',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.purpleXP.withOpacity(0.2),
                  foregroundColor: const Color(0xFFC084FC),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.purpleXP, width: 0.8),
                  ),
                ),
                icon: const Icon(Icons.alarm_add_rounded, size: 16),
                label: const Text('Saat Ayarla', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  SleepTrackingService.showManualSleepDialog(context, widget.profile, () {
                    setState(() {});
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (latest != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Son Gece: ${latest.durationHours} Saat',
                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        latest.qualityScore,
                        style: const TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    latest.advice,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Uygulama arka planda 4.5+ saat inaktif kaldığında uyku otomatik algılanacaktır.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // 7 Günlük Yatay Eksenli, Dikey Saat Göstergeli Profesyonel Uyku Tablosu
          Builder(
            builder: (context) {
              final now = DateTime.now();
              final dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
              
              // Son 7 günün tarihlerini çıkar (Bugün en sağda)
              final List<Map<String, dynamic>> last7DaysData = [];
              for (int i = 6; i >= 0; i--) {
                final d = now.subtract(Duration(days: i));
                final dKey = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                
                // Bu tarihe denk gelen uyku kaydını bul
                SleepLog? match;
                for (var log in history) {
                  final logKey = '${log.sleepEnd.year}-${log.sleepEnd.month.toString().padLeft(2, '0')}-${log.sleepEnd.day.toString().padLeft(2, '0')}';
                  if (logKey == dKey) {
                    match = log;
                    break;
                  }
                }

                last7DaysData.add({
                  'dayName': dayNames[d.weekday - 1],
                  'dateStr': '${d.day}/${d.month}',
                  'isToday': i == 0,
                  'hours': match?.durationHours ?? 0.0,
                });
              }

              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '7 GÜNLÜK UYKU ANALİZİ',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryNeon, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            const Text('7h+ İdeal', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                            const SizedBox(width: 10),
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            const Text('<6h Az', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Tablo Gövdesi: Sol Dikey Saat Skalası (12h, 8h, 4h, 0h) + Sağ 7 Gün Çubukları
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Dikey Eksen (Y-Axis): Saat Skalası
                        SizedBox(
                          height: 110,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text('12h', style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                              Text('8h', style: TextStyle(color: AppTheme.primaryNeon, fontSize: 9, fontWeight: FontWeight.bold)),
                              Text('4h', style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                              Text('0h', style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Dikey Ayırıcı Çizgi
                        Container(
                          width: 1,
                          height: 110,
                          color: AppTheme.surfaceBorder,
                        ),
                        const SizedBox(width: 8),

                        // 7 Gün Çubukları ve Alt Gün İsimleri
                        Expanded(
                          child: SizedBox(
                            height: 130,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: last7DaysData.map((data) {
                                final double h = (data['hours'] as double).clamp(0.0, 14.0);
                                final isToday = data['isToday'] as bool;
                                final hasData = h > 0;
                                final double barHeight = (h / 12.0).clamp(0.0, 1.0) * 85;

                                Color barColor = AppTheme.surfaceBorder;
                                if (h >= 7.5) {
                                  barColor = AppTheme.primaryNeon;
                                } else if (h >= 6.0) {
                                  barColor = const Color(0xFF38BDF8);
                                } else if (h > 0) {
                                  barColor = const Color(0xFFEF4444);
                                }

                                return Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Saat Değeri
                                      Text(
                                        hasData ? '${h.toStringAsFixed(1)}h' : '-',
                                        style: TextStyle(
                                          color: isToday ? AppTheme.primaryNeon : (hasData ? AppTheme.textPrimary : AppTheme.textMuted),
                                          fontSize: 9,
                                          fontWeight: isToday ? FontWeight.w900 : FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // Çubuk Barı
                                      Container(
                                        width: 14,
                                        height: hasData ? (barHeight < 8 ? 8 : barHeight) : 4,
                                        decoration: BoxDecoration(
                                          color: hasData ? barColor : AppTheme.surfaceBorder.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(4),
                                          boxShadow: hasData && isToday
                                              ? [
                                                  BoxShadow(
                                                    color: barColor.withOpacity(0.4),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, -1),
                                                  )
                                                ]
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // Alt Yatay Bar (Günler)
                                      Text(
                                        data['dayName'],
                                        style: TextStyle(
                                          color: isToday ? AppTheme.primaryNeon : AppTheme.textMuted,
                                          fontSize: 10,
                                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        data['dateStr'],
                                        style: TextStyle(
                                          color: isToday ? AppTheme.primaryNeon : AppTheme.textMuted.withOpacity(0.6),
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
