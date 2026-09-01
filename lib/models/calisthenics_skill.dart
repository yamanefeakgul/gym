enum SkillState {
  locked,
  available,
  unlocked,
  mastered,
}

class CalisthenicsSkill {
  final String id;
  final String title;
  final String branch; // 1: İtiş (Push), 2: Çekiş (Pull), 3: Statik & Core, 4: Bacak & Denge
  final int step; // 1, 2, 3, 4, 5, 6 (Daldaki basamak)
  final String description;
  final String iconEmoji;
  final int requiredXP;
  final List<String> prerequisites; // Önkoşul skill id'leri
  SkillState state;

  CalisthenicsSkill({
    required this.id,
    required this.title,
    required this.branch,
    required this.step,
    required this.description,
    required this.iconEmoji,
    required this.requiredXP,
    this.prerequisites = const [],
    this.state = SkillState.locked,
  });
}

class CalisthenicsTreeData {
  static List<CalisthenicsSkill> getInitialSkills() {
    return [
      // ==========================================
      // DAL 1: İTİŞ (PUSH) BRANŞI - 6 BASAMAK
      // ==========================================
      CalisthenicsSkill(
        id: 'push_1',
        title: 'Klasik Şınav (Push-up)',
        branch: 'İtiş (Push)',
        step: 1,
        description: 'Temel kuvvet inşası. 3 set 20 nizami tekrar vücut ağırlığı şınav.',
        iconEmoji: '🛡️',
        requiredXP: 100,
        state: SkillState.mastered,
      ),
      CalisthenicsSkill(
        id: 'push_2',
        title: 'Elmas Şınav (Diamond Push-up)',
        branch: 'İtiş (Push)',
        step: 2,
        description: 'Triceps ve iç göğüs aktivasyonu. 3 set 12 tekrar elmas şınav.',
        iconEmoji: '💎',
        requiredXP: 250,
        prerequisites: ['push_1'],
        state: SkillState.unlocked,
      ),
      CalisthenicsSkill(
        id: 'push_3',
        title: 'Paralel Bar Dips',
        branch: 'İtiş (Push)',
        step: 3,
        description: 'Alt göğüs ve triceps gücü. 3 set 15 tekrar tam derinlik paralel bar dips.',
        iconEmoji: '⚡',
        requiredXP: 500,
        prerequisites: ['push_2'],
        state: SkillState.available,
      ),
      CalisthenicsSkill(
        id: 'push_4',
        title: 'Pike & Duvar Handstand Push-up',
        branch: 'İtiş (Push)',
        step: 4,
        description: 'Omuz dikey itiş gücü. Duvarda 3 set 8 tekrar amut şınavı.',
        iconEmoji: '🏹',
        requiredXP: 900,
        prerequisites: ['push_3'],
        state: SkillState.locked,
      ),
      CalisthenicsSkill(
        id: 'push_5',
        title: 'Serbest Amut Şınavı (Freestanding HSPU)',
        branch: 'İtiş (Push)',
        step: 5,
        description: 'Duvarsız dengede vücut ağırlığı omuz presi (5 tekrar).',
        iconEmoji: '🤸',
        requiredXP: 1600,
        prerequisites: ['push_4'],
        state: SkillState.locked,
      ),
      CalisthenicsSkill(
        id: 'push_6',
        title: 'Full Planche (Planche Hold)',
        branch: 'İtiş (Push)',
        step: 6,
        description: 'Zirve itiş gücü. Yere paralel düz gövde 10 saniye havada duruş.',
        iconEmoji: '👑',
        requiredXP: 3000,
        prerequisites: ['push_5'],
        state: SkillState.locked,
      ),

      // ==========================================
      // DAL 2: ÇEKİŞ (PULL) BRANŞI - 6 BASAMAK
      // ==========================================
      CalisthenicsSkill(
        id: 'pull_1',
        title: 'Avustralya Barfiksi (Inverted Row)',
        branch: 'Çekiş (Pull)',
        step: 1,
        description: 'Sırt ve biceps başlangıç çekişi. 3 set 15 tekrar yatay çekiş.',
        iconEmoji: '🪜',
        requiredXP: 100,
        state: SkillState.mastered,
      ),
      CalisthenicsSkill(
        id: 'pull_2',
        title: 'Klasik Barfiks (Pull-up)',
        branch: 'Çekiş (Pull)',
        step: 2,
        description: 'Kanat ve kol inşası. 3 set 10 tekrar çene üstü tam barfiks.',
        iconEmoji: '🦅',
        requiredXP: 250,
        prerequisites: ['pull_1'],
        state: SkillState.unlocked,
      ),
      CalisthenicsSkill(
        id: 'pull_3',
        title: 'L-Sit Pull-up',
        branch: 'Çekiş (Pull)',
        step: 3,
        description: 'Bacaklar 90 derece L açısında çekiş kuvveti (3x8 tekrar).',
        iconEmoji: '📐',
        requiredXP: 600,
        prerequisites: ['pull_2'],
        state: SkillState.available,
      ),
      CalisthenicsSkill(
        id: 'pull_4',
        title: 'Bar Muscle-up',
        branch: 'Çekiş (Pull)',
        step: 4,
        description: 'Patlayıcı çekişten barın üzerine geçiş (5 tekrar).',
        iconEmoji: '🚀',
        requiredXP: 1100,
        prerequisites: ['pull_3'],
        state: SkillState.locked,
      ),
      CalisthenicsSkill(
        id: 'pull_5',
        title: 'Front Lever (10s Sabit Duruş)',
        branch: 'Çekiş (Pull)',
        step: 5,
        description: 'Barda yere paralel 10 saniye sabit asılı duruş.',
        iconEmoji: '🎯',
        requiredXP: 1800,
        prerequisites: ['pull_4'],
        state: SkillState.locked,
      ),
      CalisthenicsSkill(
        id: 'pull_6',
        title: 'Tek Kol Barfiks (One Arm Pull-up)',
        branch: 'Çekiş (Pull)',
        step: 6,
        description: 'Zirve çekiş gücü. Tek kol ile nizami barfiks çekişi.',
        iconEmoji: '🦾',
        requiredXP: 3500,
        prerequisites: ['pull_5'],
        state: SkillState.locked,
      ),

      // ==========================================
      // DAL 3: STATİK & CORE BRANŞI - 5 BASAMAK
      // ==========================================
      CalisthenicsSkill(
        id: 'core_1',
        title: 'Hollow Body & Plank Ustası',
        branch: 'Core & Statik',
        step: 1,
        description: '3 dakika aralıksız karın ve merkez bölge stabilizasyonu.',
        iconEmoji: '🧱',
        requiredXP: 100,
        state: SkillState.mastered,
      ),
      CalisthenicsSkill(
        id: 'core_2',
        title: 'Asılarak Bacak Kaldırma (Toes To Bar)',
        branch: 'Core & Statik',
        step: 2,
        description: 'Barfiks barında ayak parmaklarını bara değdirme (3x12 tekrar).',
        iconEmoji: '🎪',
        requiredXP: 300,
        prerequisites: ['core_1'],
        state: SkillState.unlocked,
      ),
      CalisthenicsSkill(
        id: 'core_3',
        title: 'Yerde L-Sit (20s Hold)',
        branch: 'Core & Statik',
        step: 3,
        description: 'Düz zeminde yalnızca eller üstünde bacaklar havada 20 saniye duruş.',
        iconEmoji: '🧘',
        requiredXP: 700,
        prerequisites: ['core_2'],
        state: SkillState.available,
      ),
      CalisthenicsSkill(
        id: 'core_4',
        title: 'Dragon Flag (Bruce Lee Flag)',
        branch: 'Core & Statik',
        step: 4,
        description: 'Düz sehpada omuzlar temas ederek vücudu sopa gibi dik tutma (3x8).',
        iconEmoji: '🐉',
        requiredXP: 1300,
        prerequisites: ['core_3'],
        state: SkillState.locked,
      ),
      CalisthenicsSkill(
        id: 'core_5',
        title: 'Human Flag (İnsan Bayrağı)',
        branch: 'Core & Statik',
        step: 5,
        description: 'Dikey direkte yere paralel yatay duruş.',
        iconEmoji: '🚩',
        requiredXP: 2500,
        prerequisites: ['core_4'],
        state: SkillState.locked,
      ),

      // ==========================================
      // DAL 4: BACAK & DENGE BRANŞI - 5 BASAMAK
      // ==========================================
      CalisthenicsSkill(
        id: 'leg_1',
        title: 'Vücut Ağırlığı Squat & Lunge',
        branch: 'Bacak & Denge',
        step: 1,
        description: '50 nizami squat ve 30 lunge kondisyon serisi.',
        iconEmoji: '🦵',
        requiredXP: 100,
        state: SkillState.mastered,
      ),
      CalisthenicsSkill(
        id: 'leg_2',
        title: 'Derin Cossack Squat',
        branch: 'Bacak & Denge',
        step: 2,
        description: 'Yanlara esnek ve derin tek bacak çömelme serisi (3x10).',
        iconEmoji: '🥋',
        requiredXP: 250,
        prerequisites: ['leg_1'],
        state: SkillState.unlocked,
      ),
      CalisthenicsSkill(
        id: 'leg_3',
        title: 'Tabanca Squat (Pistol Squat)',
        branch: 'Bacak & Denge',
        step: 3,
        description: 'Tek bacak tam derinlik tabanca squat (her bacak 8 tekrar).',
        iconEmoji: '🔫',
        requiredXP: 650,
        prerequisites: ['leg_2'],
        state: SkillState.available,
      ),
      CalisthenicsSkill(
        id: 'leg_4',
        title: 'Nordic Hamstring Curl',
        branch: 'Bacak & Denge',
        step: 4,
        description: 'Dizler üzerinde vücut ağırlığıyla arka bacak negatif iniş ve çekişi.',
        iconEmoji: '🪢',
        requiredXP: 1200,
        prerequisites: ['leg_3'],
        state: SkillState.locked,
      ),
      CalisthenicsSkill(
        id: 'leg_5',
        title: 'Dragon Pistol Squat',
        branch: 'Bacak & Denge',
        step: 5,
        description: 'Bacak arkadan çapraz uzatılarak yapılan elit denge squatı.',
        iconEmoji: '🐲',
        requiredXP: 2200,
        prerequisites: ['leg_4'],
        state: SkillState.locked,
      ),
    ];
  }
}
