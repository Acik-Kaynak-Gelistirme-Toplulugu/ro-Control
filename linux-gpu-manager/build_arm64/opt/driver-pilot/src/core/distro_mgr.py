import distro
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
        """
        if platform.system() == "Darwin":
            # Geliştirme modu: Ubuntu 22.04 LTS gibi davran
            self.os_info = {
                "id": "ubuntu",
                "version": "22.04",
                "name": "Ubuntu 22.04.3 LTS"
            }
        else:
            self.os_info = {
                "id": distro.id(),
                "version": distro.version(),
                "name": distro.name(pretty=True)
            }
        
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
