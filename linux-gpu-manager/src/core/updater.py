import json
import urllib.request
import urllib.error
import logging
import os
import shutil
import tempfile
from src.config import AppConfig
from src.utils.command_runner import CommandRunner

class AppUpdater:
    def __init__(self):
        self.logger = logging.getLogger("AppUpdater")
        self.runner = CommandRunner()
        self.repo = AppConfig.GITHUB_REPO
        
    def check_for_updates(self):
        """
        GitHub API'yi kontrol eder.
        Dönüş: (has_update, latest_version, download_url, release_notes)
        """
        if not self.repo: 
             return False, None, None, None

        url = f"https://api.github.com/repos/{self.repo}/releases/latest"
        try:
            req = urllib.request.Request(url)
            req.add_header("User-Agent", f"{AppConfig.APP_NAME}-Updater")
            
            with urllib.request.urlopen(req, timeout=5) as r:
                data = json.loads(r.read().decode())
                
                latest_tag = data.get("tag_name", "").replace("v", "")
                current_ver = AppConfig.VERSION.replace("v", "")
                
                # Basit versiyon karşılaştırma (x.y.z)
                if self._compare_versions(latest_tag, current_ver) > 0:
                    # Güncelleme var
                    assets = data.get("assets", [])
                    deb_url = None
                    for asset in assets:
                        if asset.get("name", "").endswith(".deb"):
                            deb_url = asset.get("browser_download_url")
                            break
                            
                    return True, latest_tag, deb_url, data.get("body", "")
                    
        except Exception as e:
            self.logger.warning(f"Güncelleme kontrolü başarısız: {e}")
            
        return False, None, None, None

    def download_and_install(self, url, progress_callback=None):
        """
        URL'den .deb dosyasını indirir ve kurar.
        """
        try:
            # 1. İndirme
            self.logger.info(f"Güncelleme indiriliyor: {url}")
            if progress_callback: progress_callback("İndiriliyor...")
            
            fd, path = tempfile.mkstemp(suffix=".deb")
            os.close(fd) # Dosyayı kapat, urllib yazacak
            
            # İndirme işlemi
            with urllib.request.urlopen(url) as response, open(path, 'wb') as out_file:
                shutil.copyfileobj(response, out_file)
                
            self.logger.info("İndirme tamamlandı, kuruluma geçiliyor...")
            if progress_callback: progress_callback("Kuruluyor...")
            
            # 2. Kurulum
            # apt install ./dosya.deb (bağımlılıkları da çözer)
            cmd = f'pkexec ro-control-root-task "apt-get install -y {path}"'
            code, out, err = self.runner.run_full(cmd)
            
            # Geçici dosyayı sil
            os.remove(path)
            
            if code == 0:
                self.logger.info("Güncelleme başarıyla kuruldu.")
                return True
            else:
                self.logger.error(f"Kurulum hatası: {err}")
                return False
                
        except Exception as e:
            self.logger.error(f"Güncelleme işlemi başarısız: {e}")
            return False

    def _compare_versions(self, v1, v2):
        """v1 > v2 ise pozitif döner."""
        def normalize(v):
            return [int(x) for x in re.sub(r'(\.0+)*$','', v).split(".")]
        
        import re
        try:
            p1 = normalize(v1)
            p2 = normalize(v2)
            return (p1 > p2) - (p1 < p2)
        except:
            return 0
