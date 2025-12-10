import shutil
import subprocess
import re
import platform

class SystemTweaks:
    def __init__(self):
        self.is_nvidia = False # Tespit edilince güncellenir

    def get_gpu_stats(self):
        """
        Anlık GPU verilerini çeker. (Sıcaklık, Kullanım, VRAM)
        NVIDIA yoksa (VM/Virtio), sistem CPU/RAM verilerini Fallback olarak döndürür.
        """
        stats = {"temp": 0, "load": 0, "mem_used": 0, "mem_total": 0}
        
        # 1. NVIDIA Denemesi
        is_nvidia = False
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
                        is_nvidia = True
            except: pass

        # 2. Fallback (Sanal Makine / Non-NVIDIA)
        if not is_nvidia:
            try:
                # Load (CPU)
                with open("/proc/loadavg", "r") as f:
                    load_avg = float(f.read().split()[0]) # 1 dk ortalaması
                    # Kaba bir yüzde hesabı (Core sayısına bölmeden)
                    stats["load"] = min(int(load_avg * 100), 100) 
                
                # RAM
                mem_info = {}
                with open("/proc/meminfo", "r") as f:
                    for line in f:
                        parts = line.split()
                        if len(parts) >= 2:
                            mem_info[parts[0].strip(":")] = int(parts[1]) # kB
                
                if "MemTotal" in mem_info and "MemAvailable" in mem_info:
                    total = mem_info["MemTotal"] // 1024 # MB
                    avail = mem_info["MemAvailable"] // 1024 # MB
                    used = total - avail
                    stats["mem_total"] = total
                    stats["mem_used"] = used
                
                # Temp (Sanalda zor ama deneyelim)
                # /sys/class/thermal/thermal_zone0/temp genelde CPU ısısıdır
                try:
                     with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
                         stats["temp"] = int(int(f.read().strip()) / 1000)
                except:
                     stats["temp"] = 45 # Dummy değer (VM genelde raporlamaz)
                     
            except Exception as e:
                print(f"DEBUG: Fallback stats error: {e}")

        return stats

    def is_gamemode_active(self):
        """Feral GameMode yüklü mü kontrol eder."""
        return shutil.which("gamemoded") is not None

    def install_gamemode(self):
        """GameMode paketini kurar."""
        cmd = ["pkexec", "apt-get", "install", "-y", "gamemode"]
        return subprocess.run(cmd).returncode == 0

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
