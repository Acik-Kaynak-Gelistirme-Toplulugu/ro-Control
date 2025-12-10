import re
import shutil
import platform
from src.utils.command_runner import CommandRunner

class SystemDetector:
    def __init__(self):
        self.runner = CommandRunner()
        self.gpu_info = {
            "vendor": "Unknown",
            "model": "Unknown",
            "driver_in_use": "Unknown",
            "secure_boot": False
        }
        self._is_detected = False

    def detect(self, force_refresh=False):
        """
        Tüm sistem taramasını başlatır.
        Önbellek (Cache) mekanizması ile gereksiz exec çağrılarını önler.
        """
        if self._is_detected and not force_refresh:
            return self.gpu_info

        self._detect_gpu_advanced()
        self._detect_active_driver()
        self._check_secure_boot()
        self._is_detected = True
        return self.gpu_info

    def _detect_gpu_advanced(self):
        """
        lspci -vmm formatını kullanarak daha hassas tespit yapar.
        """
        # macOS simülasyonu
        if platform.system() == "Darwin":
            self.gpu_info["vendor"] = "NVIDIA"
            self.gpu_info["model"] = "GeForce RTX 4060 (Simulated)"
            return

        if not shutil.which("lspci"):
            self.gpu_info["model"] = "lspci not found"
            return

        # -vmm: Machine readable, verbose
        output = self.runner.run("lspci -vmm")
        if not output:
            return

        devices = output.split("\n\n")
        
        for device in devices:
            if "VGA" in device or "3D controller" in device or "Display controller" in device:
                details = {}
                for line in device.split("\n"):
                    if ":" in line:
                        key, val = line.split(":", 1)
                        details[key.strip()] = val.strip()
                
                vendor = details.get("Vendor", "")
                device_name = details.get("Device", "")
                
                # Her halükarda bir aday olarak sakla (Fallback)
                if self.gpu_info["vendor"] == "Unknown":
                    self.gpu_info["vendor"] = vendor
                    self.gpu_info["model"] = device_name

                # Özel markaları tara
                if "NVIDIA" in vendor:
                    self.gpu_info["vendor"] = "NVIDIA"
                    self.gpu_info["model"] = device_name
                    break 
                elif "Advanced Micro Devices" in vendor or "AMD" in vendor:
                    self.gpu_info["vendor"] = "AMD"
                    self.gpu_info["model"] = device_name
                    break
                elif "Intel" in vendor:
                    self.gpu_info["vendor"] = "Intel"
                    self.gpu_info["model"] = device_name
                    break
        
        # Hala Unknown ise varsayılan düzgün bir isim ver
        if self.gpu_info["vendor"] in ["Unknown", ""]:
             self.gpu_info["vendor"] = "Sistem"
             self.gpu_info["model"] = "Grafik Bağdaştırıcısı"

    def _detect_active_driver(self):
        if platform.system() == "Darwin":
            self.gpu_info["driver_in_use"] = "nouveau (Simulated)"
            return

        # lspci -k ile kullanılan kernel modülünü bul
        output = self.runner.run("lspci -k")
        if not output:
            return

        # Şu anki GPU'yu bulmak için lspci çıktısını satır satır tarıyoruz
        # Basitçe 'Kernel driver in use' satırını VGA cihazı bağlamında arıyoruz
        # Daha karmaşık sistemlerde busID kontrolü gerekebilir.
        lines = output.split('\n')
        capture_next = False
        
        for line in lines:
            if "VGA" in line or "3D controller" in line:
                # Eğer tespit ettiğimiz vendor bu satırda geçiyorsa veya genel arama
                capture_next = True
            
            if capture_next and "Kernel driver in use:" in line:
                parts = line.split(":")
                if len(parts) > 1:
                    self.gpu_info["driver_in_use"] = parts[1].strip()
                    break

    def _check_secure_boot(self):
        """
        Secure Boot durumunu kontrol eder.
        Ubuntu/Debian/Fedora için 'mokutil' kullanılır.
        """
        if platform.system() == "Darwin":
            self.gpu_info["secure_boot"] = False # macOS dev ortamı
            return

        if not shutil.which("mokutil"):
            # mokutil yoksa durumu bilemeyiz, False varsayalım ama loglanabilir.
            return

        try:
            output = self.runner.run("mokutil --sb-state")
            if output and "SecureBoot enabled" in output:
                self.gpu_info["secure_boot"] = True
            else:
                self.gpu_info["secure_boot"] = False
        except:
            self.gpu_info["secure_boot"] = False

    def get_full_system_info(self):
        """
        GPU, CPU, RAM, OS ve Kernel bilgilerini içeren kapsamlı bir sözlük döndürür.
        """
        if not self._is_detected:
            self.detect()
            
        sys_info = self.gpu_info.copy()
        
        # CPU Info
        sys_info["cpu"] = self._get_cpu_info()
        
        # RAM Info
        sys_info["ram"] = self._get_ram_info()
        
        # OS & Kernel
        sys_info["distro"] = self._get_distro_info()
        sys_info["kernel"] = platform.release()
        
        return sys_info

    def _get_cpu_info(self):
        if platform.system() == "Darwin": return "Apple Silicon (M-Series)"
        
        try:
            # lscpu veya /proc/cpuinfo
            out = self.runner.run("grep -m1 'model name' /proc/cpuinfo")
            if out:
                return out.split(":", 1)[1].strip()
        except: pass
        return platform.processor()

    def _get_ram_info(self):
        if platform.system() == "Darwin": return "16 GB (Simulated)"
        
        try:
            # LC_ALL=C ensures 'Mem:' label regardless of system language
            out = self.runner.run("LC_ALL=C free -h")
            if out:
                lines = out.split("\n")
                for line in lines:
                    if line.startswith("Mem:") or "Mem:" in line:
                        parts = line.split()
                        # Mem: Total Used ... (Index 1 is Total)
                        # But sometimes split behaves differently on spaces
                        # free output:
                        #               total        used        free      shared  buff/cache   available
                        # Mem:           15Gi       3.2Gi        11Gi       1.0Mi       856Mi        11Gi
                        # If "Mem:" is part[0], then part[1] is total.
                        if parts[0].startswith("Mem"):
                             return parts[1]
                        # Handling verify
                        for i, p in enumerate(parts):
                             if "Mem" in p and i+1 < len(parts):
                                  return parts[i+1]
        except: pass
        return "Unknown"

    def _get_distro_info(self):
        if platform.system() == "Darwin": return "macOS"
        
        try:
            # /etc/os-release
            out = self.runner.run("cat /etc/os-release")
            if out:
                name = re.search(r'PRETTY_NAME="(.*)"', out)
                if name: return name.group(1)
        except: pass
        return "Linux"