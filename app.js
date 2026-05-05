/* ===== StudyPlan - App Logic ===== */

// --- State ---
let tasks = [];
let currentScreen = 'home';
let screenHistory = [];
let currentFilter = 'all';
let selectedPriority = '';
let editingTaskId = null;
let currentTaskId = null;
let calendarDate = new Date();
let selectedCalDate = null;
let dialogCallback = null;

// --- Subject Config ---
const SUBJECTS = {
  'Matematika':       { emoji:'📐', color:'#4A90E2', bg:'#E3F2FD', cls:'subj-matematika' },
  'Bahasa Indonesia': { emoji:'📖', color:'#FF6B9D', bg:'#FFF0F5', cls:'subj-bahasa-indonesia' },
  'IPA':              { emoji:'🔬', color:'#2ECC71', bg:'#E8F5E9', cls:'subj-ipa' },
  'Bahasa Inggris':   { emoji:'🌐', color:'#9B59B6', bg:'#F3E5F5', cls:'subj-bahasa-inggris' },
  'IPS':              { emoji:'🌍', color:'#E67E22', bg:'#FFF3E0', cls:'subj-ips' },
  'Fisika':           { emoji:'⚡', color:'#F1C40F', bg:'#FFFDE7', cls:'subj-fisika' },
  'Kimia':            { emoji:'⚗️', color:'#1ABC9C', bg:'#E0F2F1', cls:'subj-kimia' },
  'Biologi':          { emoji:'🧬', color:'#E74C3C', bg:'#FCE4EC', cls:'subj-biologi' },
  'Lainnya':          { emoji:'📝', color:'#78909C', bg:'#ECEFF1', cls:'subj-lainnya' }
};

const MONTHS = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
const DAYS = ['Min','Sen','Sel','Rab','Kam','Jum','Sab'];

// --- Init ---
document.addEventListener('DOMContentLoaded', () => {
  loadTasks();
  setTimeout(() => {
    const splash = document.getElementById('splash-screen');
    splash.classList.add('fade-out');
    setTimeout(() => {
      splash.classList.add('hidden');
      document.getElementById('app').classList.remove('hidden');
      renderHome();
      updateBadge();
    }, 500);
  }, 2500);
});

// --- Storage ---
function loadTasks() {
  const data = localStorage.getItem('studyplan_tasks');
  if (data) {
    tasks = JSON.parse(data);
  } else {
    tasks = generateDemoTasks();
    saveTasks();
  }
}

function saveTasks() {
  localStorage.setItem('studyplan_tasks', JSON.stringify(tasks));
  bridgeToKodular();
}

function generateDemoTasks() {
  const now = new Date();
  const d = (days, hours = 23, mins = 59) => {
    const dt = new Date(now);
    dt.setDate(dt.getDate() + days);
    dt.setHours(hours, mins, 0, 0);
    return dt.toISOString();
  };
  const c = (days) => {
    const dt = new Date(now);
    dt.setDate(dt.getDate() - days);
    return dt.toISOString();
  };
  return [
    { id:1, title:'Kerjakan soal halaman 45-50', subject:'Matematika', description:'Kerjakan soal nomor 1-20 pada halaman 45-50 di buku paket.', deadline:d(2), priority:'high', reminder:'1_day', status:'pending', createdAt:c(2) },
    { id:2, title:'Membuat rangkuman bab 3', subject:'Bahasa Indonesia', description:'Rangkum materi bab 3 tentang teks eksposisi.', deadline:d(4), priority:'medium', reminder:'1_day', status:'pending', createdAt:c(3) },
    { id:3, title:'Proyek sistem pencernaan', subject:'IPA', description:'Buat poster tentang sistem pencernaan manusia.', deadline:d(7), priority:'low', reminder:'1_day', status:'pending', createdAt:c(5) },
    { id:4, title:'Membuat dialog percakapan', subject:'Bahasa Inggris', description:'Write a dialogue about daily routines with your partner.', deadline:d(5), priority:'medium', reminder:'1_day', status:'pending', createdAt:c(1) },
    { id:5, title:'Latihan soal persamaan linear', subject:'Matematika', description:'Kerjakan 15 soal persamaan linear di LKS halaman 20.', deadline:d(-1), priority:'high', reminder:'3_hours', status:'completed', createdAt:c(4) },
    { id:6, title:'Essay tentang proklamasi', subject:'IPS', description:'Tulis essay 500 kata tentang peristiwa proklamasi.', deadline:d(1), priority:'high', reminder:'1_day', status:'pending', createdAt:c(1) },
    { id:7, title:'Laporan praktikum kimia', subject:'Kimia', description:'Buat laporan praktikum tentang reaksi asam basa.', deadline:d(3), priority:'medium', reminder:'1_day', status:'pending', createdAt:c(2) },
    { id:8, title:'Hafalan vocabulary unit 5', subject:'Bahasa Inggris', description:'Hafalkan 30 vocabulary baru dari unit 5.', deadline:d(-2), priority:'low', reminder:'none', status:'completed', createdAt:c(6) },
  ];
}

// --- Navigation ---
function navigateTo(screen) {
  if (screen === currentScreen) return;
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  const el = document.getElementById('screen-' + screen);
  if (el) el.classList.add('active');

  // Update nav
  document.querySelectorAll('.nav-item').forEach(n => n.classList.toggle('active', n.dataset.screen === screen));

  // Header
  const backBtn = document.getElementById('btn-back');
  const menuBtn = document.getElementById('btn-menu');
  const titleEl = document.getElementById('header-title');
  const actionBtn = document.getElementById('btn-header-action');
  const notifBtn = document.getElementById('btn-notification');
  const fab = document.getElementById('fab');
  const bottomNav = document.getElementById('bottom-nav');

  const isMain = ['home','calendar','completed','profile'].includes(screen);
  backBtn.classList.toggle('hidden', isMain);
  menuBtn.classList.toggle('hidden', !isMain || screen !== 'home');
  actionBtn.classList.add('hidden');
  notifBtn.classList.toggle('hidden', screen === 'add-task' || screen === 'task-detail');
  fab.classList.toggle('hidden', screen === 'add-task' || screen === 'task-detail');
  bottomNav.classList.toggle('hidden', screen === 'add-task' || screen === 'task-detail');

  const titles = { home:'StudyPlan', calendar:'Kalender', completed:'Selesai', profile:'Profil', 'add-task':'Tambah Tugas', 'task-detail':'Detail Tugas' };
  titleEl.textContent = titles[screen] || 'StudyPlan';

  if (screen === 'add-task') {
    actionBtn.classList.remove('hidden');
    document.getElementById('header-action-icon').textContent = 'check';
  }
  if (screen === 'task-detail') {
    actionBtn.classList.remove('hidden');
    document.getElementById('header-action-icon').textContent = 'edit';
  }

  if (!isMain) screenHistory.push(currentScreen);
  currentScreen = screen;

  // Render
  if (screen === 'home') renderHome();
  else if (screen === 'calendar') renderCalendar();
  else if (screen === 'completed') renderCompleted();
  else if (screen === 'profile') renderProfile();
}

function goBack() {
  const prev = screenHistory.pop() || 'home';
  editingTaskId = null;
  navigateTo(prev);
}

function handleHeaderAction() {
  if (currentScreen === 'add-task') {
    document.getElementById('task-form').requestSubmit();
  } else if (currentScreen === 'task-detail' && currentTaskId) {
    editTask(currentTaskId);
  }
}

// --- Render Home ---
function renderHome() {
  const pending = tasks.filter(t => t.status === 'pending');
  const completed = tasks.filter(t => t.status === 'completed');

  document.getElementById('total-count').textContent = tasks.length;
  document.getElementById('pending-count').textContent = pending.length;
  document.getElementById('done-count').textContent = completed.length;

  const search = (document.getElementById('search-input')?.value || '').toLowerCase();
  let filtered = pending;
  if (currentFilter !== 'all') filtered = filtered.filter(t => t.priority === currentFilter);
  if (search) filtered = filtered.filter(t => t.title.toLowerCase().includes(search) || t.subject.toLowerCase().includes(search));

  filtered.sort((a, b) => new Date(a.deadline) - new Date(b.deadline));

  const container = document.getElementById('task-list');
  if (filtered.length === 0) {
    container.innerHTML = '<div class="empty-state"><div class="empty-icon">📝</div><h3>Tidak ada tugas</h3><p>Tekan + untuk menambah tugas baru</p></div>';
  } else {
    container.innerHTML = filtered.map(t => taskCardHTML(t)).join('');
  }
  updateBadge();
}

function taskCardHTML(t) {
  const sub = SUBJECTS[t.subject] || SUBJECTS['Lainnya'];
  const pClass = t.priority === 'high' ? 'priority-high' : t.priority === 'medium' ? 'priority-medium' : 'priority-low';
  const pLabel = t.priority === 'high' ? 'Urgent' : t.priority === 'medium' ? 'Sedang' : 'Rendah';
  const dl = formatDateShort(t.deadline);
  const isLate = new Date(t.deadline) < new Date() && t.status === 'pending';
  const completedClass = t.status === 'completed' ? ' completed-card' : '';

  return `<div class="task-card${completedClass}" data-subject="${t.subject}" onclick="showTaskDetail(${t.id})">
    <div class="task-card-header">
      <div class="subject-icon" style="background:${sub.bg};color:${sub.color}">${sub.emoji}</div>
      <div class="task-info">
        <div class="task-subject">${t.subject}</div>
        <div class="task-title">${escHTML(t.title)}</div>
      </div>
    </div>
    <div class="task-card-footer">
      <div class="task-date" ${isLate ? 'style="color:#FF6B6B"' : ''}>
        <span class="material-icons-round">schedule</span> ${dl}
      </div>
      <span class="priority-badge ${pClass}">${pLabel}</span>
    </div>
  </div>`;
}

// --- Filter ---
function setFilter(f, el) {
  currentFilter = f;
  document.querySelectorAll('.filter-chip').forEach(c => c.classList.remove('active'));
  el.classList.add('active');
  renderHome();
}

// --- Add/Edit Task ---
function showAddTask(id) {
  editingTaskId = id || null;
  const form = document.getElementById('task-form');
  form.reset();
  selectedPriority = '';
  document.querySelectorAll('.priority-option').forEach(o => o.className = 'priority-option');

  if (id) {
    const t = tasks.find(x => x.id === id);
    if (t) {
      document.getElementById('f-title').value = t.title;
      document.getElementById('f-subject').value = t.subject;
      document.getElementById('f-desc').value = t.description || '';
      document.getElementById('f-deadline').value = t.deadline.slice(0, 16);
      document.getElementById('f-reminder').value = t.reminder || '1_day';
      selectPriority(t.priority, document.querySelector(`.priority-option[data-priority="${t.priority}"]`));
    }
  } else {
    // Default deadline: tomorrow 23:59
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(23, 59, 0, 0);
    document.getElementById('f-deadline').value = toLocalISO(tomorrow);
  }

  navigateTo('add-task');
  document.getElementById('header-title').textContent = id ? 'Edit Tugas' : 'Tambah Tugas';
}

function selectPriority(p, el) {
  selectedPriority = p;
  document.querySelectorAll('.priority-option').forEach(o => o.className = 'priority-option');
  if (el) el.classList.add('selected-' + p);
}

function saveTask(e) {
  e.preventDefault();
  const title = document.getElementById('f-title').value.trim();
  const subject = document.getElementById('f-subject').value;
  const desc = document.getElementById('f-desc').value.trim();
  const deadline = document.getElementById('f-deadline').value;
  const reminder = document.getElementById('f-reminder').value;

  if (!title || !subject || !deadline) { showToast('Lengkapi semua field yang wajib!'); return; }
  if (!selectedPriority) { showToast('Pilih prioritas tugas!'); return; }

  if (editingTaskId) {
    const t = tasks.find(x => x.id === editingTaskId);
    if (t) {
      Object.assign(t, { title, subject, description:desc, deadline:new Date(deadline).toISOString(), priority:selectedPriority, reminder });
      showToast('Tugas berhasil diperbarui! ✏️');
    }
  } else {
    tasks.push({
      id: Date.now(),
      title, subject, description:desc,
      deadline: new Date(deadline).toISOString(),
      priority: selectedPriority,
      reminder, status:'pending',
      createdAt: new Date().toISOString()
    });
    showToast('Tugas berhasil ditambahkan! 🎉');
  }
  saveTasks();
  editingTaskId = null;
  goBack();
}

function editTask(id) {
  showAddTask(id);
}

// --- Task Detail ---
function showTaskDetail(id) {
  const t = tasks.find(x => x.id === id);
  if (!t) return;
  currentTaskId = id;
  const sub = SUBJECTS[t.subject] || SUBJECTS['Lainnya'];
  const pClass = t.priority === 'high' ? 'priority-high' : t.priority === 'medium' ? 'priority-medium' : 'priority-low';
  const pLabel = t.priority === 'high' ? 'Urgent' : t.priority === 'medium' ? 'Sedang' : 'Rendah';
  const isPending = t.status === 'pending';

  document.getElementById('detail-content').innerHTML = `
    <div class="detail-header-card">
      <div class="detail-icon" style="background:${sub.bg};color:${sub.color}">${sub.emoji}</div>
      <div>
        <div class="detail-title">${escHTML(t.title)}</div>
        <span class="priority-badge ${pClass}">${pLabel}</span>
      </div>
    </div>
    <div class="detail-section">
      <div class="detail-row"><span class="detail-row-label">Mata Pelajaran</span><span class="detail-row-value">${t.subject}</span></div>
      <div class="detail-row"><span class="detail-row-label">Deadline</span><span class="detail-row-value">${formatDateFull(t.deadline)}</span></div>
      <div class="detail-row"><span class="detail-row-label">Dibuat Pada</span><span class="detail-row-value">${formatDateFull(t.createdAt)}</span></div>
    </div>
    ${t.description ? `<div class="detail-section"><div class="detail-row-label" style="margin-bottom:8px">Deskripsi</div><div class="detail-desc">${escHTML(t.description)}</div></div>` : ''}
    <div class="detail-section">
      <div class="detail-row-label" style="margin-bottom:8px">Status</div>
      <div class="status-options">
        <div class="status-option ${isPending ? 'active' : ''}" onclick="setStatus(${t.id},'pending')">
          <div class="status-radio"></div> Belum Selesai
        </div>
        <div class="status-option ${!isPending ? 'active' : ''}" onclick="setStatus(${t.id},'completed')">
          <div class="status-radio"></div> Selesai
        </div>
      </div>
    </div>
    <div class="detail-actions">
      <button class="btn-action btn-delete" onclick="confirmDelete(${t.id})">
        <span class="material-icons-round" style="font-size:18px">delete</span> Hapus
      </button>
      <button class="btn-action btn-complete" onclick="toggleComplete(${t.id})">
        <span class="material-icons-round" style="font-size:18px">${isPending ? 'check_circle' : 'undo'}</span>
        ${isPending ? 'Tandai Selesai' : 'Tandai Belum'}
      </button>
    </div>`;

  navigateTo('task-detail');
}

function setStatus(id, status) {
  const t = tasks.find(x => x.id === id);
  if (t) { t.status = status; saveTasks(); showTaskDetail(id); }
}

function toggleComplete(id) {
  const t = tasks.find(x => x.id === id);
  if (t) {
    t.status = t.status === 'pending' ? 'completed' : 'pending';
    saveTasks();
    showToast(t.status === 'completed' ? 'Tugas ditandai selesai! ✅' : 'Tugas dibuka kembali');
    showTaskDetail(id);
  }
}

function confirmDelete(id) {
  showDialog('Hapus Tugas', 'Apakah kamu yakin ingin menghapus tugas ini? Tindakan ini tidak bisa dibatalkan.', 'Hapus', () => {
    tasks = tasks.filter(t => t.id !== id);
    saveTasks();
    showToast('Tugas berhasil dihapus 🗑️');
    goBack();
  });
}

// --- Calendar ---
function renderCalendar() {
  const year = calendarDate.getFullYear();
  const month = calendarDate.getMonth();
  document.getElementById('calendar-title').textContent = MONTHS[month] + ' ' + year;

  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const daysInPrev = new Date(year, month, 0).getDate();
  const today = new Date();

  let html = DAYS.map(d => `<div class="cal-day-header">${d}</div>`).join('');

  // Previous month days
  for (let i = firstDay - 1; i >= 0; i--) {
    html += `<div class="cal-day other-month">${daysInPrev - i}</div>`;
  }

  // Current month
  for (let d = 1; d <= daysInMonth; d++) {
    const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
    const isToday = today.getFullYear() === year && today.getMonth() === month && today.getDate() === d;
    const hasTask = tasks.some(t => t.deadline.slice(0, 10) === dateStr && t.status === 'pending');
    const isSelected = selectedCalDate === dateStr;
    const classes = ['cal-day'];
    if (isToday) classes.push('today');
    if (hasTask) classes.push('has-task');
    if (isSelected) classes.push('selected');
    html += `<div class="${classes.join(' ')}" onclick="selectCalDate('${dateStr}')">${d}</div>`;
  }

  // Next month days
  const totalCells = firstDay + daysInMonth;
  const remaining = (7 - totalCells % 7) % 7;
  for (let i = 1; i <= remaining; i++) {
    html += `<div class="cal-day other-month">${i}</div>`;
  }

  document.getElementById('calendar-grid').innerHTML = html;
  renderCalTasks();
}

function selectCalDate(dateStr) {
  selectedCalDate = selectedCalDate === dateStr ? null : dateStr;
  renderCalendar();
}

function renderCalTasks() {
  const container = document.getElementById('cal-task-list');
  const titleEl = document.getElementById('cal-tasks-title');
  let filtered;

  if (selectedCalDate) {
    filtered = tasks.filter(t => t.deadline.slice(0, 10) === selectedCalDate);
    titleEl.textContent = 'Tugas ' + formatDateShort(selectedCalDate + 'T00:00:00');
  } else {
    const todayStr = new Date().toISOString().slice(0, 10);
    filtered = tasks.filter(t => t.deadline.slice(0, 10) === todayStr);
    titleEl.textContent = 'Tugas Hari Ini';
  }

  if (filtered.length === 0) {
    container.innerHTML = '<div class="empty-state"><div class="empty-icon">📅</div><h3>Tidak ada tugas</h3><p>Tidak ada tugas untuk tanggal ini</p></div>';
  } else {
    container.innerHTML = filtered.map(t => taskCardHTML(t)).join('');
  }
}

function changeMonth(dir) {
  calendarDate.setMonth(calendarDate.getMonth() + dir);
  selectedCalDate = null;
  renderCalendar();
}

// --- Completed ---
function renderCompleted() {
  const completed = tasks.filter(t => t.status === 'completed');
  const container = document.getElementById('completed-list');
  if (completed.length === 0) {
    container.innerHTML = '<div class="empty-state"><div class="empty-icon">🎯</div><h3>Belum ada tugas selesai</h3><p>Selesaikan tugasmu untuk melihatnya di sini</p></div>';
  } else {
    container.innerHTML = completed.map(t => taskCardHTML(t)).join('');
  }
}

// --- Profile ---
function renderProfile() {
  const total = tasks.length;
  const done = tasks.filter(t => t.status === 'completed').length;
  const pending = tasks.filter(t => t.status === 'pending').length;
  const urgent = tasks.filter(t => t.priority === 'high' && t.status === 'pending').length;
  document.getElementById('stat-total').textContent = total;
  document.getElementById('stat-done').textContent = done;
  document.getElementById('stat-pending').textContent = pending;
  document.getElementById('stat-urgent').textContent = urgent;
}

// --- Badge ---
function updateBadge() {
  const urgent = tasks.filter(t => t.priority === 'high' && t.status === 'pending').length;
  const badge = document.getElementById('notification-badge');
  if (urgent > 0) {
    badge.textContent = urgent;
    badge.classList.remove('hidden');
  } else {
    badge.classList.add('hidden');
  }
}

// --- Toast ---
function showToast(msg) {
  const toast = document.getElementById('toast');
  toast.textContent = msg;
  toast.classList.remove('hidden', 'fade-out');
  clearTimeout(toast._timer);
  toast._timer = setTimeout(() => {
    toast.classList.add('fade-out');
    setTimeout(() => toast.classList.add('hidden'), 300);
  }, 2500);
}

// --- Dialog ---
function showDialog(title, message, confirmText, callback) {
  document.getElementById('dialog-title').textContent = title;
  document.getElementById('dialog-message').textContent = message;
  document.getElementById('dialog-confirm').textContent = confirmText;
  dialogCallback = callback;
  document.getElementById('dialog-overlay').classList.remove('hidden');
}

function closeDialog() {
  document.getElementById('dialog-overlay').classList.add('hidden');
  dialogCallback = null;
}

function confirmDialog() {
  if (dialogCallback) dialogCallback();
  closeDialog();
}

// --- Helpers ---
function formatDateShort(isoStr) {
  const d = new Date(isoStr);
  return d.getDate() + ' ' + MONTHS[d.getMonth()].slice(0, 3) + ' ' + d.getFullYear();
}

function formatDateFull(isoStr) {
  const d = new Date(isoStr);
  const pad = n => String(n).padStart(2, '0');
  return d.getDate() + ' ' + MONTHS[d.getMonth()] + ' ' + d.getFullYear() + ', ' + pad(d.getHours()) + ':' + pad(d.getMinutes());
}

function toLocalISO(d) {
  const pad = n => String(n).padStart(2, '0');
  return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate()) + 'T' + pad(d.getHours()) + ':' + pad(d.getMinutes());
}

function escHTML(s) {
  const div = document.createElement('div');
  div.textContent = s;
  return div.innerHTML;
}

// --- Kodular WebViewer Bridge ---
function bridgeToKodular() {
  try {
    if (window.AppInventor) {
      window.AppInventor.setWebViewString(JSON.stringify({
        action: 'data_update',
        totalTasks: tasks.length,
        pendingTasks: tasks.filter(t => t.status === 'pending').length,
        completedTasks: tasks.filter(t => t.status === 'completed').length,
        urgentTasks: tasks.filter(t => t.priority === 'high' && t.status === 'pending').length
      }));
    }
  } catch (e) { /* ignore */ }
}

// Expose functions for Kodular RunJavaScript
window.SP = {
  addTask: (title, subject, deadline, priority) => {
    tasks.push({ id:Date.now(), title, subject, description:'', deadline:new Date(deadline).toISOString(), priority:priority||'medium', reminder:'1_day', status:'pending', createdAt:new Date().toISOString() });
    saveTasks(); renderHome();
  },
  getTasks: () => JSON.stringify(tasks),
  getStats: () => JSON.stringify({ total:tasks.length, pending:tasks.filter(t=>t.status==='pending').length, completed:tasks.filter(t=>t.status==='completed').length }),
  clearCompleted: () => { tasks = tasks.filter(t => t.status === 'pending'); saveTasks(); renderHome(); showToast('Tugas selesai dihapus'); }
};
