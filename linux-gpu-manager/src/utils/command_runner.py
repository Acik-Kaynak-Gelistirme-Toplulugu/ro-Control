import subprocess
import platform
import logging

class CommandRunner:
    def __init__(self):
        self.os_type = platform.system()
        self.logger = logging.getLogger("CommandRunner")

    def run(self, command):
        """
        Komutu çalıştırır. Eğer macOS üzerindeysek ve Linux'a özgü bir komutsa
        simüle edilmiş çıktı döndürür.
        """
        if self.os_type == "Darwin":
            return self._simulate_linux_output(command)
        
        try:
            result = subprocess.run(
                command, 
                shell=True, 
                check=True, 
                stdout=subprocess.PIPE, 
                stderr=subprocess.PIPE,
                text=True
            )
            return result.stdout.strip()
        except subprocess.CalledProcessError as e:
            # Bazı komutlar (örn: kontrol komutları) hata dönebilir, loglayıp None dönüyoruz
            self.logger.debug(f"Komut çalıştırılamadı: {command}. Hata: {e.stderr}")
            return None

    def _simulate_linux_output(self, command):
        """
        macOS üzerinde geliştirme yaparken Linux komutlarını taklit eder.
        """
        self.logger.info(f"[SIMULATION] Çalıştırılan komut: {command}")
        cmd_str = str(command)

        # 1. Advanced GPU Detection (lspci -vmm)
        if "lspci" in cmd_str and "-vmm" in cmd_str:
            return """Slot:\t01:00.0
Class:\tVGA compatible controller
Vendor:\tNVIDIA Corporation
Device:\tGeForce RTX 4060
SVendor:\tASUSTeK Computer Inc.
SDevice:\tDevice 88b8
Rev:\ta1

Slot:\t00:02.0
Class:\tVGA compatible controller
Vendor:\tIntel Corporation
Device:\tAlderLake-S GT1
"""

        # 2. Kernel Driver Check (lspci -k)
        if "lspci" in cmd_str and "-k" in cmd_str:
             return "\n01:00.0 VGA compatible controller: NVIDIA Corporation AD107 [GeForce RTX 4060]\n    Subsystem: ASUSTeK Computer Inc. Device 88b8\n    Kernel driver in use: nouveau\n    Kernel modules: nvidiafb, nouveau\n            "

        # 3. Secure Boot Check (mokutil)
        if "mokutil" in cmd_str:
            return "SecureBoot enabled"

        # 4. Auth & Install (pkexec)
        if "pkexec" in cmd_str:
            return "Success"
        
        # 5. Kernel Version
        if "uname -r" in cmd_str:
            return "6.5.0-14-generic"
        
        # 6. Ubuntu Drivers (Devices)
        if "ubuntu-drivers devices" in cmd_str:
            return """== /sys/devices/pci0000:00/0000:00:01.0/0000:01:00.0 ==
modalias : pci:v000010DEd00002882sv00001043sd000088B8bc03sc00i00
vendor   : NVIDIA Corporation
model    : AD107 [GeForce RTX 4060]
driver   : nvidia-driver-535 - distro non-free recommended
driver   : nvidia-driver-550 - distro non-free
driver   : nvidia-driver-535-open - distro non-free
driver   : nvidia-driver-470 - distro non-free
driver   : xserver-xorg-video-nouveau - distro free builtin
"""

        return ""
