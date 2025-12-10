class AppConfig:
    APP_NAME = "driver-pilot"
    PRETTY_NAME = "Driver Pilot"
    VERSION = "1.4.1"
    MAINTAINER = "Sopwith <sopwith.osdev@gmail.com>"
    DESCRIPTION = "Linux sistemleri için akıllı ekran kartı sürücüsü yöneticisi. NVIDIA ve AMD donanımlarını otomatik algılar, en uygun sürücüyü güvenle kurar ve yönetir."
    LICENSE = "GPL-3.0"
    
    CHANGELOG = """
    v1.4.1 Yenilikleri:
    - [YENİ] Tema Motoru: LibAdwaita ile tam uyumlu Aydınlık/Karanlık mod (anlık değişim).
    - [YENİ] Akıllı Arayüz: Sistem AMD ise sadece ilgili butonları göster (yanlış kurulumu önler).
    - [GELİŞTİRME] Hakkında Penceresi: Artık modern, açılır-kapanır (accordion) ve temiz.
    - [DÜZELTME] Performans Paneli: Sanal makinelerde CPU/RAM göstererek '0' sorunu çözüldü.
    - [DÜZELTME] Görsel Bütünlük: Tüm pencerelerde tek ve modern ikon kullanımı sağlandı.
    
    v1.4.0 Yenilikleri:
    - [YENİ] Performans Paneli: Canlı GPU Sıcaklığı, Yükü ve VRAM Kullanımı (NVIDIA).
    - [YENİ] Hybrid Grafik Yöneticisi: Laptoplar için NVIDIA/Intel/On-Demand geçişi (prime-select).
    - [YENİ] Oyun Modu: Feral GameMode yönetimi ve kurulumu.
    - [YENİ] Flatpak Onarıcı: Steam/Oyun izinlerini tek tuşla düzeltme.
    - [YENİ] Sekmeli Arayüz: Kurulum, Uzman ve Performans araçları ayrıldı.
    
    v1.3.0 Yenilikleri:
    - [YENİ] Modern Uygulama İkonu: Daha kaliteli ve şeffaf arka planlı yeni logo.
    - [YENİ] Tema Değiştirici: Sağ üst menüden Aydınlık/Karanlık mod geçişi eklendi.
    - [YENİ] Gelişmiş Hakkında: Geliştirici ve proje bilgileri güncellendi.
    - [GELİŞTİRME] Sürücü Listesi: Depolardan en güncel ve stabil sürümleri akıllı çekme özelliği.
    
    v1.2.0 Yenilikleri:
    - [YENİ] Oto-Tamir Sistemi: Eksik kütüphaneleri açılışta tespit eder ve onarır.
    - [YENİ] Akıllı GPU Tespiti: 'Unknown' GPU sorunu giderildi, sanal makine desteği eklendi.
    - [YENİ] Repo Taraması: Sürücü sürümleri artık apt-cache üzerinden canlı çekiliyor.
    - [DÜZELTME] GTK4 InfoBar uyumluluk sorunu giderildi.
    - [DÜZELTME] Uygulamanın sessiz kapanma (crash) sorunları çözüldü.
    """
    
    # URL = "" # Web siteniz yoksa boş bırakılabilir veya kaldırılabilir
    
    # Bağımlılıklar (Debian/Ubuntu isimleri)
    DEPENDENCIES = "python3, python3-gi, gir1.2-gtk-4.0"

    # E-posta
    DEVELOPER_EMAIL = "sopwith.osdev@gmail.com"
