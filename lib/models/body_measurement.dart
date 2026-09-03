import 'dart:convert';

class BodyMeasurementEntry {
  final String date; // YYYY-MM-DD
  final double weightKg;
  final double bodyFat;
  final double muscleMass;
  final double chestCm;
  final double waistCm;
  final double armCm;
  final double thighCm;

  BodyMeasurementEntry({
    required this.date,
    required this.weightKg,
    this.bodyFat = 15.0,
    this.muscleMass = 35.0,
    this.chestCm = 100.0,
    this.waistCm = 80.0,
    this.armCm = 36.0,
    this.thighCm = 56.0,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'weightKg': weightKg,
        'bodyFat': bodyFat,
        'muscleMass': muscleMass,
        'chestCm': chestCm,
        'waistCm': waistCm,
        'armCm': armCm,
        'thighCm': thighCm,
      };

  factory BodyMeasurementEntry.fromJson(Map<String, dynamic> json) => BodyMeasurementEntry(
        date: json['date'] ?? '',
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 75.0,
        bodyFat: (json['bodyFat'] as num?)?.toDouble() ?? 15.0,
        muscleMass: (json['muscleMass'] as num?)?.toDouble() ?? 35.0,
        chestCm: (json['chestCm'] as num?)?.toDouble() ?? 100.0,
        waistCm: (json['waistCm'] as num?)?.toDouble() ?? 80.0,
        armCm: (json['armCm'] as num?)?.toDouble() ?? 36.0,
        thighCm: (json['thighCm'] as num?)?.toDouble() ?? 56.0,
      );
}
