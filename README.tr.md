<p align="center">
  <img src="data/icons/hicolor/scalable/apps/io.github.AcikKaynakGelistirmeToplulugu.ro-control.svg" width="128" height="128" alt="ro-Control">
</p>

<h1 align="center">ro-Control</h1>

<p align="center">
  <strong>Linux için Akıllı GPU Sürücü Yöneticisi</strong>
</p>

<p align="center">
  <a href="https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/releases"><img src="https://img.shields.io/github/v/release/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control?style=flat-square&color=blue" alt="Sürüm"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/lisans-GPL--3.0-green?style=flat-square" alt="Lisans"></a>
  <a href="https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/actions"><img src="https://img.shields.io/github/actions/workflow/status/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/ci.yml?style=flat-square&label=CI" alt="CI"></a>
  <img src="https://img.shields.io/badge/platform-Fedora%2040+-51A2DA?style=flat-square" alt="Fedora">
  <img src="https://img.shields.io/badge/rust-1.82+-orange?style=flat-square&logo=rust" alt="Rust">
</p>

<p align="center">
  <a href="#özellikler">Özellikler</a> •
  <a href="#kurulum">Kurulum</a> •
  <a href="#kaynak-koddan-derleme">Derleme</a> •
  <a href="#katkı">Katkı</a> •
  <a href="#lisans">Lisans</a>
</p>

<p align="center">
  <a href="README.md"><img src="https://img.shields.io/badge/README-English-blue?style=flat-square" alt="README in English"></a>
  <a href="README.tr.md"><img src="https://img.shields.io/badge/README-T%C3%BCrk%C3%A7e-red?style=flat-square" alt="README in Turkish"></a>
</p>

---

ro-Control, **Rust** ve **Qt6/QML** ([CXX-Qt](https://github.com/KDAB/cxx-qt)) ile geliştirilen, Fedora üzerinde NVIDIA GPU sürücü yönetimini kolaylaştıran yerel bir Linux masaüstü uygulamasıdır. PolicyKit entegrasyonu ile güvenli yetki yükseltme desteği sunar.

## Özellikler

### 🚀 Akıllı Sürücü Yönetimi

- **Hızlı Kurulum** — RPM Fusion (`akmod-nvidia`) ile tek tık NVIDIA sürücü kurulumu
- **Uzman Modu** — Proprietary ve Open Kernel modülleri arasında seçim
- **Derin Temizlik** — Eski sürücü kalıntılarını kaldırma
- **Secure Boot** — İmzalı/imzasız modül durumunu algılama ve uyarı

### 📊 Canlı Performans İzleme

- Gerçek zamanlı GPU sıcaklığı, yük ve VRAM kullanımı
- CPU yük ve sıcaklık takibi
- RAM kullanım takibi
- Renk kodlu ilerleme göstergeleri

### 🎮 Oyun Optimizasyonu

- **Feral GameMode** kurulumu ve yönetimi
- **Flatpak/Steam** izin onarım araçları

### 🖥 Görüntü Sunucusu

- **Wayland Düzeltmesi** — `nvidia-drm.modeset=1` parametresini kolay uygulama
- **Hibrit Grafik Profilleri** — NVIDIA/Intel/On-Demand geçiş desteği

### 🔄 Otomatik Güncelleme

- GitHub Releases üzerinden güncelleme kontrolü
- RPM paket indirip yükleme akışı

### 🌍 Çoklu Dil Desteği

- **17 dil desteği**: İngilizce, Türkçe, Almanca, İspanyolca, Fransızca, İtalyanca, Arapça, Japonca, Korece, Felemenkçe, Lehçe, Portekizce, Brezilya Portekizcesi, Rusça, Ukraynaca, Basitleştirilmiş Çince, Geleneksel Çince
- Otomatik sistem dili algılama ile sözlük tabanlı çeviri sistemi

## Kurulum

### Fedora (RPM)

En güncel `.rpm` dosyasını [Releases](https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/releases) sayfasından indirip kurabilirsiniz:

```bash
sudo dnf install ./ro-control-1.1.0-1.fc40.x86_64.rpm
```

### Kaynaktan

> **Rust ≥ 1.82 gereklidir.** Dağıtımınız eski sürüm içeriyorsa [rustup](https://rustup.rs/) ile kurun.

```bash
# Derleme bağımlılıklarını kur (Fedora 40+)
sudo dnf install cmake extra-cmake-modules gcc-c++ \
  kf6-qqc2-desktop-style \
  qt6-qtdeclarative-devel \
  qt6-qtbase-devel \
  qt6-qtwayland-devel

# Klonla ve derle
git clone https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control.git
cd ro-Control
cargo build --release

# Sistem genelinde kur
sudo make install
```

Detaylı derleme adımları için: [docs/BUILDING.md](docs/BUILDING.md)

## Kullanım

Uygulamayı menüden veya terminalden başlatabilirsiniz:

```bash
ro-control
```

> Not: Sürücü işlemleri PolicyKit üzerinden yönetici yetkisi gerektirir.

## Proje Yapısı

```text
ro-Control/
├── src/                    # Uygulama kaynak kodu
│   ├── main.rs             #   Giriş noktası: loglama, i18n, uygulama başlatma
│   ├── bridge.rs           #   CXX-Qt köprüsü (Rust ↔ QML)
│   ├── config.rs           #   Uygulama sabitleri
│   ├── core/               #   İş mantığı
│   │   ├── detector.rs     #     GPU/CPU/OS donanım algılama
│   │   ├── installer.rs    #     DNF tabanlı sürücü kurulum/kaldırma
│   │   ├── tweaks.rs       #     GPU istatistikleri, GameMode, Wayland düzeltme
│   │   └── updater.rs      #     GitHub Releases güncelleme kontrolü
│   ├── qml/                #   Qt Quick arayüz (Rust Edition)
│   │   ├── Main.qml        #     Uygulama penceresi, kenar çubuğu, StatusBar
│   │   ├── Theme.qml       #     Renk paleti singleton
│   │   ├── pages/          #     Install, Expert, Perf, Progress
│   │   └── components/     #     ActionCard, CustomProgressBar,
│   │                       #     GradientButton, StatusBar, StepItem
│   └── utils/              #   Yardımcı modüller
│       ├── command.rs      #     Kabuk komut çalıştırıcı
│       ├── i18n.rs         #     Çoklu dil çeviri sistemi (17 dil)
│       └── logger.rs       #     simplelog yapılandırması
├── data/                   # FreeDesktop veri dosyaları
├── packaging/              # RPM/Flatpak paketleme dosyaları
├── scripts/                # Yardımcı scriptler (pkexec wrapper)
├── po/                     # Çeviri dosyaları
├── docs/                   # Dokümantasyon
├── .github/                # CI/CD iş akışları
├── Cargo.toml              # Proje manifesto
├── Makefile                # Derleme/kurulum hedefleri
├── CHANGELOG.md            # Sürüm geçmişi
└── CONTRIBUTING.md         # Katkı rehberi
```

## Katkı

Katkılarınızı memnuniyetle karşılıyoruz. Pull request açmadan önce lütfen [CONTRIBUTING.md](CONTRIBUTING.md) dosyasını inceleyin.

## Lisans

Bu proje [GPL-3.0](LICENSE) lisansı ile dağıtılmaktadır.
