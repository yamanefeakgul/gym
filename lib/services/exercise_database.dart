import '../models/exercise.dart';

class ExerciseDatabase {
  static List<Exercise> getAllExercises() {
    return [
      // Görseldeki Program Hareketleri & Temel Kütüphane
      // GÖĞÜS (CHEST)
      Exercise(
        id: 'plate_loaded_chest_press',
        name: 'Plate Loaded Chest Press',
        muscleGroup: MuscleGroup.chest,
        equipment: 'Plaka Yüklemeli Makine',
        instructions: 'Göğüs hizasına kontrollü indirin, göğüs kaslarını sıkarak güçlü itin.',
      ),
      Exercise(
        id: 'smith_machine_incline_press',
        name: 'Smith Machine Low Incline Press',
        muscleGroup: MuscleGroup.chest,
        equipment: 'Smith Machine & Eğimli Sehpa',
        instructions: 'Üst göğsü hedefleyin. Kontrollü iniş ve patlayıcı itiş.',
      ),
      Exercise(
        id: 'chest_fly_machine',
        name: 'Chest Fly Machine (Pec Deck)',
        muscleGroup: MuscleGroup.chest,
        equipment: 'Kelebek / Fly Makinesi',
        instructions: 'Tepe noktada göğüs kaslarını 1 saniye tam sıkıştırın.',
      ),
      Exercise(
        id: 'bench_press',
        name: 'Barbell Bench Press',
        muscleGroup: MuscleGroup.chest,
        equipment: 'Barbell & Düz Sehpa',
        instructions: 'Göğüs hizasına kontrollü indirin ve itin.',
      ),
      Exercise(
        id: 'incline_db_press',
        name: 'Incline Dumbbell Press',
        muscleGroup: MuscleGroup.chest,
        equipment: 'Dumbbell & Eğimli Sehpa',
        instructions: 'Dirsekleri gövdeye 45 derece açıda tutarak yukarı itin.',
      ),

      // SIRT (BACK)
      Exercise(
        id: 'lat_pulldown',
        name: 'Lat Pulldown',
        muscleGroup: MuscleGroup.back,
        equipment: 'Kablo İstasyonu',
        instructions: 'Göğsün üstüne doğru geniş tutuşla çekin, kanatları sıkın.',
      ),
      Exercise(
        id: 'plate_loaded_wide_row',
        name: 'Plate Loaded Wide Grip Row',
        muscleGroup: MuscleGroup.back,
        equipment: 'Plaka Yüklemeli Row Makinesi',
        instructions: 'Geniş tutuşla dirsekleri geriye doğru çekerek üst sırtı aktif edin.',
      ),
      Exercise(
        id: 'seated_cable_row',
        name: 'Cable Row (Seated)',
        muscleGroup: MuscleGroup.back,
        equipment: 'Oturarak Kablo Row',
        instructions: 'Gövdeyi dik tutarak karnınıza doğru çekiş yapın.',
      ),
      Exercise(
        id: 'deadlift',
        name: 'Conventional Deadlift',
        muscleGroup: MuscleGroup.back,
        equipment: 'Barbell & Plakalar',
        instructions: 'Bel düz, bacak ve kalça gücüyle yerden kaldırın.',
      ),
      Exercise(
        id: 'barbell_row',
        name: 'Barbell Bent Over Row',
        muscleGroup: MuscleGroup.back,
        equipment: 'Barbell',
        instructions: 'Gövde eğik, sırt kaslarıyla çekiş yapın.',
      ),

      // OMUZ (SHOULDERS)
      Exercise(
        id: 'shoulder_press_machine',
        name: 'Shoulder Press Machine',
        muscleGroup: MuscleGroup.shoulders,
        equipment: 'Omuz Pres Makinesi',
        instructions: 'Omuz hizasından başın üzerine doğru itin.',
      ),
      Exercise(
        id: 'lateral_raise',
        name: 'Lateral Raise (Dumbbell / Cable)',
        muscleGroup: MuscleGroup.shoulders,
        equipment: 'Dumbbell / Kablo',
        instructions: 'Yan omuzları izole ederek kolları yana paralel açın.',
      ),
      Exercise(
        id: 'cable_rear_delt_fly',
        name: 'Cable Rear Delt Fly',
        muscleGroup: MuscleGroup.shoulders,
        equipment: 'Kablo İstasyonu',
        instructions: 'Arka omuzları hedefleyerek kolları geriye doğru açın.',
      ),
      Exercise(
        id: 'overhead_press',
        name: 'Overhead Press (OHP)',
        muscleGroup: MuscleGroup.shoulders,
        equipment: 'Barbell',
        instructions: 'Ayakta dik durarak barı baş üzerine kaldırın.',
      ),

      // KOL (ARMS)
      Exercise(
        id: 'incline_dumbbell_curl',
        name: 'Incline Dumbbell Curl',
        muscleGroup: MuscleGroup.arms,
        equipment: 'Dumbbell & Eğimli Sehpa',
        instructions: 'Biceps uzun başını maksimum gererek curl yapın.',
      ),
      Exercise(
        id: 'cable_curl',
        name: 'Cable Biceps Curl',
        muscleGroup: MuscleGroup.arms,
        equipment: 'Kablo İstasyonu & Düz Bar',
        instructions: 'Sabit gerilimle biceps tepe noktasına sıkıştırma.',
      ),
      Exercise(
        id: 'hammer_curl',
        name: 'Hammer Curl',
        muscleGroup: MuscleGroup.arms,
        equipment: 'Dumbbell',
        instructions: 'Avuç içleri birbirine bakar, brachialis ve ön kol hedeflenir.',
      ),
      Exercise(
        id: 'reverse_barbell_curl',
        name: 'Reverse Barbell Curl',
        muscleGroup: MuscleGroup.arms,
        equipment: 'EZ / Düz Barbell',
        instructions: 'Ters tutuşla ön kol ve brachioradialis odaklı curl.',
      ),
      Exercise(
        id: 'triceps_pushdown',
        name: 'Triceps Pushdown',
        muscleGroup: MuscleGroup.arms,
        equipment: 'Kablo & Halat / Düz Bar',
        instructions: 'Dirsekleri kilitlemeden aşağıya doğru itin.',
      ),
      Exercise(
        id: 'overhead_rope_extension',
        name: 'Overhead Rope Extension',
        muscleGroup: MuscleGroup.arms,
        equipment: 'Kablo & Halat',
        instructions: 'Başın arkasından öne doğru uzatarak triceps uzun başını esnetin.',
      ),

      // BACAK (LEGS)
      Exercise(
        id: 'leg_press',
        name: 'Leg Press (45°)',
        muscleGroup: MuscleGroup.legs,
        equipment: 'Leg Press Makinesi',
        instructions: 'Dizleri içeri kaçırmadan derin iniş ve güçlü itiş.',
      ),
      Exercise(
        id: 'smith_machine_squat',
        name: 'Smith Machine Squat',
        muscleGroup: MuscleGroup.legs,
        equipment: 'Smith Machine',
        instructions: 'Quadriceps odaklı kontrollü derin çöküş.',
      ),
      Exercise(
        id: 'leg_extension',
        name: 'Leg Extension',
        muscleGroup: MuscleGroup.legs,
        equipment: 'Bacak Ön Makinesi',
        instructions: 'Tepe noktada quadriceps kaslarını sıkıştırın.',
      ),
      Exercise(
        id: 'seated_leg_curl',
        name: 'Seated Leg Curl',
        muscleGroup: MuscleGroup.legs,
        equipment: 'Oturarak Bacak Arka Makinesi',
        instructions: 'Arka bacak (Hamstrings) kaslarını kontrollü bükün.',
      ),
      Exercise(
        id: 'romanian_deadlift',
        name: 'Romanian Deadlift (RDL)',
        muscleGroup: MuscleGroup.legs,
        equipment: 'Barbell / Dumbbell',
        instructions: 'Kalçayı geriye doğru iterek arka bacağı tam gerin.',
      ),
      Exercise(
        id: 'barbell_squat',
        name: 'Barbell Back Squat',
        muscleGroup: MuscleGroup.legs,
        equipment: 'Squat Rack & Barbell',
        instructions: 'Tam derinlikte kontrollü squat.',
      ),

      // KARIN & KARDİYO
      Exercise(
        id: 'hanging_leg_raise',
        name: 'Hanging Leg Raise',
        muscleGroup: MuscleGroup.core,
        equipment: 'Barfiks Demiri',
        instructions: 'Bacakları 90 derece kaldırarak alt karın sıkıştırma.',
      ),
      Exercise(
        id: 'plank',
        name: 'Weighted Plank',
        muscleGroup: MuscleGroup.core,
        equipment: 'Vücut Ağırlığı',
        instructions: 'Merkez bölgeyi nötr ve sıkı tutun.',
      ),
      Exercise(
        id: 'hiit_treadmill',
        name: 'HIIT Koşu Bandı',
        muscleGroup: MuscleGroup.cardio,
        equipment: 'Koşu Bandı',
        instructions: 'Yüksek tempolu intervaller.',
      ),
    ];
  }
}
