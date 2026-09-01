const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// İndirmeler ve yüklemeler klasörü
const downloadsDir = path.join(__dirname, 'public', 'downloads');
const uploadsDir = path.join(__dirname, 'public', 'uploads');
if (!fs.existsSync(downloadsDir)) {
  fs.mkdirSync(downloadsDir, { recursive: true });
}
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

app.use('/downloads', express.static(downloadsDir));
app.use('/uploads', express.static(uploadsDir));

// JSON Veritabanı Dosyası (Kalıcı Saklama)
const DB_FILE = path.join(__dirname, 'gym_database.json');

function readData() {
  if (!fs.existsSync(DB_FILE)) {
    const initialData = {
      users: [],
      programs: [],
      userPrograms: {}, // Kullanıcının özel oluşturduğu programlar (userId -> [programlar])
      exercisesHistory: {} // Kullanıcının egzersiz geçmişi (userId -> {exerciseId -> [logs]})
    };
    fs.writeFileSync(DB_FILE, JSON.stringify(initialData, null, 2));
    return initialData;
  }
  try {
    const data = JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
    if (!data.userPrograms) data.userPrograms = {};
    if (!data.exercisesHistory) data.exercisesHistory = {};
    return data;
  } catch (e) {
    return { users: [], programs: [], userPrograms: {}, exercisesHistory: {} };
  }
}

function writeData(data) {
  fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2));
}

// 1. VERSİYON KONTROLÜ (OTA GÜNCELLEME - ANDROID & IOS)
app.get('/api/version.json', (req, res) => {
  res.json({
    latest_version: '1.0.5',
    download_url: `/downloads/gym.apk`,
    ios_download_url: `/downloads/gym.ipa`,
    changelog: 'v1.0.5 Güncelleme Notları:\n• ☁️ Özel programlar & Egzersiz ağırlık geçmişi VDS sunucuya kalıcı bağlandı (Güncellemede asla silinmez)!\n• 🖼️ Ana sayfa sol üst köşede dinamik sporcu profil fotoğrafı avatarı eklendi!\n• 🔥 Streak günü & takvim yeni güne geçiş renk kontrolü düzeltildi!\n• 📱 Streak & Motivasyon masaüstü widget hatası giderildi (iOS & Android)!'
  });
});

// 2. KAYIT OL
app.post('/api/auth/register', (req, res) => {
  const { username, email, password, goal } = req.body;
  const db = readData();

  if (db.users.some(u => u.email === email)) {
    return res.status(400).json({ error: 'Bu e-posta adresi zaten kayıtlı.' });
  }

  const newUser = {
    id: 'usr_' + Date.now(),
    username: username || 'Sporcu',
    email,
    password,
    goal: goal || 'Kas ve Güç Kazanımı',
    level: 1,
    currentXP: 0,
    targetXP: 500,
    streakDays: 0,
    totalWorkoutsCompleted: 0,
    totalTonnageLiftedKg: 0.0,
    unlockedBadges: [],
    activityCalendar: {},
    activeProgramId: null,
    weightKg: 75.0,
    gender: 'Erkek',
    bodyFat: 15.0,
    isFatPercentage: true,
    muscleMass: 35.0,
    isMusclePercentage: false,
    avatarBase64: ''
  };

  db.users.push(newUser);
  writeData(db);

  res.json({
    success: true,
    user: newUser,
    customPrograms: [],
    exercisesHistory: {}
  });
});

// 3. GİRİŞ YAP (Tüm Özel Programlar ve Ağırlık Geçmişi VDS'ten Döner)
app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;
  const db = readData();

  const user = db.users.find(u => u.email === email && u.password === password);
  if (!user) {
    return res.status(401).json({ error: 'E-posta veya şifre hatalı!' });
  }

  const userCustomPrograms = db.userPrograms[user.id] || [];
  const userExercisesHistory = db.exercisesHistory[user.id] || {};

  res.json({
    success: true,
    user: user,
    customPrograms: userCustomPrograms,
    exercisesHistory: userExercisesHistory
  });
});

// 4. KULLANICI PROFİLİ, ÖZEL PROGRAMLARI VE AĞIRLIK GEÇMİŞİNİ VDS SUNUCUYA TAM SENKRONİZE ET
app.post('/api/user/sync', (req, res) => {
  const { userId, profile, activeProgramId, customPrograms, exercisesHistory, badges, avatarBase64 } = req.body;
  const db = readData();

  const userIndex = db.users.findIndex(u => u.id === userId);
  if (userIndex !== -1) {
    db.users[userIndex] = {
      ...db.users[userIndex],
      ...profile,
      activeProgramId: activeProgramId !== undefined ? activeProgramId : db.users[userIndex].activeProgramId,
      unlockedBadges: badges || db.users[userIndex].unlockedBadges,
      avatarBase64: avatarBase64 !== undefined ? avatarBase64 : db.users[userIndex].avatarBase64
    };

    if (customPrograms) {
      if (!db.userPrograms) db.userPrograms = {};
      db.userPrograms[userId] = customPrograms;
    }

    if (exercisesHistory) {
      if (!db.exercisesHistory) db.exercisesHistory = {};
      db.exercisesHistory[userId] = exercisesHistory;
    }

    writeData(db);
    return res.json({
      success: true,
      user: db.users[userIndex],
      customPrograms: db.userPrograms[userId] || [],
      exercisesHistory: db.exercisesHistory[userId] || {}
    });
  }
  res.status(404).json({ error: 'Kullanıcı bulunamadı.' });
});

// 5. TÜM PROGRAMLAR (VDS TOPLULUK CLOUD)
app.get('/api/programs', (req, res) => {
  const db = readData();
  res.json(db.programs || []);
});

app.post('/api/programs', (req, res) => {
  const program = req.body;
  const db = readData();

  const idx = db.programs.findIndex(p => p.id === program.id);
  if (idx !== -1) {
    db.programs[idx] = program;
  } else {
    db.programs.push(program);
  }
  writeData(db);
  res.json({ success: true, program });
});

// 6. LİDERLİK TABLOSU (DETAYLI PROFİLLER)
app.get('/api/leaderboard', (req, res) => {
  const db = readData();
  const sorted = (db.users || [])
    .map(u => ({
      userId: u.id,
      username: u.username,
      goal: u.goal || 'Kas ve Güç Kazanımı',
      level: u.level || 1,
      currentXP: u.currentXP || 0,
      targetXP: u.targetXP || 500,
      totalTonnage: (u.totalTonnageLiftedKg || 0) / 1000,
      totalTonnageKg: u.totalTonnageLiftedKg || 0.0,
      streakDays: u.streakDays || 0,
      totalWorkoutsCompleted: u.totalWorkoutsCompleted || 0,
      weightKg: u.weightKg || 75.0,
      gender: u.gender || 'Erkek',
      bodyFat: u.bodyFat || 15.0,
      isFatPercentage: u.isFatPercentage !== undefined ? u.isFatPercentage : true,
      muscleMass: u.muscleMass || 35.0,
      isMusclePercentage: u.isMusclePercentage !== undefined ? u.isMusclePercentage : false,
      unlockedBadgesCount: (u.unlockedBadges || []).length,
      avatarBase64: u.avatarBase64 || '',
      rankTitle: u.level >= 15 ? 'Olympia Şampiyonu' : (u.level >= 10 ? 'Titan' : (u.level >= 6 ? 'Ağırlık Canavarı' : (u.level >= 3 ? 'Demir Savaşçısı' : 'Gym Çaylağı')))
    }))
    .sort((a, b) => b.totalTonnage - a.totalTonnage);

  const leaderboard = sorted.map((item, index) => ({
    rank: index + 1,
    ...item
  }));

  res.json(leaderboard);
});

// 7. TEKİL SPORCU PROFİLİ DETAYI
app.get('/api/user/:username', (req, res) => {
  const db = readData();
  const user = db.users.find(u => u.username.toLowerCase() === req.params.username.toLowerCase());
  if (!user) {
    return res.status(404).json({ error: 'Kullanıcı bulunamadı.' });
  }

  const { password, ...safeUser } = user;
  res.json(safeUser);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 GYM VDS API & Veritabanı Sunucusu Port ${PORT} üzerinde hazır!`);
});
