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

    def optimize_sources(self):
        """
        sources.list dosyasını en yakın sunucuya yönlendirir.
        """
        if not shutil.which("apt-get"):
            return False 
            
        cc = self.get_country_code()
        self.logger.info(f"Konum tespit edildi: {cc.upper()}")
        
        # Komutları zincirle
        cmds = []
        cmds.append("cp /etc/apt/sources.list /etc/apt/sources.list.backup_dp")
        cmds.append(f"sed -i 's/http:\/\/archive.ubuntu.com\/ubuntu/http:\/\/{cc}.archive.ubuntu.com\/ubuntu/g' /etc/apt/sources.list")
        
        full_cmd = " && ".join(cmds)
        # Wrapper kullan
        return self.runner.run(f'pkexec driver-pilot-root-task "{full_cmd}"')

    def ensure_standard_repos(self):
        """
        Ubuntu'nun resmi depolarını (Main, Restricted, Universe, Multiverse) aktif eder.
        Sürücüler genelde 'restricted' deposunda bulunur.
        """
        if not shutil.which("add-apt-repository"):
            self.runner.run('pkexec driver-pilot-root-task "apt-get install -y software-properties-common"')
            
        self.logger.info("Resmi Ubuntu depoları (Restricted/Multiverse) kontrol ediliyor...")
        # Tek komutla hepsini garantile
        return self.runner.run('pkexec driver-pilot-root-task "add-apt-repository -y main restricted universe multiverse"')

    def fix_gamemode_repo(self):
        """
        GameMode için Universe deposu gerekir (Yukarıdaki işlem bunu zaten kapsar ama yedek olsun).
        """
        # ensure_standard_repos zaten universe'ü kapsıyor, sadece update yapalım
        self.runner.run(f'pkexec driver-pilot-root-task "apt-get update"')
