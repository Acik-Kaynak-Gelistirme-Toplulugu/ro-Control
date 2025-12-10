import shutil
import subprocess
import sys
import logging

class DependencyManager:
    @staticmethod
    def check_and_fix():
        """
        Kritik bağımlılıkları kontrol eder ve eksikse pkexec ile kurmaya çalışır.
        """
        missing_pkgs = []
        
        # 1. Python GObject ve GTK4 Typelib
        try:
            import gi
            try:
                gi.require_version('Gtk', '4.0')
                from gi.repository import Gtk
                print("DEBUG: GTK 4.0 bulundu.")
            except (ValueError, ImportError):
                print("DEBUG: GTK 4.0 bulunamadı, kurulum listesine ekleniyor.")
                missing_pkgs.append("gir1.2-gtk-4.0")
                missing_pkgs.append("gir1.2-adw-1") # Adwaita da ekleyelim, modern görünüm için
        except ImportError:
            print("DEBUG: 'gi' modülü bulunamadı, kurulum listesine ekleniyor.")
            missing_pkgs.append("python3-gi")
            missing_pkgs.append("gir1.2-gtk-4.0")
            missing_pkgs.append("gir1.2-adw-1")

        # 2. Lspci (Donanım tarama için şart)
        if not shutil.which("lspci"):
            print("DEBUG: 'lspci' bulunamadı, kurulum listesine ekleniyor.")
            missing_pkgs.append("pciutils")

        # Eksik varsa kur
        if missing_pkgs:
            print(f"DEBUG: Tespit edilen eksikler: {missing_pkgs}")
            DependencyManager._install_packages(missing_pkgs)
        else:
            print("DEBUG: Tüm kritik bağımlılıklar tam.")

    @staticmethod
    def _install_packages(packages):
        print("DEBUG: Eksik paketler için yetki isteniyor...")
        try:
            # Kullanıcıdan grafiksel şifre isteyerek paketleri kur
            # 'bash -c' kullanarak komut zinciri oluşturuyoruz
            pkgs_str = " ".join(packages)
            cmd = [
                "pkexec", "bash", "-c",
                f"apt-get update && apt-get install -y {pkgs_str}"
            ]
            
            subprocess.run(cmd, check=True)
            print("DEBUG: Paketler başarıyla kuruldu.")
            
        except subprocess.CalledProcessError as e:
            print(f"CRITICAL: Paket kurulumu başarısız oldu veya iptal edildi: {e}")
            # Yine de devam etmeyi dene, belki kullanıcı manuel kurmuştur.
        except Exception as e:
            print(f"CRITICAL: Beklenmeyen hata: {e}")
