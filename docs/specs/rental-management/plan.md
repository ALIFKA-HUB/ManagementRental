# Implementation Plan — Rentalin

> **PRD:** [PRD.md](file:///c:/Users/ASUS/Documents/ALIFKA/PROJECT/ManagementRental/docs/specs/rental-management/PRD.md)
> **Tanggal:** 2026-06-26
> **Total Phase:** 10
> **Strategi:** Setiap phase independently shippable, ordered by dependency, ≤400 LOC per phase.

---

## Phase 1 — Project Setup + Design System

**Branch:** `phase-1/setup-design-system`

**Tujuan:** Inisialisasi project Flutter, konfigurasi Firebase, dan bangun design system (theme, tokens, reusable widgets) yang jadi fondasi seluruh app.

### Tasks

- [ ] **1.1** Init Flutter project (`flutter create rentalin`)
- [ ] **1.2** Setup Firebase project di Firebase Console (Android + iOS)
  - Tambahkan app Android (package name: `com.rentalin.app`)
  - Tambahkan app iOS (bundle ID: `com.rentalin.app`)
  - Download `google-services.json` (Android) + `GoogleService-Info.plist` (iOS)
- [ ] **1.3** Install base dependencies di `pubspec.yaml`:
  - `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
  - `provider` atau `riverpod` (state management)
  - `shared_preferences` (dark mode persistence)
  - `intl` (format tanggal/mata uang Indonesia)
  - `google_fonts` (Inter / Poppins)
- [ ] **1.4** Buat file `lib/core/theme/app_colors.dart`
  - Light mode palette: background `#F9FAFB`, surface `#FFFFFF`, primary `#A3E635`, secondary `#1F2937`, textPrimary `#111827`, textSecondary `#6B7280`, error `#EF4444`, warning `#F59E0B`, success `#22C55E`, divider `#E5E7EB`
  - Dark mode palette: background `#0F172A`, surface `#1E293B`, primary `#A3E635`, textPrimary `#F8FAFC`, textSecondary `#94A3B8`
- [ ] **1.5** Buat file `lib/core/theme/app_typography.dart`
  - Heading: 24sp Bold, Sub-heading: 18sp Semi-bold, Body: 14sp Regular, Caption: 12sp Regular, Metric: 32sp Bold, Button label: 14sp Semi-bold
- [ ] **1.6** Buat file `lib/core/theme/app_theme.dart`
  - `lightTheme` dan `darkTheme` (ThemeData)
  - Integrasi color tokens + typography
- [ ] **1.7** Buat `lib/core/theme/theme_provider.dart`
  - Provider/Riverpod state untuk toggle dark/light mode
  - Persist preferensi ke `SharedPreferences`
- [ ] **1.8** Buat reusable widgets di `lib/core/widgets/`:
  - `app_card.dart` — Card dengan borderRadius 16px, elevation 2, padding 16px
  - `app_button.dart` — Primary (lime green) + Secondary (dark) button, borderRadius 12px, height 48px
  - `app_input.dart` — TextField dengan borderRadius 12px, border divider color
  - `app_chip.dart` — Status chip (warna dinamis berdasarkan status)
  - `app_empty_state.dart` — Ilustrasi + teks untuk list kosong
- [ ] **1.9** Setup `main.dart` dengan MaterialApp, theme provider, placeholder home screen
- [ ] **1.10** Verifikasi app jalan di emulator (Android + iOS)

### File yang dibuat/dimodifikasi

| Aksi | Path |
|------|------|
| [NEW] | `lib/core/theme/app_colors.dart` |
| [NEW] | `lib/core/theme/app_typography.dart` |
| [NEW] | `lib/core/theme/app_theme.dart` |
| [NEW] | `lib/core/theme/theme_provider.dart` |
| [NEW] | `lib/core/widgets/app_card.dart` |
| [NEW] | `lib/core/widgets/app_button.dart` |
| [NEW] | `lib/core/widgets/app_input.dart` |
| [NEW] | `lib/core/widgets/app_chip.dart` |
| [NEW] | `lib/core/widgets/app_empty_state.dart` |
| [MODIFY] | `lib/main.dart` |
| [MODIFY] | `pubspec.yaml` |
| [NEW] | `android/app/google-services.json` |
| [NEW] | `ios/Runner/GoogleService-Info.plist` |

### Definition of Done

```bash
# App build tanpa error
flutter analyze --no-fatal-infos
flutter build apk --debug

# Theme toggle test
flutter test test/core/theme_test.dart
```

- [ ] `flutter analyze` exit 0 (no errors)
- [ ] `flutter build apk --debug` exit 0
- [ ] Dark mode toggle works (SharedPreferences persists)
- [ ] Semua reusable widget bisa di-render tanpa error

---

## Phase 2 — Auth + Role System

**Branch:** `phase-2/auth-role-system`
**Depends on:** Phase 1

**Tujuan:** Implementasi halaman login, Firebase Auth integration, role-based routing (admin 3 tab vs operator 2 tab).

### Tasks

- [ ] **2.1** Buat Firestore collection `users` (seed admin account manual di Firebase Console)
- [ ] **2.2** Buat `lib/data/models/user_model.dart`
  - Fields: `userId`, `email`, `displayName`, `role`, `photoUrl`, `driverId`, `createdAt`, `updatedAt`
  - `fromFirestore()` / `toFirestore()` factory
- [ ] **2.3** Buat `lib/data/repositories/auth_repository.dart`
  - `signIn(email, password)` → Firebase Auth sign in
  - `signOut()` → Firebase Auth sign out
  - `getCurrentUser()` → current auth state
  - `getUserRole(uid)` → fetch from Firestore `users/{uid}`
- [ ] **2.4** Buat `lib/features/auth/viewmodels/auth_viewmodel.dart`
  - State: `isLoading`, `errorMessage`, `currentUser`
  - Login flow: validate → sign in → fetch role → navigate
  - Error mapping (email not found, wrong password, no connection, user doc missing)
- [ ] **2.5** Buat `lib/features/auth/views/login_page.dart`
  - Layout sesuai PRD Section 6.1: logo, email field, password field (eye toggle), "Masuk" CTA, error messages
  - Menggunakan reusable widgets dari Phase 1
- [ ] **2.6** Buat `lib/core/navigation/app_router.dart`
  - Auth state listener: sudah login → Home, belum → Login
  - Role-based: admin → `AdminShell` (3 tab), operator → `OperatorShell` (2 tab)
- [ ] **2.7** Buat `lib/core/navigation/admin_shell.dart`
  - Bottom nav bar 3 tab: Home, Schedule, Booking
  - Placeholder pages per tab
- [ ] **2.8** Buat `lib/core/navigation/operator_shell.dart`
  - Bottom nav bar 2 tab: Home, Schedule
  - Placeholder pages per tab
- [ ] **2.9** Deploy Firestore Security Rules (Section 8.1 dari PRD) — `users` collection rules
- [ ] **2.10** Test login flow end-to-end: admin masuk → 3 tab, buat akun operator manual → operator masuk → 2 tab

### File yang dibuat/dimodifikasi

| Aksi | Path |
|------|------|
| [NEW] | `lib/data/models/user_model.dart` |
| [NEW] | `lib/data/repositories/auth_repository.dart` |
| [NEW] | `lib/features/auth/viewmodels/auth_viewmodel.dart` |
| [NEW] | `lib/features/auth/views/login_page.dart` |
| [NEW] | `lib/core/navigation/app_router.dart` |
| [NEW] | `lib/core/navigation/admin_shell.dart` |
| [NEW] | `lib/core/navigation/operator_shell.dart` |
| [NEW] | `firestore.rules` |
| [MODIFY] | `lib/main.dart` |

### Definition of Done

```bash
flutter analyze --no-fatal-infos
flutter test test/features/auth/
```

- [ ] Login admin → sees 3-tab navbar
- [ ] Login operator → sees 2-tab navbar
- [ ] Wrong password → error message shown
- [ ] Logout → returns to login page
- [ ] `flutter analyze` exit 0

---

## Phase 3 — Data Models + Repository Layer

**Branch:** `phase-3/data-models-repositories`
**Depends on:** Phase 1

**Tujuan:** Buat semua Dart model classes dan Firestore repository layer (MVVM foundation).

### Tasks

- [ ] **3.1** Buat `lib/data/models/vehicle_model.dart`
  - Fields sesuai PRD Section 5.2: `vehicleId`, `name`, `plateNumber`, `category`, `status`, `photoUrl`, `conditionNotes`, `createdAt`, `updatedAt`
  - `fromFirestore()` / `toFirestore()`
  - Enum: `VehicleStatus { ready, inUse, maintenance }`
  - Enum: `VehicleCategory { bus, elf, hiace, mpv, suv, other }`
- [ ] **3.2** Buat `lib/data/models/driver_model.dart`
  - Fields sesuai PRD Section 5.3
  - Enum: `DriverStatus { standby, onTrip }`
- [ ] **3.3** Buat `lib/data/models/booking_model.dart`
  - Fields sesuai PRD Section 5.4 (termasuk denormalized fields)
  - Enum: `PaymentStatus { unpaid, dp, paid }`
  - Enum: `BookingStatus { upcoming, active, completed, cancelled }`
- [ ] **3.4** Buat `lib/data/models/booking_log_model.dart`
  - Fields sesuai PRD Section 5.5
- [ ] **3.5** Buat `lib/data/models/customer_model.dart`
  - Fields sesuai PRD Section 5.6
- [ ] **3.6** Buat `lib/data/repositories/vehicle_repository.dart`
  - CRUD: `getAll()`, `getById()`, `getByStatus()`, `add()`, `update()`, `delete()`
  - `getReadyVehicles()` — filter status ready
  - `updateStatus(vehicleId, status)`
  - `checkPlateExists(plateNumber)` — uniqueness validation
- [ ] **3.7** Buat `lib/data/repositories/driver_repository.dart`
  - CRUD + `getStandbyDrivers()`, `updateStatus()`, `checkCodeIdExists()`
- [ ] **3.8** Buat `lib/data/repositories/booking_repository.dart`
  - CRUD + query methods:
    - `getActiveBookings()` — status upcoming/active, sort startDateTime
    - `getBookingsForMonth(year, month)` — untuk kalender
    - `getBookingsForDate(date)` — untuk detail tanggal
    - `getBookingsByDriver(driverId)` — untuk operator
    - `getCompletedBookings()` — untuk riwayat
    - `checkConflict(vehicleId, driverId, start, end)` — bentrok check
    - `addWithLog(booking)` — create + log dalam batch
    - `cancelBooking(bookingId)` — batch: cancel + release vehicle + release driver + log
    - `completeBooking(bookingId)` — batch: complete + release vehicle + release driver + log
    - `extendBooking(bookingId, newEnd, extraPrice)` — perpanjang + log
    - `updatePaymentStatus(bookingId, newStatus)` — update + log
- [ ] **3.9** Buat `lib/data/repositories/customer_repository.dart`
  - `searchByName(query)` — auto-complete (startsWith, limit 5)
  - `upsertCustomer(name, phone)` — create or increment counter
- [ ] **3.10** Buat `lib/data/repositories/booking_log_repository.dart`
  - `getLogsForBooking(bookingId)` — orderBy timestamp desc
  - `addLog(bookingId, log)`

### File yang dibuat/dimodifikasi

| Aksi | Path |
|------|------|
| [NEW] | `lib/data/models/vehicle_model.dart` |
| [NEW] | `lib/data/models/driver_model.dart` |
| [NEW] | `lib/data/models/booking_model.dart` |
| [NEW] | `lib/data/models/booking_log_model.dart` |
| [NEW] | `lib/data/models/customer_model.dart` |
| [NEW] | `lib/data/repositories/vehicle_repository.dart` |
| [NEW] | `lib/data/repositories/driver_repository.dart` |
| [NEW] | `lib/data/repositories/booking_repository.dart` |
| [NEW] | `lib/data/repositories/customer_repository.dart` |
| [NEW] | `lib/data/repositories/booking_log_repository.dart` |

### Definition of Done

```bash
flutter analyze --no-fatal-infos
flutter test test/data/
```

- [ ] Semua model class bisa serialize/deserialize tanpa error
- [ ] Repository CRUD methods terdefinisi (compile pass)
- [ ] Enum status values sesuai PRD
- [ ] `flutter analyze` exit 0

---

## Phase 4 — Armada: Kendaraan

**Branch:** `phase-4/armada-kendaraan`
**Depends on:** Phase 2, Phase 3

**Tujuan:** Implementasi Tab Kendaraan di halaman Armada — list, form tambah/edit, upload foto, status toggle, hapus + validasi.

### Tasks

- [ ] **4.1** Install dependencies: `image_picker`, `cached_network_image`
- [ ] **4.2** Buat `lib/features/armada/viewmodels/vehicle_viewmodel.dart`
  - State: `vehicles` list, `isLoading`, `errorMessage`
  - Methods: `loadVehicles()`, `addVehicle()`, `updateVehicle()`, `deleteVehicle()`, `toggleStatus()`
  - Validasi: plat nomor unik, cek booking aktif sebelum hapus
- [ ] **4.3** Buat `lib/features/armada/views/armada_page.dart`
  - Tab bar: "Kendaraan" | "Supir" (Supir tab placeholder dulu)
  - Operator: hanya tampil tab Kendaraan (read-only)
- [ ] **4.4** Buat `lib/features/armada/views/vehicle_list_view.dart`
  - List/grid card kendaraan
  - Card: foto (atau placeholder), nama, plat, chip kategori, chip status (warna), catatan kondisi
  - Tap → edit (admin) / detail (operator)
  - Swipe left → hapus (admin only, dengan validasi booking aktif)
  - FAB: "+ Tambah Kendaraan" (admin only)
- [ ] **4.5** Buat `lib/features/armada/views/vehicle_form_page.dart`
  - Form: nama, plat nomor, kategori dropdown, foto picker (kamera/galeri), catatan kondisi, status (Ready/Bengkel)
  - Upload foto ke Cloud Storage (compress max 1MB)
  - Validasi plat nomor unik
  - Mode: Tambah + Edit (reuse same form)
- [ ] **4.6** Deploy Storage Rules (Section 8.2 — vehicles path)
- [ ] **4.7** Deploy Firestore Security Rules (vehicles collection)
- [ ] **4.8** Integrasi navigasi: tombol "Kelola Armada" dari Home → Armada page

### File yang dibuat/dimodifikasi

| Aksi | Path |
|------|------|
| [NEW] | `lib/features/armada/viewmodels/vehicle_viewmodel.dart` |
| [NEW] | `lib/features/armada/views/armada_page.dart` |
| [NEW] | `lib/features/armada/views/vehicle_list_view.dart` |
| [NEW] | `lib/features/armada/views/vehicle_form_page.dart` |
| [MODIFY] | `pubspec.yaml` |
| [MODIFY] | `firestore.rules` |
| [MODIFY] | `storage.rules` |

### Definition of Done

```bash
flutter analyze --no-fatal-infos
flutter test test/features/armada/vehicle_test.dart
```

- [ ] Admin bisa tambah kendaraan + upload foto
- [ ] Admin bisa edit kendaraan
- [ ] Admin bisa toggle status Ready ↔ Bengkel
- [ ] Admin bisa hapus kendaraan (hanya jika tidak ada booking aktif)
- [ ] Operator lihat list kendaraan (read-only, tanpa FAB/hapus)
- [ ] Plat nomor duplikat ditolak
- [ ] `flutter analyze` exit 0

---

## Phase 5 — Armada: Supir

**Branch:** `phase-5/armada-supir`
**Depends on:** Phase 4

**Tujuan:** Implementasi Tab Supir — list, form tambah (auto-create Firebase Auth + Firestore), edit, hapus.

### Tasks

- [ ] **5.1** Buat `lib/features/armada/viewmodels/driver_viewmodel.dart`
  - State: `drivers` list, `isLoading`, `errorMessage`
  - `addDriver()` — batch: create Auth account + create `users` doc + create `drivers` doc + rollback on failure
  - `updateDriver()` — edit nama, kode ID, nomor HP
  - `deleteDriver()` — validasi booking aktif, hapus drivers doc + users doc + disable Auth account
  - Validasi: kode ID unik
- [ ] **5.2** Buat `lib/features/armada/views/driver_list_view.dart`
  - List card supir: avatar (initials), nama, kode ID, chip status (Standby/Sedang Jalan)
  - Tap → edit
  - FAB: "+ Tambah Supir"
  - Admin only (Operator tidak lihat tab ini)
- [ ] **5.3** Buat `lib/features/armada/views/driver_form_page.dart`
  - Form Tambah: nama, kode ID, nomor HP, email, password (toggle visibility)
  - Form Edit: nama, kode ID, nomor HP (email/password tidak bisa edit)
  - Note: "Akun ini digunakan supir untuk login ke aplikasi"
  - Validasi kode ID unik
- [ ] **5.4** Integrasi tab Supir di `armada_page.dart` (replace placeholder)
- [ ] **5.5** Deploy Firestore Security Rules (drivers collection)
- [ ] **5.6** Test flow: admin tambah supir → supir bisa login sebagai operator → lihat 2-tab navbar

### File yang dibuat/dimodifikasi

| Aksi | Path |
|------|------|
| [NEW] | `lib/features/armada/viewmodels/driver_viewmodel.dart` |
| [NEW] | `lib/features/armada/views/driver_list_view.dart` |
| [NEW] | `lib/features/armada/views/driver_form_page.dart` |
| [MODIFY] | `lib/features/armada/views/armada_page.dart` |
| [MODIFY] | `firestore.rules` |

### Definition of Done

```bash
flutter analyze --no-fatal-infos
flutter test test/features/armada/driver_test.dart
```

- [ ] Admin tambah supir → akun operator terbuat di Auth + Firestore
- [ ] Supir baru bisa login → masuk Home Operator
- [ ] Admin edit supir (nama, kode ID)
- [ ] Admin hapus supir → akun disabled, tidak bisa login lagi
- [ ] Kode ID duplikat ditolak
- [ ] Rollback jika create Auth berhasil tapi Firestore gagal
- [ ] `flutter analyze` exit 0

---

## Phase 6 — Booking: Form + List

**Branch:** `phase-6/booking-form-list`
**Depends on:** Phase 4, Phase 5

**Tujuan:** Implementasi form tambah booking (multi-stop, auto-complete, dropdown, validasi bentrok) dan list booking aktif + filter.

### Tasks

- [ ] **6.1** Buat `lib/features/booking/viewmodels/booking_viewmodel.dart`
  - State: `activeBookings`, `isLoading`, `errorMessage`
  - `loadActiveBookings()` — query upcoming + active, sort startDateTime
  - `filterBookings(filter)` — semua / hari ini / minggu ini
  - `createBooking(data)` — validasi bentrok → batch write (booking + log + customer upsert + status update)
- [ ] **6.2** Buat `lib/features/booking/views/booking_page.dart`
  - 2 sub-tab: "Aktif" | "Riwayat" (riwayat placeholder dulu)
  - FAB: "+" Tambah Booking
- [ ] **6.3** Buat `lib/features/booking/views/booking_list_view.dart`
  - Filter chip bar: Semua | Hari Ini | Minggu Ini
  - List card booking: ikon kategori, nama penyewa, plat + kendaraan, rute, tanggal+jam, badge status pembayaran
  - Swipe kiri → "Batalkan" (konfirmasi dialog)
  - Empty state
- [ ] **6.4** Buat `lib/features/booking/views/booking_form_page.dart`
  - Full-screen scrollable form sesuai PRD Section 6.4.2:
    - Nama penyewa + auto-complete overlay (query customers, debounce 300ms)
    - Nomor HP (auto-fill dari saran)
    - Multi-stop route input (dynamic list + "Tambah Rute" button)
    - Harga sewa (formatted Rp)
    - Status pembayaran (segmented: Belum Bayar / DP / Lunas)
    - Dropdown kendaraan (only Ready)
    - Dropdown supir (only Standby)
    - DateTimePicker mulai + selesai
    - Catatan tambahan
  - Sticky CTA: "Simpan Booking"
- [ ] **6.5** Implementasi validasi bentrok jadwal (Firestore transaction)
  - Cek vehicle conflict → dialog error detail
  - Cek driver conflict → dialog error detail
- [ ] **6.6** Implementasi auto-complete pelanggan
  - Query collection `customers` saat ketik (debounce, limit 5)
  - Dropdown overlay: "Nama — No HP"
  - Tap → auto-fill nama + HP
- [ ] **6.7** Deploy Firestore Security Rules (bookings + customers collection)
- [ ] **6.8** Integrasi navigasi: tab Booking di admin navbar → booking_page

### File yang dibuat/dimodifikasi

| Aksi | Path |
|------|------|
| [NEW] | `lib/features/booking/viewmodels/booking_viewmodel.dart` |
| [NEW] | `lib/features/booking/views/booking_page.dart` |
| [NEW] | `lib/features/booking/views/booking_list_view.dart` |
| [NEW] | `lib/features/booking/views/booking_form_page.dart` |
| [NEW] | `lib/core/widgets/multi_stop_input.dart` |
| [NEW] | `lib/core/widgets/customer_autocomplete.dart` |
| [MODIFY] | `lib/core/navigation/admin_shell.dart` |
| [MODIFY] | `firestore.rules` |

### Definition of Done

```bash
flutter analyze --no-fatal-infos
flutter test test/features/booking/booking_form_test.dart
```

- [ ] Admin bisa tambah booking → data tersimpan di Firestore
- [ ] Multi-stop route input berfungsi (tambah/hapus stop)
- [ ] Auto-complete pelanggan muncul saat ketik nama
- [ ] Bentrok jadwal kendaraan → ditolak + dialog error
- [ ] Bentrok jadwal supir → ditolak + dialog error
- [ ] List booking aktif tampil + filter berfungsi
- [ ] Customer auto-saved di background
- [ ] `flutter analyze` exit 0

---

## Phase 7 — Booking: Detail + Aksi

**Branch:** `phase-7/booking-detail-actions`
**Depends on:** Phase 6

**Tujuan:** Halaman detail booking lengkap dengan tombol aksi (ubah pembayaran, selesai, batal, perpanjang) + activity log + riwayat tab.

### Tasks

- [ ] **7.1** Buat `lib/features/booking/views/booking_detail_page.dart`
  - Layout sesuai PRD Section 6.4.3:
    - Header: nama penyewa + badges (booking status + payment status)
    - Info card: HP (tappable WA), kendaraan, supir, rute, jadwal, harga, catatan
    - Tombol aksi (conditional render based on status)
    - Timeline log aktivitas
- [ ] **7.2** Implementasi "Ubah Status Pembayaran"
  - Bottom sheet: Belum Bayar / DP / Lunas
  - Update `paymentStatus` + create log
  - Marker warna di kalender otomatis berubah
- [ ] **7.3** Implementasi "Konfirmasi Selesai"
  - Dialog konfirmasi → batch write: booking completed + vehicle ready + driver standby + log
- [ ] **7.4** Implementasi "Batalkan Booking"
  - Dialog warning → batch write sesuai PRD Section 7.5
  - Release vehicle + driver, marker hilang dari kalender
- [ ] **7.5** Implementasi "Perpanjang Booking"
  - Bottom sheet: current endDateTime (read-only) + new endDateTime picker + extra price input
  - Validasi: newEnd > oldEnd + cek bentrok di rentang perpanjangan
  - Update endDateTime + rentalPrice + log
- [ ] **7.6** Buat `lib/features/booking/views/booking_log_timeline.dart`
  - Widget timeline: dots + lines, action text + admin name + timestamp
  - Query `bookings/{id}/logs` orderBy timestamp desc
- [ ] **7.7** Implementasi Tab Riwayat di `booking_page.dart`
  - Query completed + cancelled, sort updatedAt desc
  - Same card format, different badges
  - Pagination: 20 per batch, infinite scroll
  - Tap → detail (read-only, tanpa tombol aksi)
- [ ] **7.8** Navigasi: tap card dari list/schedule → detail page (pass bookingId)

### File yang dibuat/dimodifikasi

| Aksi | Path |
|------|------|
| [NEW] | `lib/features/booking/views/booking_detail_page.dart` |
| [NEW] | `lib/features/booking/views/booking_log_timeline.dart` |
| [MODIFY] | `lib/features/booking/views/booking_page.dart` |
| [MODIFY] | `lib/features/booking/viewmodels/booking_viewmodel.dart` |

### Definition of Done

```bash
flutter analyze --no-fatal-infos
flutter test test/features/booking/booking_detail_test.dart
```

- [ ] Detail booking menampilkan semua info lengkap
- [ ] Ubah pembayaran → badge warna berubah
- [ ] Konfirmasi selesai → booking completed, vehicle + driver released
- [ ] Batalkan → booking cancelled, vehicle + driver released, marker hilang
- [ ] Perpanjang → endDateTime updated, harga updated, bentrok dicek
- [ ] Activity log timeline menampilkan riwayat perubahan
- [ ] Tab Riwayat menampilkan booking selesai/batal + pagination
- [ ] Operator lihat detail (read-only, tanpa tombol aksi)
- [ ] `flutter analyze` exit 0

---

## Phase 8 — Schedule (Kalender)

**Branch:** `phase-8/schedule-calendar`
**Depends on:** Phase 6

**Tujuan:** Halaman kalender bulanan dengan marker warna per status pembayaran, tap tanggal → card detail booking.

### Tasks

- [ ] **8.1** Install dependency: `table_calendar`
- [ ] **8.2** Buat `lib/features/schedule/viewmodels/schedule_viewmodel.dart`
  - State: `selectedDate`, `currentMonth`, `bookingsForMonth`, `bookingsForSelectedDate`
  - `loadBookingsForMonth(year, month)` — query booking yang overlap dengan bulan ini
  - `selectDate(date)` — filter booking yang jatuh di tanggal ini
  - `navigateMonth(direction)` — prev/next month
  - Logic: iterasi booking, plot di semua tanggal antara start dan end
- [ ] **8.3** Buat `lib/features/schedule/views/schedule_page.dart`
  - Header: "◀ Juni 2026 ▶"
  - `TableCalendar` widget dengan custom marker builder
  - Today highlight (primary circle)
  - Selected date highlight
- [ ] **8.4** Buat custom marker builder
  - Per tanggal: tampilkan chip kotak kecil (borderRadius 4px)
  - Teks: plat nomor disingkat
  - Warna: merah (unpaid) / kuning (dp) / hijau (paid)
  - Max 3 marker, sisanya "+N lagi" chip
  - Exclude cancelled bookings
- [ ] **8.5** Buat `lib/features/schedule/views/schedule_detail_section.dart`
  - Area di bawah kalender (slide up animation)
  - Default: "Tap tanggal untuk lihat detail"
  - Saat tanggal di-tap: list card booking di tanggal itu
  - Card: ikon status dot + plat + nama kendaraan, penyewa, rute, jam + badge pembayaran
  - Tap card → ke Detail Booking
- [ ] **8.6** Handle edge cases:
  - Booking lintas bulan → marker di kedua bulan
  - > 3 booking per tanggal → "+N lagi" chip
  - Bulan kosong → kalender tampil, area detail kosong
- [ ] **8.7** Integrasi navigasi: tab Schedule di navbar → schedule_page

### File yang dibuat/dimodifikasi

| Aksi | Path |
|------|------|
| [NEW] | `lib/features/schedule/viewmodels/schedule_viewmodel.dart` |
| [NEW] | `lib/features/schedule/views/schedule_page.dart` |
| [NEW] | `lib/features/schedule/views/schedule_detail_section.dart` |
| [MODIFY] | `pubspec.yaml` |
| [MODIFY] | `lib/core/navigation/admin_shell.dart` |
| [MODIFY] | `lib/core/navigation/operator_shell.dart` |

### Definition of Done

```bash
flutter analyze --no-fatal-infos
flutter test test/features/schedule/
```

- [ ] Kalender bulanan tampil dengan navigasi bulan
- [ ] Marker warna muncul di tanggal yang ada booking
- [ ] Warna marker sesuai status pembayaran (merah/kuning/hijau)
- [ ] Tap tanggal → card detail booking tampil di bawah
- [ ] Booking lintas bulan → marker di kedua bulan
- [ ] > 3 booking per tanggal → "+N lagi"
- [ ] Tap card → navigasi ke Detail Booking
- [ ] Admin + Operator bisa lihat kalender
- [ ] `flutter analyze` exit 0

---

## Phase 9 — Home Dashboard

**Branch:** `phase-9/home-dashboard`
**Depends on:** Phase 7, Phase 8

**Tujuan:** Implementasi Home Admin (search, metrik, jadwal hari ini, riwayat terbaru, quick action) dan Home Operator (jadwal assigned, riwayat sendiri).

### Tasks

- [ ] **9.1** Buat `lib/features/home/viewmodels/home_admin_viewmodel.dart`
  - State: `mobilKeluar`, `bookingBaru`, `belumLunas`, `jadwalHariIni`, `riwayatTerbaru`
  - Query metrik cards sesuai PRD Section 6.2.1
  - Query jadwal hari ini
  - Query riwayat terbaru (completed + cancelled, limit 10)
- [ ] **9.2** Buat `lib/features/home/viewmodels/home_operator_viewmodel.dart`
  - State: `jadwalSayaHariIni`, `jadwalMendatang`, `riwayatSaya`
  - Filter by `driverId == currentDriverId`
- [ ] **9.3** Buat `lib/features/home/views/home_admin_page.dart`
  - Layout sesuai PRD Section 6.2.1:
    - Header: sapaan + tanggal + avatar
    - Search bar (tap → full-screen search)
    - 3 card metrik horizontal
    - Quick action buttons: "Kelola Armada" + "Lihat Laporan"
    - Section "Jadwal Hari Ini" (vertical cards + empty state)
    - Section "Riwayat Sewa Terbaru" (horizontal scroll cards)
- [ ] **9.4** Buat `lib/features/home/views/home_operator_page.dart`
  - Layout sesuai PRD Section 6.2.2:
    - Header: sapaan + avatar
    - Section "Jadwal Saya Hari Ini" (prominent card)
    - Section "Jadwal Mendatang" (smaller cards)
    - Section "Riwayat Perjalanan Saya" (horizontal scroll)
- [ ] **9.5** Buat `lib/features/home/views/search_page.dart`
  - Full-screen overlay: auto-focused search field
  - Real-time results (debounce 300ms): grouped by Booking / Kendaraan / Supir
  - Tap result → navigasi ke detail
  - Empty state: "Tidak ditemukan hasil"
- [ ] **9.6** Buat `lib/core/widgets/metric_card.dart`
  - Reusable card: angka besar + label kecil + tap action
- [ ] **9.7** Buat `lib/core/widgets/horizontal_booking_card.dart`
  - Card untuk horizontal scroll: penyewa, plat, tanggal, status, harga
- [ ] **9.8** Integrasi: replace placeholder home pages di admin_shell + operator_shell
- [ ] **9.9** Tap metrik card → navigasi ke list booking ter-filter

### File yang dibuat/dimodifikasi

| Aksi | Path |
|------|------|
| [NEW] | `lib/features/home/viewmodels/home_admin_viewmodel.dart` |
| [NEW] | `lib/features/home/viewmodels/home_operator_viewmodel.dart` |
| [NEW] | `lib/features/home/views/home_admin_page.dart` |
| [NEW] | `lib/features/home/views/home_operator_page.dart` |
| [NEW] | `lib/features/home/views/search_page.dart` |
| [NEW] | `lib/core/widgets/metric_card.dart` |
| [NEW] | `lib/core/widgets/horizontal_booking_card.dart` |
| [MODIFY] | `lib/core/navigation/admin_shell.dart` |
| [MODIFY] | `lib/core/navigation/operator_shell.dart` |

### Definition of Done

```bash
flutter analyze --no-fatal-infos
flutter test test/features/home/
```

- [ ] Admin Home: 3 metrik cards menampilkan angka benar
- [ ] Admin Home: jadwal hari ini tampil
- [ ] Admin Home: riwayat terbaru horizontal scroll berfungsi
- [ ] Tap metrik card → list booking ter-filter
- [ ] Search: ketik nama → hasil muncul grouped
- [ ] Operator Home: hanya jadwal yang di-assign ke supir
- [ ] Operator Home: riwayat hanya perjalanan sendiri
- [ ] Quick action "Kelola Armada" → ke halaman Armada
- [ ] `flutter analyze` exit 0

---

## Phase 10 — Laporan + Profil + Polish

**Branch:** `phase-10/laporan-profil-polish`
**Depends on:** Phase 9

**Tujuan:** Laporan keuangan (metrik, filter, export PDF/Excel), profil (avatar, ganti password, dark mode), deploy Security Rules final, polish.

### Tasks

- [ ] **10.1** Install dependencies: `pdf`, `printing`, `excel` atau `csv`, `share_plus`
- [ ] **10.2** Buat `lib/features/laporan/viewmodels/report_viewmodel.dart`
  - State: `totalPemasukan`, `totalDP`, `sisaPiutang`, `bookingSelesai`, `bookingDibatalkan`
  - `loadReport(startDate, endDate)` — kalkulasi sesuai PRD Section 6.6
  - `exportPDF()` — generate PDF file + share
  - `exportExcel()` — generate Excel/CSV file + share
- [ ] **10.3** Buat `lib/features/laporan/views/report_page.dart`
  - Filter: Hari Ini | Minggu Ini | Bulan Ini | Custom (date range picker)
  - 5 metrik cards (2-column grid)
  - Export buttons: "Export PDF" + "Export Excel"
- [ ] **10.4** Implementasi PDF generation
  - Format sesuai PRD Section 6.6: header + summary + detail table
  - Share via share sheet OS
- [ ] **10.5** Implementasi Excel/CSV generation
  - Tabel booking detail + summary
  - Share via share sheet OS
- [ ] **10.6** Buat `lib/features/profil/viewmodels/profile_viewmodel.dart`
  - State: `currentUser`, `isLoading`
  - `updateAvatar()` — pick image + upload Cloud Storage + update photoUrl
  - `changePassword()` — validate old + new + confirm → Firebase updatePassword
  - `toggleDarkMode()` — update SharedPreferences + rebuild theme
  - `logout()` — Firebase signOut → navigate to login
- [ ] **10.7** Buat `lib/features/profil/views/profile_page.dart`
  - Layout sesuai PRD Section 6.7:
    - Avatar (tap → camera/gallery) + edit button
    - Info card: nama, email, role chip
    - Settings: Ganti Password → dialog, Dark Mode → toggle, Keluar → confirm dialog
    - App version text
- [ ] **10.8** Deploy Firestore Security Rules final (semua collection)
- [ ] **10.9** Deploy Storage Rules final (vehicles + profiles)
- [ ] **10.10** Setup Firestore indexes (compound indexes sesuai PRD Section 5.4)
- [ ] **10.11** Polish & QA:
  - Cek semua empty states
  - Cek semua error handling messages
  - Cek dark mode di semua halaman
  - Cek operator access restriction di semua halaman
  - Pull-to-refresh di list pages
  - Loading skeleton/shimmer
- [ ] **10.12** Build APK release + test di device fisik

### File yang dibuat/dimodifikasi

| Aksi | Path |
|------|------|
| [NEW] | `lib/features/laporan/viewmodels/report_viewmodel.dart` |
| [NEW] | `lib/features/laporan/views/report_page.dart` |
| [NEW] | `lib/features/profil/viewmodels/profile_viewmodel.dart` |
| [NEW] | `lib/features/profil/views/profile_page.dart` |
| [MODIFY] | `pubspec.yaml` |
| [MODIFY] | `firestore.rules` (final) |
| [MODIFY] | `storage.rules` (final) |
| [NEW] | `firestore.indexes.json` |

### Definition of Done

```bash
flutter analyze --no-fatal-infos
flutter build apk --release
flutter test
```

- [ ] Laporan metrik kalkulasi benar
- [ ] Export PDF → file valid, bisa di-share
- [ ] Export Excel/CSV → file valid, bisa di-share
- [ ] Profil: upload avatar → foto update
- [ ] Profil: ganti password → login ulang dengan password baru berhasil
- [ ] Dark mode toggle → theme berubah + persist setelah restart
- [ ] Logout → kembali ke login
- [ ] Security Rules: operator tidak bisa write
- [ ] Release APK build berhasil
- [ ] `flutter analyze` exit 0
- [ ] `flutter test` exit 0

---

## Phase 11 — Revisi 1 (Booking & Home UI)

**Branch:** `phase-11/revisi-1`
**Depends on:** Phase 9

**Tujuan:** Menerapkan revisi dan perbaikan UI berdasarkan feedback, termasuk pewarnaan status, perbaikan crash provider, penyederhanaan UI home, penambahan halaman riwayat, dan akses cepat logout.

### Tasks

- [ ] **11.1** Perbaikan Warna Status (Bengkel & Ready)
  - Modifikasi `lib/core/widgets/app_chip.dart` agar status "Bengkel" berwarna orange (warning) dan "Ready" berwarna hijau (success) sesuai label yang dihasilkan oleh enum.
- [ ] **11.2** Perbaikan Error Layar Merah pada Form Booking
  - Bungkus pemanggilan `BookingFormPage` di dalam `dashboard_page.dart` dan `booking_list_view.dart` dengan `ChangeNotifierProvider.value` agar tidak terjadi `ProviderNotFoundException`.
- [ ] **11.3** Bersihkan UI Refresh di Home
  - Hapus ikon refresh manual dari AppBar di `dashboard_page.dart`.
  - Hapus tombol "Refresh Data" dari deretan menu aksi cepat.
  - Pastikan halaman sudah diselimuti `RefreshIndicator` untuk mekanisme *pull-to-refresh*.
- [ ] **11.4** Buat Halaman/Tab Riwayat Booking Lengkap
  - Modifikasi `booking_page.dart` untuk menggunakan `DefaultTabController` dengan 2 tab: "Aktif" dan "Riwayat".
  - Buat mekanisme di `booking_list_view.dart` atau buat file baru khusus riwayat yang me-load data booking berstatus Selesai atau Dibatalkan.
- [ ] **11.5** Tambahkan Tombol Logout di Home
  - Tambahkan tombol CTA "Keluar" atau "Logout" dengan warna merah di bagian paling bawah halaman `dashboard_page.dart`.
  - Berikan konfirmasi dialog sebelum logout.

### File yang dibuat/dimodifikasi

| Aksi | Path |
|------|------|
| [MODIFY] | `lib/core/widgets/app_chip.dart` |
| [MODIFY] | `lib/features/booking/views/booking_page.dart` |
| [MODIFY] | `lib/features/booking/views/booking_list_view.dart` |
| [MODIFY] | `lib/features/dashboard/views/dashboard_page.dart` |

### Definition of Done

```bash
flutter analyze --no-fatal-infos
```

- [ ] Status Bengkel berwarna orange, Ready berwarna hijau.
- [ ] Membuka BookingFormPage dari manapun tidak menyebabkan crash merah.
- [ ] Pull-to-refresh berfungsi di Home dan tidak ada tombol manual refresh yang mengotori UI.
- [ ] Tab Riwayat Booking muncul dan menampilkan data historis.
- [ ] Admin & Operator bisa langsung logout dari halaman Home.
- [ ] `flutter analyze` exit 0 (no errors).

---

## Dependency Graph

```
Phase 1 (Setup + Design System)
    ├── Phase 2 (Auth + Role) ──┐
    └── Phase 3 (Data Models) ──┤
                                ├── Phase 4 (Armada: Kendaraan)
                                │       └── Phase 5 (Armada: Supir)
                                │               └── Phase 6 (Booking: Form + List)
                                │                       ├── Phase 7 (Booking: Detail + Aksi)
                                                       └── Phase 8 (Schedule / Kalender)
                                        └── Phase 9 (Home Dashboard)
                                                ├── Phase 10 (Laporan + Profil + Polish)
                                                └── Phase 11 (Revisi 1)
```

**Parallel opportunities:** Phase 2 + Phase 3 bisa dikerjakan paralel (no dependency satu sama lain).

---

## Estimasi Total File

| Kategori | Jumlah File |
|----------|-------------|
| Models | 6 |
| Repositories | 6 |
| ViewModels | 8 |
| Views / Pages | ~18 |
| Core Widgets | ~9 |
| Core Theme | 4 |
| Core Navigation | 3 |
| Config / Rules | ~4 |
| **Total** | **~58 files** |
