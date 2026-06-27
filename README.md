# Rentalin (Aplikasi Manajemen Rental Mobil)

**Rentalin** adalah aplikasi mobile internal untuk mengelola operasional harian usaha rental mobil. Aplikasi ini digunakan oleh pemilik usaha (admin) untuk mengatur jadwal booking, armada kendaraan, supir, dan memantau status pembayaran. Supir (operator) mendapatkan akses terbatas untuk melihat jadwal tugas mereka.

> **Catatan:** Aplikasi ini **bukan** untuk pelanggan/publik. Distribusi dilakukan via file APK/IPA langsung (tanpa Play Store/App Store).

---

## 👥 Target User & Role

| Role | Pengguna | Akses |
|------|----------|-------|
| **Admin** | Pemilik usaha | Full access: CRUD booking, armada, supir, laporan keuangan, manajemen akun operator |
| **Operator** | Supir | Read-only: lihat semua jadwal di kalender, lihat armada. Home hanya menampilkan jadwal yang di-assign kepadanya |

---

## 🛠 Tech Stack

- **Framework:** Flutter (Dart) - Cross-platform (Android & iOS)
- **Arsitektur:** MVVM (Provider / Riverpod)
- **Backend & Database:** Firebase (Cloud Firestore)
- **Authentication:** Firebase Auth (Email & Password)
- **Storage:** Firebase Cloud Storage
- **Distribusi:** Direct Install (APK/IPA)

---

## 🎨 Design System (Neobank Style)

Antarmuka aplikasi mengadopsi gaya **Neobank** yang bersih, modern, dan memiliki kontras tinggi dengan panduan desain sebagai berikut:

### Skema Warna
- **Background:** Off-white / Abu-abu sangat terang (`#F9FAFB`)
- **Surface:** Putih Murni (`#FFFFFF`) dengan shadow halus
- **Primary / Aksen:** Hijau Lime/Neon (`#A3E635`)
- **Secondary:** Hitam Pekat / Abu gelap (`#1F2937`)

### Tipografi
- **Font Family:** Inter / Poppins
- **Karakteristik:** Bersih, membulat, dan mudah dibaca. Hierarki teks tebal (bold) pada saldo/angka metrik, dan reguler pada deskripsi.

### Komponen UI & Bentuk
- Menggunakan sudut membulat (*rounded corners*, radius 16px - 24px) pada tombol, kartu, dan input.
- Berfokus pada penggunaan *whitespace* (ruang kosong) yang lega untuk menjaga tampilan tetap teratur dan elegan.
- *Bottom Navigation Bar* untuk navigasi antar halaman utama.

---

## 📌 Fitur Utama

### 👑 Admin
1. **Dashboard (Home):** Pantauan metrik utama (Mobil Keluar, Booking Baru, Menunggu Pelunasan) dan pencarian global.
2. **Manajemen Booking:** Tambah booking multi-rute, atur status pembayaran (Belum Bayar, DP, Lunas), dan deteksi bentrok jadwal.
3. **Jadwal (Schedule):** Kalender bulanan yang dilengkapi marker status pembayaran.
4. **Armada:** CRUD data Kendaraan dan Supir.
5. **Laporan Keuangan:** Ekspor laporan pemasukan dan piutang ke PDF/Excel.

### 🚗 Operator (Supir)
1. **Dashboard (Home):** Menampilkan tugas jadwal hari ini dan jadwal mendatang yang di-assign kepada supir tersebut.
2. **Jadwal (Schedule):** Melihat jadwal operasional (Read-only).
3. **Profil:** Manajemen profil dan preferensi aplikasi (seperti *Dark Mode*).

---

## 🚀 Panduan Memulai (Development Setup)

1. Pastikan Anda telah menginstal [Flutter SDK](https://flutter.dev/docs/get-started/install).
2. Clone repository ini.
3. Jalankan perintah berikut untuk mengunduh dependencies:
   ```bash
   flutter pub get
   ```
4. Tambahkan file konfigurasi Firebase:
   - Letakkan `google-services.json` di `android/app/`
   - Letakkan `GoogleService-Info.plist` di `ios/Runner/`
5. Jalankan aplikasi pada emulator atau perangkat fisik:
   ```bash
   flutter run
   ```

---
*Dokumentasi spesifikasi lengkap (PRD) dan rencana implementasi dapat dilihat di dalam folder `docs/specs/rental-management/`.*