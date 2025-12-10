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

    def detect(self):
        """
        Tüm sistem taramasını başlatır.
        """
        self._detect_gpu_advanced()
        self._detect_active_driver()
        self._check_secure_boot()
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
                
                # Öncelik NVIDIA veya AMD'ye verilir, yoksa Intel
                if "NVIDIA" in vendor:
                    self.gpu_info["vendor"] = "NVIDIA"
                    self.gpu_info["model"] = device_name
                    break # Birincil GPU bulundu varsayıyoruz
                elif "Advanced Micro Devices" in vendor or "AMD" in vendor:
                    self.gpu_info["vendor"] = "AMD"
                    self.gpu_info["model"] = device_name
                    break
                elif "Intel" in vendor and self.gpu_info["vendor"] == "Unknown":
                    self.gpu_info["vendor"] = "Intel"
                    self.gpu_info["model"] = device_name

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