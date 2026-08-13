# Dockerized Ookla Speedtest Server

[![Docker Build & Push](https://github.com/tkjskanesga/dockerize-speedtest-ookla-server/actions/workflows/build.yml/badge.svg)](https://github.com/tkjskanesga/dockerize-speedtest-ookla-server/actions/workflows/build.yml)
[![Docker Image](https://img.shields.io/badge/docker-image-blue.svg)](https://github.com/tkjskanesga/dockerize-speedtest-ookla-server/pkgs/container/speedtest-ookla)

Repository ini menyediakan konfigurasi Docker lengkap untuk menjalankan **Ookla Speedtest Server** secara aman, efisien, dan siap pakai. Menggunakan base image `debian:bookworm-slim` dan dijalankan di bawah non-root user (`ookla` dengan UID/GID `1100`).

## Persyaratan Sistem
- **Docker Engine** v20.10+
- **Docker Compose** v2.0+
- Port publik yang terbuka dan dapat diakses dari internet.

## Port yang Digunakan
Server ini membutuhkan port berikut untuk diekspos agar pengujian kecepatan berjalan lancar:

| Port | Protokol | Deskripsi | Status |
| :--- | :--- | :--- | :--- |
| **80** | TCP | HTTP Legacy / Latency Test | Wajib |
| **443** | TCP | Secure HTTPS Connection | Wajib |
| **8080** | TCP & UDP | Port Utama Ookla Speedtest | Wajib |
| **5060** | TCP & UDP | Port Cadangan Ookla Speedtest | Wajib |

## Panduan Instalasi Cepat

### 1. Kloning Repository
```bash
git clone https://github.com/tkjskanesga/dockerize-speedtest-ookla-server.git
cd dockerize-speedtest-ookla-server
```

### 2. Jalankan Container
Secara default, container akan langsung mengunduh versi server terbaru dari Ookla dan menjalankannya:
```bash
docker compose up -d
```

### 3. Cek Log Server
```bash
docker compose logs -f
```


## Konfigurasi Manual SSL (Custom Certificates)
Jika Anda ingin menggunakan sertifikat SSL sendiri (misal dari Cloudflare, Commercial CA, atau sertifikat lokal) dan **tidak** menggunakan fitur auto Let's Encrypt bawaan Ookla, ikuti langkah berikut:

### Langkah 1: Siapkan Sertifikat SSL di Host
Buat folder `certs` di root project dan letakkan file sertifikat Anda (misal `certificate.pem` dan `privatekey.pem`) di dalamnya.
```bash
mkdir certs
# Copy file sertifikat Anda ke dalam folder certs/
```

### Langkah 2: Edit `docker-compose.yml`
Aktifkan mounting folder `certs` dengan menghapus tanda komentar (`#`) pada baris volume certs:
```yaml
    volumes:
      - speedtest-ookla-data:/home/ookla
      - ./OoklaServer.properties:/home/ookla/OoklaServer.properties
      - ./certs:/home/ookla/certs # <-- Aktifkan baris ini
```

### Langkah 3: Konfigurasi [`OoklaServer.properties`](OoklaServer.properties)
Buka berkas `OoklaServer.properties` dan sesuaikan parameter berikut:

1. **Matikan Auto Let's Encrypt**:
   ```properties
   OoklaServer.ssl.useLetsEncrypt = false
   ```
2. **Tentukan Path Sertifikat**:
   Arahkan ke lokasi di dalam container (di dalam `/home/ookla/certs/`):
   ```properties
   openSSL.server.certificateFile = /home/ookla/certs/certificate.pem
   openSSL.server.privateKeyFile = /home/ookla/certs/privatekey.pem
   ```
3. **Pastikan Auto Update Aktif (Wajib)**:
   Ookla mewajibkan opsi ini bernilai `true` agar server selalu ter-update dengan protokol pengetesan terbaru:
   ```properties
   OoklaServer.enableAutoUpdate = true
   ```

## Solusi Kendala & Troubleshooting

### 1. Error Exception: File / Permission Denied (Masalah Bind Mount Host)

#### **Penyebab**:
Aplikasi berjalan menggunakan user non-root `ookla` (UID `1100`). Jika Anda memetakan folder atau file langsung dari host (seperti `./certs` atau `./OoklaServer.properties`), dan file/folder tersebut dimiliki oleh `root` atau user host lain tanpa izin akses tulis/baca untuk UID `1100`, OoklaServer akan memicu **error/exception** (terutama saat mencoba memperbarui dirinya sendiri dengan fitur auto-update).

#### **Solusi**:
Ubah kepemilikan berkas dan folder di host agar dapat diakses oleh UID `1100`:
```bash
# Ubah ownership folder sertifikat dan konfigurasi ke UID/GID 1100
sudo chown -R 1100:1100 ./certs
sudo chown 1100:1100 ./OoklaServer.properties
```

### 2. Error: Binary `OoklaServer` Hilang atau Tidak Ditemukan

#### **Penyebab**:
Jika Anda mencoba melakukan bind mount seluruh directory kerja ke host seperti ini:
```yaml
# JANGAN LAKUKAN INI jika folder di host kosong
- ./data:/home/ookla
```
Melakukan bind mount direktori host kosong ke `/home/ookla` akan menutupi/menyembunyikan seluruh file binary `OoklaServer` yang sudah diunduh di dalam image saat proses build docker dilakukan. Akibatnya container akan langsung mati karena file binary tidak ditemukan.

#### **Solusi**:
Selalu gunakan **Named Volume** untuk penyimpanan data utama `/home/ookla`:
```yaml
# Rekomendasi (Docker akan menyalin isi internal container ke volume secara otomatis)
- speedtest-ookla-data:/home/ookla
```
Jika Anda terpaksa menggunakan bind mount direktori penuh dari host, Anda harus menyalin terlebih dahulu binary `OoklaServer` ke direktori host tersebut sebelum menjalankan container.
