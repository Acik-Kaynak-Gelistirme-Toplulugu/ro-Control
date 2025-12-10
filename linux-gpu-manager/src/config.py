class AppConfig:
    APP_NAME = "ro-control"
    PRETTY_NAME = "ro-Control"
    VERSION = "1.0.0"
    MAINTAINER = "Sopwith <sopwith.osdev@gmail.com>"
    DESCRIPTION = "Smart graphics driver manager for Linux systems. Automatically detects NVIDIA and AMD hardware, securely installs the optimal drivers, and manages configuration."
    LICENSE = "GPL-3.0"
    
    # Güncelleme için GitHub Repo (user/repo formatında)
    GITHUB_REPO = "Acik-Kaynak-Gelistirme-Toplulugu/ro-Control"
    
    CHANGELOG = """
    v1.0.0 (GitHub Release) Yenilikleri:
    - [YENİ] Hızlı Kurulum Sihirbazı: Donanımı analiz edip tek tıkla en doğru sürücüyü kuran akıllı mod.
    - [YENİ] Mux Switch Koruması: Desteklenmeyen cihazlarda Hybrid Grafik ayarlarını otomatik devre dışı bırakma.
    - [YENİ] Sistem Dedektifi: Kurulum öncesi ve sırasında detaylı donanım/yazılım analizi ve loglama.
    - [GELİŞTİRME] Arayüz Sadeleşmesi: Karmaşık 'Uzman' sekmeleri gizlendi, sadece ihtiyaç anında açılır.
    - [GELİŞTİRME] Performans Monitörü: GPU verilerinin yanına canlı CPU ve RAM istatistikleri eklendi.
    - [DÜZELTME] GTK4 Kararlılık: Diyalog pencerelerindeki çökme sorunları ve başlatma hataları giderildi.

    v0.5.1 (Beta) Yenilikleri:
    - [YENİ] Tema Motoru: LibAdwaita ile tam uyumlu Aydınlık/Karanlık mod (anlık değişim).
    - [YENİ] Akıllı Arayüz: Sistem AMD ise sadece ilgili butonları göster (yanlış kurulumu önler).
    - [GELİŞTİRME] Hakkında Penceresi: Artık modern, açılır-kapanır (accordion) ve temiz.
    - [DÜZELTME] Performans Paneli: Sanal makinelerde CPU/RAM göstererek '0' sorunu çözüldü.
    - [DÜZELTME] Görsel Bütünlük: Tüm pencerelerde tek ve modern ikon kullanımı sağlandı.
    
    v0.5.0 (Beta) Yenilikleri:
    - [YENİ] Performans Paneli: Canlı GPU Sıcaklığı, Yükü ve VRAM Kullanımı (NVIDIA).
    - [YENİ] Hybrid Grafik Yöneticisi: Laptoplar için NVIDIA/Intel/On-Demand geçişi (prime-select).
    - [YENİ] Oyun Modu: Feral GameMode yönetimi ve kurulumu.
    - [YENİ] Flatpak Onarıcı: Steam/Oyun izinlerini tek tuşla düzeltme.
    - [YENİ] Sekmeli Arayüz: Kurulum, Uzman ve Performans araçları ayrıldı.
    
    v0.4.0 (Alpha) Yenilikleri:
    - [YENİ] Modern Uygulama İkonu: Daha kaliteli ve şeffaf arka planlı yeni logo.
    - [YENİ] Tema Değiştirici: Sağ üst menüden Aydınlık/Karanlık mod geçişi eklendi.
    - [YENİ] Gelişmiş Hakkında: Geliştirici ve proje bilgileri güncellendi.
    - [GELİŞTİRME] Sürücü Listesi: Depolardan en güncel ve stabil sürümleri akıllı çekme özelliği.
    
    v0.3.0 (Alpha) Yenilikleri:
    - [YENİ] Oto-Tamir Sistemi: Eksik kütüphaneleri açılışta tespit eder ve onarır.
    - [YENİ] Akıllı GPU Tespiti: 'Unknown' GPU sorunu giderildi, sanal makine desteği eklendi.
    - [YENİ] Repo Taraması: Sürücü sürümleri artık apt-cache üzerinden canlı çekiliyor.
    - [DÜZELTME] GTK4 InfoBar uyumluluk sorunu giderildi.
    - [DÜZELTME] Uygulamanın sessiz kapanma (crash) sorunları çözüldü.
    """
    
    # URL = "" # Web siteniz yoksa boş bırakılabilir veya kaldırılabilir
    
    # Bağımlılıklar (Debian/Ubuntu isimleri)
    DEPENDENCIES = "python3, python3-gi, gir1.2-gtk-4.0"

    # E-posta - DEPRECATED (GitHub Issues kullanılır)
    # DEVELOPER_EMAIL = ""
