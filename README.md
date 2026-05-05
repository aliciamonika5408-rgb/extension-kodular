# 📚 StudyPlan - Catatan Tugas Sekolah

> **Ingetin Tugas Yuk!** - Aplikasi planner untuk mengelola tugas sekolah dengan mudah dan teratur.

![StudyPlan Logo](assets/logo.png)

## ✨ Fitur Utama

- ➕ **Tambah Tugas** - Buat tugas baru dengan mudah
- ⏰ **Deadline** - Atur deadline agar tidak terlambat
- ✅ **Status Selesai** - Tandai tugas selesai dan pantau progres
- 📅 **Kalender** - Lihat tugas berdasarkan tanggal
- 🔍 **Pencarian** - Cari tugas dengan cepat
- 🏷️ **Prioritas** - Tandai tugas sebagai Urgent, Sedang, atau Rendah
- 📊 **Ringkasan** - Pantau statistik tugas di dashboard
- 💾 **Data Tersimpan** - Data tersimpan otomatis di localStorage

## 🎨 Warna Tema

| Warna | Kode | Kegunaan |
|-------|------|----------|
| 💜 Purple | `#6C5CE7` | Primary |
| 🔴 Red | `#FF6B6B` | Urgent |
| 🟡 Yellow | `#FECA57` | Medium |
| 🟢 Green | `#00B894` | Low/Success |
| ⚪ Light | `#F2F3F7` | Background |

## 📱 Cara Pakai di Kodular

### 1. Upload File
Upload semua file ke hosting (GitHub Pages, Netlify, dll):
- `index.html`
- `style.css`
- `app.js`
- `assets/logo.png`

### 2. Setup di Kodular
1. Tambahkan komponen **WebViewer** ke layar
2. Set properti `HomeUrl` ke URL hosting kamu
3. Centang **UsesLocation** = false
4. Set **Width** & **Height** = Fill Parent

### 3. Komunikasi dengan Blocks (Opsional)
```
// Tambah tugas dari Kodular:
WebViewer.RunJavaScript("SP.addTask('Judul','Matematika','2024-12-31','high')")

// Ambil data tugas:
WebViewer.RunJavaScript("SP.getTasks()")

// Ambil statistik:
WebViewer.RunJavaScript("SP.getStats()")

// Hapus tugas selesai:
WebViewer.RunJavaScript("SP.clearCompleted()")
```

## 🗂️ Struktur File

```
extension kodular/
├── index.html          # Halaman utama
├── style.css           # Styling
├── app.js              # Logika aplikasi
├── assets/
│   └── logo.png        # Logo StudyPlan
└── README.md           # Dokumentasi
```

## 📄 Lisensi

Dibuat untuk keperluan pendidikan. © 2026 StudyPlan
