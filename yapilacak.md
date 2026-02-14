# yapılacak.md — ro-Control v1.0.0 Post-Release İyileştirmeler

> Proje genelinde tespit edilen iyileştirmeler. Öncelik sırasına göre sıralanmıştır.

---

## P0 — Kritik (Güvenlik)

### 1. `scripts/ro-control-root-task` Güvenlik Sertleştirme
- **Durum:** `sh -c "$1"` ile gelen komutu doğrulama yapmadan root olarak çalıştırıyor
- **Çözüm:** Komut allowlist'i ekle — sadece bilinen komutlara (`dnf`, `dracut`, `grubby`, `rpm`, `modprobe`, vb.) izin ver
- **Dosya:** `scripts/ro-control-root-task`

---

## P1 — Yüksek Öncelik

### 2. Kullanılmayan Bağımlılıkları Kaldır
- **Durum:** `env_logger = "0.11"` ve `open = "5"` Cargo.toml'da var ama kodda kullanılmıyor
- **Çözüm:** Her iki bağımlılığı Cargo.toml'dan sil
- **Dosya:** `Cargo.toml`

### 3. Birim Testleri Ekle
- **Durum:** Proje genelinde hiçbir `#[test]` fonksiyonu yok
- **Çözüm:** `detector.rs`, `updater.rs`, `command.rs`, `i18n.rs` modüllerine temel testler ekle
- **Dosyalar:** `src/core/detector.rs`, `src/core/updater.rs`, `src/utils/command.rs`, `src/utils/i18n.rs`

---

## P2 — Orta Öncelik

### 4. `po/POTFILES.in` Dosya Yollarını Düzelt
- **Durum:** `src/ui/window.rs`, `src/ui/install_view.rs` gibi var olmayan dosyalara referans veriyor
- **Çözüm:** Doğru yollarla güncelle (`src/utils/i18n.rs`, QML dosyaları)
- **Dosya:** `po/POTFILES.in`

### 5. Metainfo URL'lerini Düzelt
- **Durum:** `<url>` etiketlerinde `ro-control` yazıyor, doğrusu `ro-Control`
- **Çözüm:** Tüm GitHub URL'lerinde büyük/küçük harf düzelt, screenshot `<image>` etiketlerini yorum satırından çıkar (geçici URL ile)
- **Dosya:** `data/io.github.AcikKaynakGelistirmeToplulugu.ro-control.metainfo.xml`

### 6. Dockerfile Güncelle
- **Durum:** `fedora:40` (EOL), dnf ile rust/cargo kurulumu (sürüm kontrolü yok), tek aşamalı build
- **Çözüm:** `fedora:42`'ye geç, rustup kullan, multi-stage build ekle, .dockerignore oluştur
- **Dosya:** `Dockerfile`

### 7. `rust-toolchain.toml` Sürüm Pinleme
- **Durum:** `channel = "stable"` yazıyor ama CI'da `1.88.0` pinli — tutarsızlık
- **Çözüm:** MSRV'yi belge olarak bırak, `channel = "stable"` yeterli (CI ayrıca pinler)
- **Dosya:** `rust-toolchain.toml` — yorum ekle

### 8. TODO Stub'ları Çöz
- **Durum:** `bridge.rs:180` — `is_version_compatible()` hep `true` döndürüyor; `ProgressPage.qml:220` — iptal mantığı yok
- **Çözüm:** Kernel uyumluluk kontrolü implementasyonu; cancel dialog'una gerçek iptal sinyali ekle
- **Dosyalar:** `src/bridge.rs`, `src/qml/pages/ProgressPage.qml`

---

## P3 — Düşük Öncelik (İyileştirme)

### 9. `.dockerignore` Dosyası Oluştur
- **Durum:** Build context gereksiz dosyaları (target/, .git/) içeriyor
- **Çözüm:** `.dockerignore` dosyası oluştur
- **Dosya:** `.dockerignore`

### 10. `SECURITY.md` Ekle
- **Durum:** Güvenlik açığı bildirme politikası yok
- **Çözüm:** Standart güvenlik politikası dosyası oluştur
- **Dosya:** `SECURITY.md`

### 11. Flatpak Manifest Güncelle  
- **Durum:** GSchema, symbolic ikon ve cleanup bölümü eksik
- **Çözüm:** `install` komutlarını genişlet
- **Dosya:** `packaging/flatpak/io.github.AcikKaynakGelistirmeToplulugu.ro-control.yml`

### 12. CI'ya MSRV Kontrol Job'u Ekle
- **Durum:** MSRV (1.82) ile derlenebilirlik test edilmiyor
- **Çözüm:** `ci.yml`'ye Rust 1.82.0 ile `cargo check` yapan yeni job ekle
- **Dosya:** `.github/workflows/ci.yml`

### 13. `config.rs` URL'lerini Düzelt
- **Durum:** `GITHUB_REPO`, `HOMEPAGE`, `ISSUE_URL` sabitleri `ro-control` kullanıyor, doğrusu `ro-Control`
- **Çözüm:** Tüm URL'leri düzelt
- **Dosya:** `src/config.rs`

---

## Tamamlananlar

- [x] CI/CD pipeline hataları düzeltildi (gcc, rpmbuild --nodeps)
- [x] v1.0.0 release yayınlandı (5 asset)
- [x] Release notes yazıldı
- [x] VERSIONS.md İngilizce'ye çevrildi
- [x] README ve dökümantasyon güncellendi
- [x] `scripts/ro-control-root-task` güvenlik sertleştirme (komut allowlist)
- [x] Kullanılmayan bağımlılıklar kaldırıldı (`env_logger`, `open`)
- [x] `po/POTFILES.in` dosya yolları düzeltildi
- [x] Metainfo URL'leri ve screenshot'lar düzeltildi
- [x] Dockerfile güncellendi (fedora:42, rustup, multi-stage)
- [x] `.dockerignore` oluşturuldu
- [x] `rust-toolchain.toml` belgelendi
- [x] TODO stub'ları çözüldü (`is_version_compatible`, cancel dialog)
- [x] `SECURITY.md` eklendi
- [x] Flatpak manifest güncellendi (GSchema, symbolic ikon, cleanup)
- [x] CI'ya MSRV (1.82) kontrol job'u eklendi
- [x] `config.rs` URL'leri düzeltildi (`ro-Control` casing)
- [x] Birim testleri eklendi (`updater`, `detector`, `command`, `i18n`)
