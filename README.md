# 📱 SSH Remote

A sleek, lightweight mobile application built with **Flutter** to monitor and manage Linux VPS / servers remotely via Secure Shell (SSH) — featuring real-time resource meters, Quick Actions (Reboot VPS, service restarts), an interactive Terminal shell, and custom app branding.

[![Build & Release Android APK](https://github.com/Reyonl/ssh-remote/actions/workflows/build-apk.yml/badge.svg)](https://github.com/Reyonl/ssh-remote/actions/workflows/build-apk.yml)
[![GitHub Release](https://img.shields.io/github/v/release/Reyonl/ssh-remote?color=blue&label=Latest%20APK)](https://github.com/Reyonl/ssh-remote/releases)

---

## 🚀 Fitur Utama

- 📊 **Agentless Server Monitoring:**
  - **CPU Load & Usage:** Memantau load average 1m, 5m, 15m dan persentase penggunaan core.
  - **RAM / Memory Meter:** Info penggunaan memori aktual (Used / Total MB) dengan visual progress bar.
  - **Disk Storage:** Status kapasitas hard drive root (`/`) dalam GB dan persentase.
  - **System Uptime & OS:** Info kernel dan lama server aktif (`uptime -p`).
- ⚡ **Quick Actions (Power & Services):**
  - **Restart VPS:** Tombol reboot 1-klik (`sudo reboot`) dengan dialog konfirmasi aman.
  - **Restart Web Server (Nginx)** & **Docker:** Menjalankan `systemctl restart` instan.
- 💻 **Interactive Mobile Terminal (CMD):**
  - Terminal VT100 / ANSI interaktif bertenaga `xterm.dart`.
  - **Accessory Bar:** Tombol pintas khusus keyboard HP (`ESC`, `TAB`, `CTRL+C`, `CTRL+D`, `CTRL+Z`, `↑`, `↓`, `←`, `→`, `|`, `/`, `~`).
- 🎨 **Desain Elegan & Responsif:**
  - **Tema Biru & Putih** (*Sapphire & Pure White*) untuk Light Mode.
  - **Dark Mode AMOLED** (*Midnight Obsidian & Cyan*) untuk kenyamanan mata di malam hari.
- 🔒 **Keamanan & Privasi:**
  - Kredensial SSH (Password / Private Key) disimpan secara lokal di perangkat menggunakan storage terenkripsi hardware (Android Keystore).
  - Tidak ada perantara server pihak ketiga; koneksi langsung (*peer-to-server*) antara HP dan VPS kamu.

---

## 📥 Download APK Langsung

Kamu bisa langsung mengunduh file `.apk` siap pasang di HP Android melalui tautan berikut:

👉 **[Download APK Terbaru di GitHub Releases](https://github.com/Reyonl/ssh-remote/releases)**

Setiap kali ada commit atau rilis baru, GitHub Actions secara otomatis meng-compile APK release dan mengunggahnya ke menu Releases.

---

## 🛠️ Tech Stack

- **Framework:** Flutter 3.x (Dart 3.x)
- **SSH Protocol Engine:** `dartssh2`
- **Terminal Emulator:** `xterm`
- **State Management:** `provider`
- **Local Storage:** `shared_preferences` & `flutter_secure_storage`
- **CI/CD:** GitHub Actions (`build-apk.yml`)

---

## 💻 Menjalankan di Komputer Lokal

```bash
# 1. Clone repository
git clone https://github.com/Reyonl/ssh-remote.git
cd ssh-remote

# 2. Ambil dependensi
flutter pub get

# 3. Jalankan automated test
flutter test

# 4. Build APK Release
flutter build apk --release
```

---

## 📜 Lisensi
MIT License © 2026 Reyon Lau Jiemin.
