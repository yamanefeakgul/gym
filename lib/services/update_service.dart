import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class UpdateService {
  static const String serverBaseUrl = 'http://166.1.94.116:3000';
  static const String currentVersion = '1.0.8';
  static const MethodChannel _updaterChannel = MethodChannel('com.gympulse.gymapp/updater');

  // 🌟 Uygulama her açıldığında Bilinmeyen Kaynaklardan Yükleme & Bildirim İzinlerini Kontrol Et
  static Future<void> checkRequiredPermissions(BuildContext context) async {
    try {
      // 1. Bildirim İzni İste (Android 13+)
      await _updaterChannel.invokeMethod('requestNotificationPermission');

      // 2. Bilinmeyen Kaynaklardan Uygulama Yükleme İzni Kontrolü
      final bool canInstall = await _updaterChannel.invokeMethod('checkInstallPermission') ?? false;

      if (!canInstall && context.mounted) {
        _showInstallPermissionDialog(context);
      }
    } catch (_) {}
  }

  static void _showInstallPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.secondaryOrange, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.security_update_good_rounded, color: AppTheme.secondaryOrange, size: 26),
            SizedBox(width: 10),
            Text('Otomatik Güncelleme İzni', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uygulamanın yeni sürümlerini sorunsuz otomatik indirebilmesi ve kurabilmesi için "Bilinmeyen uygulamaları yükle" iznine ihtiyaç vardır.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            SizedBox(height: 10),
            Text(
              'Lütfen açılan ayarlar sayfasından "Bu kaynaktan izin ver" seçeneğini aktif ediniz.',
              style: TextStyle(color: AppTheme.secondaryOrange, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Daha Sonra', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _updaterChannel.invokeMethod('requestInstallPermission');
            },
            child: const Text('AYARLARDA AÇ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static Future<void> checkForUpdates(BuildContext context, {bool showNoUpdateDialog = false}) async {
    try {
      final response = await http.get(
        Uri.parse('$serverBaseUrl/api/version.json'),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['latest_version'] ?? currentVersion;
        final downloadUrl = data['download_url'] ?? '';
        final changeLog = data['changelog'] ?? 'Hata düzeltmeleri ve performans iyileştirmeleri.';

        if (latestVersion != currentVersion) {
          String finalUrl = downloadUrl;
          if (Platform.isIOS && data['ios_download_url'] != null) {
            finalUrl = data['ios_download_url'];
          }

          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, finalUrl, changeLog);
          }
          return;
        }
      }
    } catch (_) {
      // VDS çevrimdışıysa
    }

    if (showNoUpdateDialog && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Uygulamanız en son sürümde güncel! (v$currentVersion)',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF16A34A), // Canlı Yeşil
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  static void _showUpdateDialog(
    BuildContext context,
    String newVersion,
    String downloadUrl,
    String changeLog,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.primaryNeon, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryNeon.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.system_update_alt_rounded, color: AppTheme.primaryNeon, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Yeni Sürüm Hazır!',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yeni Versiyon: v$newVersion',
              style: const TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Yenilikler:\n$changeLog',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Daha Sonra', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNeon,
              foregroundColor: AppTheme.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              
              String fullUrl = downloadUrl;
              if (!fullUrl.startsWith('http')) {
                fullUrl = '$serverBaseUrl$downloadUrl';
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '🚀 Güncelleme indiriliyor ve otomatik kurulacak...',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 4),
                ),
              );

              try {
                // Yerel DownloadManager + Otomatik Paket Yükleyiciyi Tetikle
                await _updaterChannel.invokeMethod('downloadAndInstall', {'url': fullUrl});
              } catch (_) {
                // Fallback: Tarayıcı aç
                launchUrl(Uri.parse(fullUrl), mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('ŞİMDİ GÜNCELLE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
