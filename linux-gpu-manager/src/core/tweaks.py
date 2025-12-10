import shutil
import subprocess
import re
import platform

class SystemTweaks:
    def __init__(self):
        self.is_nvidia = False # Tespit edilince güncellenir

    def get_gpu_stats(self):
        """
        NVIDIA GPU verilerini çeker.
        """
        stats = {"temp": 0, "load": 0, "mem_used": 0, "mem_total": 0}
        
        if shutil.which("nvidia-smi"):
            try:
                res = subprocess.run(
                    ["nvidia-smi", "--query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total", "--format=csv,noheader,nounits"],
                    capture_output=True, text=True
                )
                if res.returncode == 0:
                    parts = res.stdout.strip().split(', ')
                    if len(parts) >= 4:
                        stats["temp"] = int(parts[0])
                        stats["load"] = int(parts[1])
                        stats["mem_used"] = int(parts[2])
                        stats["mem_total"] = int(parts[3])
                        return stats
            except: pass
        
        # Eğer NVIDIA bulunamazsa boş döner (Veya mock dönebiliriz)
        # Önceki fallback mantığını get_system_stats'a taşıyoruz.
        return stats

    def get_system_stats(self):
        """
        Genel Sistem kaynak kullanımını (CPU, RAM, Temp) çeker.
        """
        sys_stats = {"cpu_load": 0, "ram_used": 0, "ram_total": 0, "ram_percent": 0, "cpu_temp": 0}
        
        try:
            # CPU Load (Basit ortalama)
            with open("/proc/loadavg", "r") as f:
                # 1 dakikalık ortalama yük / Core sayısı tahmini (Basitleştirilmiş)
                # Tam yüzde için psutil gerekir ama stdlib kullanıyoruz
                # multiprocessing.cpu_count() ile core sayısını alıp bölebiliriz
                import multiprocessing
                load_avg = float(f.read().split()[0])
                cores = multiprocessing.cpu_count()
                percent = (load_avg / cores) * 100
                sys_stats["cpu_load"] = min(int(percent), 100)

            # RAM
            mem_info = {}
            with open("/proc/meminfo", "r") as f:
                for line in f:
                    parts = line.split()
                    if len(parts) >= 2:
                        mem_info[parts[0].strip(":")] = int(parts[1]) # kB

            if "MemTotal" in mem_info and "MemAvailable" in mem_info:
                total_mb = mem_info["MemTotal"] // 1024
                avail_mb = mem_info["MemAvailable"] // 1024
                used_mb = total_mb - avail_mb
                sys_stats["ram_total"] = total_mb
                sys_stats["ram_used"] = used_mb
                sys_stats["ram_percent"] = int((used_mb / total_mb) * 100)

            # CPU Temp
            try:
                # Yaygın thermal zone (x86)
                with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
                    sys_stats["cpu_temp"] = int(int(f.read().strip()) / 1000)
            except:
                sys_stats["cpu_temp"] = 0 # Okunamazsa 0
                
        except Exception:
            pass
            
        return sys_stats

    def is_gamemode_active(self):
        """Feral GameMode yüklü mü kontrol eder."""
        return shutil.which("gamemoded") is not None

    def install_gamemode(self):
        """GameMode paketini kurar."""
        cmd = ["pkexec", "apt-get", "install", "-y", "gamemode"]
        return subprocess.run(cmd).returncode == 0

    def is_prime_supported(self):
        """Sistemin NVIDIA Prime (Hybrid Graphics) destekleyip desteklemediğini kontrol eder."""
        return shutil.which("prime-select") is not None

    def get_prime_profile(self):
        """Mevcut Hybrid Graphics modunu döndürür (nvidia/intel/on-demand)."""
        if not shutil.which("prime-select"):
            return "unknown"
        res = subprocess.run(["prime-select", "query"], capture_output=True, text=True)
        return res.stdout.strip()

    def set_prime_profile(self, profile):
        """Hybrid modunu değiştirir (Reboot gerekir)."""
        # profile: nvidia, intel, on-demand
        cmd = ["pkexec", "prime-select", profile]
        return subprocess.run(cmd).returncode == 0

    def repair_flatpak_permissions(self):
        """Flatpak NVIDIA runtime izinlerini düzeltmeye çalışır."""
        # Basitçe update ve repair dener
        cmds = [
            "flatpak update -y",
            "flatpak repair"
        ]
        success = True
        for c in cmds:
            if subprocess.run(f"pkexec {c}", shell=True).returncode != 0:
                success = False
        return success
