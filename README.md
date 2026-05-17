<div align="center">

```
██╗    ██╗██╗███████╗ █████╗ ██████╗ ██████╗
██║    ██║██║╚══███╔╝██╔══██╗██╔══██╗██╔══██╗
██║ █╗ ██║██║  ███╔╝ ███████║██████╔╝██║  ██║
██║███╗██║██║ ███╔╝  ██╔══██║██╔══██╗██║  ██║
╚███╔███╔╝██║███████╗██║  ██║██║  ██║██████╔╝
 ╚══╝╚══╝ ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝
```

# Wizard Toolkit — v1.0.0

**A powerful offline server management toolkit built for restricted network conditions.**  
ابزار مدیریت سرور، طراحی‌شده برای شرایط شبکه‌های محدود

[![Telegram](https://img.shields.io/badge/Telegram-@Gr4y__Wizard-blue?logo=telegram)](https://t.me/Gray_wiz4rd)
[![Version](https://img.shields.io/badge/Version-1.0.0-cyan)]()
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%2020.04%20%7C%2022.04-orange)]()
[![License](https://img.shields.io/badge/License-MIT-green)]()

</div>

---

## 🇮🇷 توضیحات فارسی

### Wizard Toolkit چیست؟

Wizard Toolkit یک اسکریپت Bash پیشرفته است که در دوران قطع کامل اینترنت بین‌الملل در ایران ساخته شده.
این ابزار به طور خاص برای نصب و راه‌اندازی نیازمندی‌های شبکه روی سرورهای ایرانی طراحی شده و بیشترین کاربرد آن در شرایطی است که دسترسی به اینترنت بین‌الملل وجود ندارد.
تمام قابلیت‌های اصلی آن **کاملاً آفلاین** کار می‌کنند و نیازی به اینترنت بین‌الملل ندارند.

---

### ✨ قابلیت‌ها

#### ۱. بهینه‌سازی شبکه و میرور
- تشخیص خودکار سریع‌ترین DNS برای سرور ایران یا خارج
- پیدا کردن سریع‌ترین میرور apt و اعمال خودکار آن روی سیستم
- دو حالت جداگانه برای سرور ایران و سرور خارج

#### ۲. نصب آفلاین پنل 3X-UI
- نصب کامل پنل بدون نیاز به اینترنت
- پشتیبانی از فرمت‌های `tar.gz` و `zip`
- غیرفعال کردن خودکار SSL اجباری پنل
- ساخت و فعال‌سازی خودکار سرویس systemd

#### ۳. مدیریت تانل Backhaul Premium
- نصب آفلاین باینری Backhaul Premium
- راه‌اندازی تانل از طریق منوی تعاملی Backhaul
- اعمال IP Spoof روی فایل‌های کانفیگ toml (سرور ایران و خارج)
- تست پشتیبانی از Spoof با استفاده از Scapy (حالت Sender و Listener)
- مدیریت سرویس (مشاهده وضعیت و ریستارت)

#### ۴. مدیریت رمزنگاری پوشه‌ها
- رمزنگاری هر پوشه دلخواه با استفاده از `gocryptfs`
- قفل و باز کردن پوشه در هر زمان دلخواه
- مخفی‌سازی فوری محتویات پوشه بدون قطع شدن تانل
- پاک‌سازی history و لاگ‌های سرور پس از هر عملیات

---

### 📦 فایل‌های مورد نیاز

همه فایل‌ها باید **کنار اسکریپت اصلی** قرار بگیرند:

```
📁 wizardtoolkit/
├── wizard_toolkit.sh                    ← اسکریپت اصلی
├── x-ui-linux-amd64.tar.gz          ← برای نصب 3X-UI
├── x-ui.sh                          ← منوی مدیریت 3X-UI
├── backhaul_premium                  ← باینری Backhaul
├── backhaul.sh                       ← منوی مدیریت Backhaul
└── scapy-2.7.0-py3-none-any.whl     ← برای تست Spoof
```

> فقط فایل‌هایی که به قابلیت مورد نظرت نیاز داری رو کنارش بذار.

---

### 🚀 نصب و اجرا

فقط همین یه دستور رو روی سرورت بزن — همه چیز خودکار نصب و اجرا میشه:

```bash
bash <(curl -s https://raw.githubusercontent.com/Graywiz4rd/wizard-toolkit/main/install.sh)
```

تمام! اسکریپت دانلود میشه و بلافاصله اجرا میشه.

---

### ⚙️ سیستم‌عامل‌های پشتیبانی‌شده

| سیستم‌عامل | وضعیت |
|-----------|--------|
| Ubuntu 24.04 LTS | ✅ کاملاً پشتیبانی‌شده |
| Ubuntu 22.04 LTS | ✅ کاملاً پشتیبانی‌شده |
| Ubuntu 20.04 LTS | ✅ کاملاً پشتیبانی‌شده |
| Debian 11/12 | ⚠️ تست نشده |

---

### 📡 ارتباط با سازنده

- **تلگرام:** [@Gr4y_Wizard](https://t.me/Gr4y_Wizard)
- **کانال:** [t.me/Gray_wiz4rd](https://t.me/Gray_wiz4rd)

---
---

## 🌐 English Description

### What is Wizard Toolkit?

Wizard Toolkit is an advanced Bash script designed for easy server management under restricted internet conditions. All core features work **completely offline** — no international internet access required.

It is specifically built for setting up and managing network tunnels and proxy panels under internet censorship conditions.

---

### ✨ Features

#### 1. Network & Mirror Optimizer
- Auto-detects fastest DNS servers (Iran or Global mode)
- Finds the fastest apt mirror (Iranian or international)
- Applies settings automatically to the system

#### 2. 3X-UI Offline Installer
- Full installation with zero internet dependency
- Supports both `tar.gz` and `zip` package formats
- Automatically disables forced SSL on the panel
- Creates and enables systemd service

#### 3. Backhaul Premium Manager
- **Offline installation** of Backhaul Premium binary
- **Tunnel setup** via original Backhaul interactive menu
- **IP Spoof injection** into toml config files (Iran & Kharej)
- **Spoof support test** using Scapy (Sender & Listener modes)
- Service management (status, restart)

#### 4. Folder Encryption Manager
- Encrypt any folder using `gocryptfs`
- Lock/unlock folders at any time
- Instantly hide contents without dropping the tunnel
- Clear bash history and server logs

---

### 📦 Required Files

All files must be placed **next to the script**:

```
📁 Script Directory
├── wizard_toolkit.sh          ← Main script
├── x-ui-linux-amd64.tar.gz   ← For 3X-UI installation
├── x-ui.sh                   ← 3X-UI management menu
├── backhaul_premium           ← Backhaul binary
├── backhaul.sh                ← Backhaul management menu
└── scapy-2.7.0-py3-none-any.whl ← For Spoof testing
```

> **Note:** You only need the files relevant to the features you want to use.

---

### 🚀 Installation

Run this single command on your server — everything installs and launches automatically:

```bash
bash <(curl -s https://raw.githubusercontent.com/Graywiz4rd/wizard-toolkit/main/install.sh)
```

That's it! The toolkit downloads and launches immediately.

---

### ⚙️ Supported Systems

| OS | Status |
|----|--------|
| Ubuntu 24.04 LTS | ✅ Fully supported |
| Ubuntu 22.04 LTS | ✅ Fully supported |
| Ubuntu 20.04 LTS | ✅ Fully supported |
| Debian 11/12 | ⚠️ Not tested |

---

### 🔧 How Backhaul IP Spoof Works

The script automates a manual process:

1. After setting up the Backhaul tunnel, a `iran{PORT}.toml` or `kharej{PORT}.toml` config file is created
2. The script injects `spoof_src_ip` and `spoof_dst_ip` into the `[ipx]` section — right before the `interface` line
3. The Backhaul service is restarted automatically

Before using spoof, you can test if your servers support it using the built-in **Spoof Support Test** (Option 4 in Backhaul menu).

---

### 🔒 Folder Encryption Flow

```
Original Folder          Encrypted Vault
/root/backhaul-core  →  /root/.backhaul-core-encrypted
        ↓
   (empty after lock — tunnel still running)
        ↓
   gocryptfs unlock → contents visible again
```

---

### 📡 Contact

- **Telegram:** [@Gr4y_Wizard](https://t.me/Gr4y_Wizard)
- **Channel:** [t.me/Gray_wiz4rd](https://t.me/Gray_wiz4rd)

---

<div align="center">

*Crafted with ❤️ by @Gr4y_Wizard*

</div>
