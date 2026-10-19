# 🚗 Mobilku Care

<p align="center">
  <b>Aplikasi Cerdas Pengingat & Pencatatan Perawatan Kendaraan</b><br>
  Pantau siklus cuci mobil, wax bodi, wax kaca, dan perawatan interior dengan mudah, teratur, dan otomatis.
</p>

---

## ✨ Fitur Utama

- 🔄 **Siklus Perawatan Otomatis**: Melacak progres cuci berkala dengan sistem siklus (1-6) dan reset otomatis.
- 💡 **Smart Alert & Reminder**: Memberitahu kapan waktunya aplikasi wax bodi (setiap 3 kali cuci) dan full wax (setiap 6 kali cuci).
- 📝 **Catatan Riwayat (Notes)**: Catatan khusus pada setiap aktivitas perawatan yang tersimpan rapi di halaman riwayat.
- 🔐 **Autentikasi Mudah**: Masuk dengan satu klik menggunakan **Akun Google** atau Email & Password.
- ☁️ **Cloud Realtime Sync**: Seluruh data tersimpan aman di cloud menggunakan Firebase Firestore sehingga data tidak akan hilang meskipun ganti perangkat.
- ⚡ **Ringan & Optimal**: Dibangun dengan optimasi R8 shrinker dan arsitektur modern untuk performa responsif dan ukuran APK hemat memori (~20 MB).

---

## 📱 Panduan Instalasi di HP Android (Untuk Pengguna)

Bagi Anda yang ingin langsung menggunakan aplikasi di smartphone Android:

### 1. Unduh File APK
- Unduh file **`app-release.apk`** dari menu [Releases](../../releases) repositori ini, atau salin file APK yang telah disediakan ke penyimpanan ponsel Anda.

### 2. Izinkan Pemasangan dari Sumber Tidak Dikenal (*Unknown Sources*)
1. Buka file APK yang telah diunduh di aplikasi **File Manager** / browser HP Anda.
2. Jika muncul peringatan keamanan *"Demi keamanan, ponsel Anda tidak diizinkan memasang aplikasi yang tidak dikenal dari sumber ini"*:
   - Klik **Setelan / Settings**.
   - Aktifkan toggle **Izinkan dari sumber ini** (*Allow from this source*).
3. Kembali dan klik **Instal**.

### 3. Buka Aplikasi & Masuk
1. Buka aplikasi **Mobilku Care**.
2. Klik tombol **Login dengan Google** atau daftar menggunakan email Anda.
3. Tambahkan kendaraan Anda dan mulai catat perawatan pertama Anda!

---

## 🛠️ Panduan Menjalankan dari Kode Sumber (Untuk Pengembang / Developer)

Jika Anda ingin mengembangkan atau menjalankan aplikasi ini secara lokal:

### Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.24+ / 3.38+)
- [Android Studio](https://developer.android.com/studio) dengan SDK Android & NDK
- Java JDK 17 (misal: Eclipse Adoptium JDK 17)

### Langkah-langkah

1. **Clone Repositori**:
   ```bash
   git clone git@github.com:fauzixhuman/MobilkuCare.git
   cd MobilkuCare
   ```

2. **Pasang Dependensi**:
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Firebase**:
   - Pastikan file `google-services.json` diletakkan di dalam direktori `android/app/`.
   - Daftarkan sidik jari SHA-1 & SHA-256 penandatanganan Anda di Firebase Console agar fitur Google Sign-In aktif.

4. **Jalankan Aplikasi (Mode Debug)**:
   ```bash
   flutter run
   ```

5. **Build APK Rilis (Produksi)**:
   ```bash
   flutter build apk --release --target-platform android-arm64 --tree-shake-icons
   ```
   *File output APK akan berada di `build/app/outputs/flutter-apk/app-release.apk`.*

---

## 🏗️ Teknologi yang Digunakan

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Backend & Database**: [Firebase Cloud Firestore](https://firebase.google.com/docs/firestore)
- **Autentikasi**: Firebase Authentication & Google Sign-In
- **Notifikasi**: Flutter Local Notifications & Firebase Messaging

---

## 📄 Lisensi

Proyek ini dibuat untuk keperluan manajemen perawatan kendaraan pribadi dan pengembangan aplikasi mobile. Bebas digunakan dan dimodifikasi untuk tujuan pembelajaran.
