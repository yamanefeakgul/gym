import 'dart:convert';

class CardioWorkoutLog {
  final String id;
  final String dateStr;
  final String mode; // 'Koşu' veya 'Yürüyüş'
  final int seconds;
  final double distanceKm;
  final double avgSpeedKmh;
  final List<Map<String, double>> route;

  CardioWorkoutLog({
    required this.id,
    required this.dateStr,
    required this.mode,
    required this.seconds,
    required this.distanceKm,
    required this.avgSpeedKmh,
    required this.route,
  });

  String get formattedTime {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateStr': dateStr,
        'mode': mode,
        'seconds': seconds,
        'distanceKm': distanceKm,
        'avgSpeedKmh': avgSpeedKmh,
        'route': route,
      };

  factory CardioWorkoutLog.fromJson(Map<String, dynamic> json) => CardioWorkoutLog(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        dateStr: json['dateStr'] ?? '',
        mode: json['mode'] ?? 'Koşu',
        seconds: json['seconds'] ?? 0,
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
        avgSpeedKmh: (json['avgSpeedKmh'] as num?)?.toDouble() ?? 0.0,
        route: (json['route'] as List<dynamic>?)
                ?.map((e) => {
                      'lat': (e['lat'] as num).toDouble(),
                      'lng': (e['lng'] as num).toDouble(),
                    })
                .toList() ??
            [],
      );
}
