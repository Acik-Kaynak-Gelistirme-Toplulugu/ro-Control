
class AppConfig:
    APP_NAME = "driver-pilot"
    PRETTY_NAME = "Driver Pilot"
    VERSION = "1.1.0"
    MAINTAINER = "Sopwith <sopwith.osdev@gmail.com>"
    DESCRIPTION = "Linux sistemleri için akıllı ekran kartı sürücüsü yöneticisi. NVIDIA ve AMD donanımlarını otomatik algılar, en uygun sürücüyü güvenle kurar ve yönetir."
    LICENSE = "GPL-3.0"
    LICENSE = "GPL-3.0"
    # URL = "" # Web siteniz yoksa boş bırakılabilir veya kaldırılabilir
    
    # Bağımlılıklar (Debian/Ubuntu isimleri)
    DEPENDENCIES = "python3, python3-venv, python3-gi, gir1.2-gtk-4.0, gir1.2-adw-1, policykit-1, pciutils, mokutil"

    # E-posta
    DEVELOPER_EMAIL = "sopwith.osdev@gmail.com"
