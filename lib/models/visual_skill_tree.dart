import 'package:flutter/material.dart';

enum SkillNodeState {
  locked,      // Gri / Kilitli
  unlocked,    // Beyaz (2s Hold / 1 Rep)
  inProgress,  // Pembe (6s Hold / 3 Reps)
  mastered,    // Yeşil (12s+ Hold / 6+ Reps)
}

class VisualSkillNode {
  final String id;
  final String name;
  final String branch;
  final Offset position;
  final List<String> childrenIds;
  SkillNodeState state;
  final String description;

  VisualSkillNode({
    required this.id,
    required this.name,
    required this.branch,
    required this.position,
    this.childrenIds = const [],
    this.state = SkillNodeState.locked,
    required this.description,
  });
}

class CalisthenicsVisualTreeData {
  static List<VisualSkillNode> getNodes() {
    // 🌟 Yeni hesap açıldığında veya sıfırdan başlandığında sadece ROOT (ilk) hareketler açık (unlocked), diğer tüm basamaklar tamamen KİLİTLİ (locked) başlar!
    return [
      // ==========================================
      // ROOT / CORE MERKEZ
      // ==========================================
      VisualSkillNode(
        id: 'core_root',
        name: 'Hollow Body',
        branch: 'CORE',
        position: const Offset(500, 600),
        childrenIds: ['core_plank', 'h_push_root', 'v_push_root', 'h_pull_root', 'v_pull_root', 'legs_root'],
        state: SkillNodeState.unlocked, // Sadece kök hareket açık
        description: 'Temel merkez bölge gerilimi (15s+ Hold).',
      ),
      VisualSkillNode(
        id: 'core_plank',
        name: 'Plank Hold',
        branch: 'CORE',
        position: const Offset(500, 520),
        childrenIds: ['core_l_sit'],
        state: SkillNodeState.locked,
        description: 'Düz merkez stabilizasyonu.',
      ),
      VisualSkillNode(
        id: 'core_l_sit',
        name: 'Floor L-Sit',
        branch: 'CORE',
        position: const Offset(500, 440),
        childrenIds: ['core_dragon_flag'],
        state: SkillNodeState.locked,
        description: 'Yerde bacaklar 90 derece L duruşu.',
      ),
      VisualSkillNode(
        id: 'core_dragon_flag',
        name: 'Dragon Flag',
        branch: 'CORE',
        position: const Offset(500, 360),
        childrenIds: ['core_human_flag'],
        state: SkillNodeState.locked,
        description: 'Bruce Lee vücut bayrağı.',
      ),
      VisualSkillNode(
        id: 'core_human_flag',
        name: 'Human Flag',
        branch: 'CORE',
        position: const Offset(500, 280),
        state: SkillNodeState.locked,
        description: 'Dikey direkte tam insan bayrağı.',
      ),

      // ==========================================
      // HORIZONTAL PUSH (YATAY İTİŞ)
      // ==========================================
      VisualSkillNode(
        id: 'h_push_root',
        name: 'Knee Push-up',
        branch: 'HORIZONTAL PUSH',
        position: const Offset(420, 620),
        childrenIds: ['h_push_reg'],
        state: SkillNodeState.unlocked, // Kök başlangıç
        description: 'Dizler üzerinde temel şınav.',
      ),
      VisualSkillNode(
        id: 'h_push_reg',
        name: 'Regular Push-up',
        branch: 'HORIZONTAL PUSH',
        position: const Offset(340, 650),
        childrenIds: ['h_push_diamond', 'h_push_wide'],
        state: SkillNodeState.locked,
        description: '3x20 nizami şınav.',
      ),
      VisualSkillNode(
        id: 'h_push_diamond',
        name: 'Diamond Push-up',
        branch: 'HORIZONTAL PUSH',
        position: const Offset(260, 620),
        childrenIds: ['h_push_pseudo'],
        state: SkillNodeState.locked,
        description: 'Elmas şınav.',
      ),
      VisualSkillNode(
        id: 'h_push_wide',
        name: 'Archer Push-up',
        branch: 'HORIZONTAL PUSH',
        position: const Offset(280, 710),
        childrenIds: ['h_push_one_arm'],
        state: SkillNodeState.locked,
        description: 'Okçu şınavı.',
      ),
      VisualSkillNode(
        id: 'h_push_pseudo',
        name: 'Pseudo Planche Push-up',
        branch: 'HORIZONTAL PUSH',
        position: const Offset(180, 590),
        childrenIds: ['h_push_tuck_planche'],
        state: SkillNodeState.locked,
        description: 'Öne eğik planche şınavı.',
      ),
      VisualSkillNode(
        id: 'h_push_one_arm',
        name: 'One Arm Push-up',
        branch: 'HORIZONTAL PUSH',
        position: const Offset(190, 720),
        state: SkillNodeState.locked,
        description: 'Tek kol şınav.',
      ),
      VisualSkillNode(
        id: 'h_push_tuck_planche',
        name: 'Tuck Planche',
        branch: 'HORIZONTAL PUSH',
        position: const Offset(110, 560),
        childrenIds: ['h_push_straddle_planche'],
        state: SkillNodeState.locked,
        description: 'Toplu dizler havada planche duruşu.',
      ),
      VisualSkillNode(
        id: 'h_push_straddle_planche',
        name: 'Straddle Planche',
        branch: 'HORIZONTAL PUSH',
        position: const Offset(60, 500),
        childrenIds: ['h_push_full_planche'],
        state: SkillNodeState.locked,
        description: 'Bacaklar açık planche.',
      ),
      VisualSkillNode(
        id: 'h_push_full_planche',
        name: 'Full Planche',
        branch: 'HORIZONTAL PUSH',
        position: const Offset(30, 430),
        state: SkillNodeState.locked,
        description: 'Zirve: Düz tam Planche (10s+ Hold).',
      ),

      // ==========================================
      // VERTICAL PUSH (DİKEY İTİŞ)
      // ==========================================
      VisualSkillNode(
        id: 'v_push_root',
        name: 'Bench Dips',
        branch: 'VERTICAL PUSH',
        position: const Offset(430, 530),
        childrenIds: ['v_push_dips'],
        state: SkillNodeState.unlocked, // Kök başlangıç
        description: 'Sehpa dips.',
      ),
      VisualSkillNode(
        id: 'v_push_dips',
        name: 'Parallel Bar Dips',
        branch: 'VERTICAL PUSH',
        position: const Offset(360, 450),
        childrenIds: ['v_push_pike', 'v_push_straight_bar'],
        state: SkillNodeState.locked,
        description: 'Paralel bar tam dips.',
      ),
      VisualSkillNode(
        id: 'v_push_pike',
        name: 'Pike Push-up',
        branch: 'VERTICAL PUSH',
        position: const Offset(300, 370),
        childrenIds: ['v_push_wall_hs'],
        state: SkillNodeState.locked,
        description: 'Pike omuz şınavı.',
      ),
      VisualSkillNode(
        id: 'v_push_straight_bar',
        name: 'Straight Bar Dips',
        branch: 'VERTICAL PUSH',
        position: const Offset(370, 360),
        childrenIds: ['v_push_korean_dips'],
        state: SkillNodeState.locked,
        description: 'Düz tek barda dips.',
      ),
      VisualSkillNode(
        id: 'v_push_wall_hs',
        name: 'Wall Handstand Push-up',
        branch: 'VERTICAL PUSH',
        position: const Offset(230, 290),
        childrenIds: ['v_push_free_hs'],
        state: SkillNodeState.locked,
        description: 'Duvarda amut şınavı.',
      ),
      VisualSkillNode(
        id: 'v_push_korean_dips',
        name: 'Korean Dips',
        branch: 'VERTICAL PUSH',
        position: const Offset(340, 270),
        state: SkillNodeState.locked,
        description: 'Bar arkadan dips.',
      ),
      VisualSkillNode(
        id: 'v_push_free_hs',
        name: 'Freestanding HSPU',
        branch: 'VERTICAL PUSH',
        position: const Offset(170, 200),
        childrenIds: ['v_push_90deg_pushup'],
        state: SkillNodeState.locked,
        description: 'Duvarsız amutta şınav.',
      ),
      VisualSkillNode(
        id: 'v_push_90deg_pushup',
        name: '90° Push-up (Hollowback)',
        branch: 'VERTICAL PUSH',
        position: const Offset(110, 130),
        state: SkillNodeState.locked,
        description: 'Amuttan plancheye inip tekrar amuda kalkış.',
      ),

      // ==========================================
      // VERTICAL PULL (DİKEY ÇEKİŞ)
      // ==========================================
      VisualSkillNode(
        id: 'v_pull_root',
        name: 'Dead Hang (60s)',
        branch: 'VERTICAL PULL',
        position: const Offset(580, 620),
        childrenIds: ['v_pull_pullup'],
        state: SkillNodeState.unlocked, // Kök başlangıç
        description: 'Barda 60 saniye asılı kalma ve tutuş gücü.',
      ),
      VisualSkillNode(
        id: 'v_pull_pullup',
        name: 'Regular Pull-up',
        branch: 'VERTICAL PULL',
        position: const Offset(660, 660),
        childrenIds: ['v_pull_l_sit', 'v_pull_chest_to_bar'],
        state: SkillNodeState.locked,
        description: '3x10 nizami barfiks.',
      ),
      VisualSkillNode(
        id: 'v_pull_l_sit',
        name: 'L-Sit Pull-up',
        branch: 'VERTICAL PULL',
        position: const Offset(740, 640),
        childrenIds: ['v_pull_high_pullup'],
        state: SkillNodeState.locked,
        description: 'L bacak açısıyla barfiks.',
      ),
      VisualSkillNode(
        id: 'v_pull_chest_to_bar',
        name: 'Chest To Bar Pull-up',
        branch: 'VERTICAL PULL',
        position: const Offset(730, 730),
        childrenIds: ['v_pull_archer'],
        state: SkillNodeState.locked,
        description: 'Göğsü bara değdiren patlayıcı çekiş.',
      ),
      VisualSkillNode(
        id: 'v_pull_high_pullup',
        name: 'High Pull-up (Karna Doğru)',
        branch: 'VERTICAL PULL',
        position: const Offset(820, 620),
        childrenIds: ['v_pull_muscle_up'],
        state: SkillNodeState.locked,
        description: 'Karna kadar yüksek çekiş.',
      ),
      VisualSkillNode(
        id: 'v_pull_archer',
        name: 'Archer Pull-up',
        branch: 'VERTICAL PULL',
        position: const Offset(810, 740),
        childrenIds: ['v_pull_one_arm'],
        state: SkillNodeState.locked,
        description: 'Okçu barfiksi.',
      ),
      VisualSkillNode(
        id: 'v_pull_muscle_up',
        name: 'Bar Muscle-up',
        branch: 'VERTICAL PULL',
        position: const Offset(890, 570),
        childrenIds: ['v_pull_strict_muscle_up'],
        state: SkillNodeState.locked,
        description: 'Çekip barın üzerine patlayıcı geçiş.',
      ),
      VisualSkillNode(
        id: 'v_pull_strict_muscle_up',
        name: 'Strict Slow Muscle-up',
        branch: 'VERTICAL PULL',
        position: const Offset(940, 500),
        childrenIds: ['v_pull_one_arm'],
        state: SkillNodeState.locked,
        description: 'Savurmasız, yavaş ve nizami muscle-up.',
      ),
      VisualSkillNode(
        id: 'v_pull_one_arm',
        name: 'One Arm Pull-up (OAP)',
        branch: 'VERTICAL PULL',
        position: const Offset(960, 630),
        state: SkillNodeState.locked,
        description: 'Zirve: Tek kol ile nizami barfiks.',
      ),

      // ==========================================
      // HORIZONTAL PULL (YATAY ÇEKİŞ / LEVER)
      // ==========================================
      VisualSkillNode(
        id: 'h_pull_root',
        name: 'Inverted Row',
        branch: 'HORIZONTAL PULL',
        position: const Offset(570, 520),
        childrenIds: ['h_pull_tuck_fl'],
        state: SkillNodeState.unlocked, // Kök başlangıç
        description: 'Yatay avustralya barfiksi.',
      ),
      VisualSkillNode(
        id: 'h_pull_tuck_fl',
        name: 'Tuck Front Lever',
        branch: 'HORIZONTAL PULL',
        position: const Offset(640, 440),
        childrenIds: ['h_pull_adv_tuck', 'h_pull_skin_the_cat'],
        state: SkillNodeState.locked,
        description: 'Dizler karında front lever.',
      ),
      VisualSkillNode(
        id: 'h_pull_skin_the_cat',
        name: 'Skin The Cat & Back Lever',
        branch: 'HORIZONTAL PULL',
        position: const Offset(690, 360),
        childrenIds: ['h_pull_full_bl'],
        state: SkillNodeState.locked,
        description: 'Omuz esnekliği ve ters lever.',
      ),
      VisualSkillNode(
        id: 'h_pull_adv_tuck',
        name: 'Adv. Tuck Front Lever',
        branch: 'HORIZONTAL PULL',
        position: const Offset(610, 340),
        childrenIds: ['h_pull_straddle_fl'],
        state: SkillNodeState.locked,
        description: 'Sırt düz, bacaklar 90 derece lever.',
      ),
      VisualSkillNode(
        id: 'h_pull_full_bl',
        name: 'Full Back Lever',
        branch: 'HORIZONTAL PULL',
        position: const Offset(730, 260),
        state: SkillNodeState.locked,
        description: 'Tam düz sırt duruşu.',
      ),
      VisualSkillNode(
        id: 'h_pull_straddle_fl',
        name: 'Straddle Front Lever',
        branch: 'HORIZONTAL PULL',
        position: const Offset(610, 230),
        childrenIds: ['h_pull_full_fl'],
        state: SkillNodeState.locked,
        description: 'Bacaklar açık Front Lever.',
      ),
      VisualSkillNode(
        id: 'h_pull_full_fl',
        name: 'Full Front Lever',
        branch: 'HORIZONTAL PULL',
        position: const Offset(620, 120),
        childrenIds: ['h_pull_fl_touch'],
        state: SkillNodeState.locked,
        description: 'Yere paralel düz tahta gibi duruş (10s+).',
      ),
      VisualSkillNode(
        id: 'h_pull_fl_touch',
        name: 'Front Lever Row / Touch',
        branch: 'HORIZONTAL PULL',
        position: const Offset(720, 60),
        state: SkillNodeState.locked,
        description: 'Front lever pozisyonunda çekiş yapmak.',
      ),

      // ==========================================
      // LEGS (ALT GÖVDE / BACAK)
      // ==========================================
      VisualSkillNode(
        id: 'legs_root',
        name: 'Bodyweight Squat',
        branch: 'LEGS',
        position: const Offset(500, 720),
        childrenIds: ['legs_cossack'],
        state: SkillNodeState.unlocked, // Kök başlangıç
        description: '50 nizami derin squat.',
      ),
      VisualSkillNode(
        id: 'legs_cossack',
        name: 'Cossack Squat',
        branch: 'LEGS',
        position: const Offset(500, 800),
        childrenIds: ['legs_pistol', 'legs_nordic'],
        state: SkillNodeState.locked,
        description: 'Yanlara esnek derin tek bacak çöküş.',
      ),
      VisualSkillNode(
        id: 'legs_pistol',
        name: 'Pistol Squat',
        branch: 'LEGS',
        position: const Offset(430, 880),
        childrenIds: ['legs_dragon_pistol'],
        state: SkillNodeState.locked,
        description: 'Tek bacak tam derinlik tabanca squat.',
      ),
      VisualSkillNode(
        id: 'legs_nordic',
        name: 'Nordic Hamstring Curl',
        branch: 'LEGS',
        position: const Offset(570, 880),
        state: SkillNodeState.locked,
        description: 'Dizler üzerinde vücut ağırlığı arka bacak çekişi.',
      ),
      VisualSkillNode(
        id: 'legs_dragon_pistol',
        name: 'Dragon Pistol Squat',
        branch: 'LEGS',
        position: const Offset(360, 940),
        state: SkillNodeState.locked,
        description: 'Arkadan bacak çapraz uzatmalı denge squatı.',
      ),
    ];
  }
}
