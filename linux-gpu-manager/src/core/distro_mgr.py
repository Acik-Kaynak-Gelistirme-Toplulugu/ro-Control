
import platform

class DistroManager:
    def __init__(self):
        self.os_info = {
            "id": "unknown",
            "version": "unknown",
            "name": "Unknown OS"
        }

    def detect(self):
        """
        Dağıtım bilgilerini toplar. macOS üzerindeysek 'Ubuntu' taklidi yapar.
        Linux'ta ise /etc/os-release dosyasını okur (bağımlılık gerektirmez).
        """
        if platform.system() == "Darwin":
            # Geliştirme modu: Ubuntu 22.04 LTS gibi davran
            self.os_info = {
                "id": "ubuntu",
                "version": "22.04",
                "name": "Ubuntu 22.04.3 LTS"
            }
        else:
            # Standart Linux yöntemleri (distro kütüphanesi olmadan)
            info = {}
            try:
                with open("/etc/os-release") as f:
                    for line in f:
                        if "=" in line:
                            k, v = line.strip().split("=", 1)
                            info[k] = v.strip('"')
                
                self.os_info = {
                    "id": info.get("ID", "linux"),
                    "version": info.get("VERSION_ID", "unknown"),
                    "name": info.get("PRETTY_NAME", "Linux")
                }
            except Exception:
                self.os_info = {"id": "linux", "version": "unknown", "name": "Linux"}
        
        return self.os_info

    def get_package_manager(self):
        """
        Dağıtıma göre paket yöneticisi komutunu döndürür.
        """
        dist_id = self.os_info["id"]
        
        if dist_id in ["ubuntu", "debian", "linuxmint", "pop"]:
            return "apt"
        elif dist_id in ["fedora", "rhel", "centos"]:
            return "dnf"
        elif dist_id in ["arch", "manjaro", "endeavouros"]:
            return "pacman"
        elif dist_id in ["opensuse", "sles"]:
            return "zypper"
        else:
            return None
