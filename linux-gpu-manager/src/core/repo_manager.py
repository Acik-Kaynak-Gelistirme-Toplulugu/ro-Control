import logging
import subprocess
import shutil
import urllib.request
import json
import locale
from src.utils.command_runner import CommandRunner

class RepoManager:
    def __init__(self):
        self.logger = logging.getLogger("RepoManager")
        self.runner = CommandRunner()
        self.log_callback = None

    def set_logger_callback(self, callback):
        self.log_callback = callback

    def log(self, msg):
        self.logger.info(msg)
        if self.log_callback:
            self.log_callback(msg)

    def get_country_code(self):
        """
        Kullanıcının konumunu bulur (IP veya Sistem Dili üzerinden).
        Öncelik: IP -> Locale -> Varsayılan (us)
        """
        # 1. IP Tabanlı (En doğrusu)
        try:
            with urllib.request.urlopen("http://ip-api.com/json/", timeout=3) as url:
                data = json.loads(url.read().decode())
                return data.get("countryCode", "us").lower()
        except:
            pass

        # 2. Sistem Dili Tabanlı
        try:
            loc = locale.getdefaultlocale()[0]
            if loc and "_" in loc:
                return loc.split("_")[1].lower()
        except:
            pass
            
        return "us"

    def batch_optimize(self):
        """
        Tüm repo işlemlerini (Optimize + Standard Repos + Update) tek bir root yetkisiyle yapar.
        """
        if not shutil.which("apt-get"): return False
        
        cc = self.get_country_code()
        self.log(f"Konum tespit edildi: {cc.upper()}")
        
        # Komut Zinciri Oluştur
        chain = []
        
        # 1. Yedekle
        chain.append("cp /etc/apt/sources.list /etc/apt/sources.list.backup_dp")
        
        # 2. Optimize Et (sed)
        chain.append(rf"sed -i 's/http:\/\/archive.ubuntu.com\/ubuntu/http:\/\/{cc}.archive.ubuntu.com\/ubuntu/g' /etc/apt/sources.list")
        
        # 3. Yazılım Özellikleri Aracı (Eğer yoksa)
        if not shutil.which("add-apt-repository"):
             chain.append("apt-get install -y software-properties-common")
        
        # 4. Standart Depolar
        chain.append("add-apt-repository -y main restricted universe multiverse")
        
        # 5. Güncelleme
        chain.append("apt-get update")
        
        # Zinciri Birleştir
        full_cmd = " && ".join(chain)
        self.log(f"Toplu işlem başlatılıyor (Tek Şifre Girişi)...")
        self.log(f"En yakın ayna deneniyor: {cc.upper()}.archive.ubuntu.com")
        
        code, out, err = self.runner.run_full(f'pkexec ro-control-root-task "{full_cmd}"')
        
        if out: self.log(out)
        if err: self.log(f"İşlem çıktısı: {err}")
        
        if code != 0:
            self.log("UYARI: Yerel ayna yanıt vermedi veya hata oluştu!")
            self.log("Yedek (Ana) sunuculara geri dönülüyor...")
            
            # Kurtarma Zinciri
            # 1. Yedeği geri yükle
            # 2. Ana sunucuları (Main) kullan
            # 3. Tekrar güncelle
            
            rescue_chain = []
            rescue_chain.append("mv /etc/apt/sources.list.backup_dp /etc/apt/sources.list")
            rescue_chain.append("apt-get update")
            
            rescue_cmd = " && ".join(rescue_chain)
            
            code2, out2, err2 = self.runner.run_full(f'pkexec ro-control-root-task "{rescue_cmd}"')
            
            if code2 == 0:
                self.log("Başarılı: Ana sunuculara (Main Server) geçiş yapıldı.")
                return True
            else:
                 self.log(f"KRİTİK HATA: Ana sunuculara da erişilemedi! İnternet bağlantınızı kontrol edin. ({err2})")
                 return False
        
        self.log("Repo optimizasyonu ve güncelleme başarılı.")
        return True

    def optimize_sources(self):
        # Artık batch kullanıyoruz
        return self.batch_optimize()

    def ensure_standard_repos(self):
        return True # Batch içinde zaten yapılıyor

    def update_repos(self):
         return True # Batch içinde zaten yapılıyor
