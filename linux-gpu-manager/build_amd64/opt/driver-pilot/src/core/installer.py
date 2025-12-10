import logging
import platform
import re
import datetime
from src.core.distro_mgr import DistroManager
from src.utils.command_runner import CommandRunner

class DriverInstaller:
    def __init__(self):
        self.logger = logging.getLogger("DriverInstaller")
        self.distro_mgr = DistroManager()
        self.runner = CommandRunner()
        self.os_info = self.distro_mgr.detect()
        self.pkg_manager = self.distro_mgr.get_package_manager()
        self.is_macos = platform.system() == "Darwin"

    def get_available_versions(self):
        versions = []
        if self.is_macos:
            return ["550", "535", "470"]

        if self.pkg_manager == "apt":
            # 1. Yöntem: ubuntu-drivers (En sağlıklısı)
            output = self.runner.run("ubuntu-drivers devices") or ""
            if output:
                matches = re.findall(r'nvidia-driver-(\d+)', output)
                if matches:
                     versions = sorted(list(set(matches)), key=lambda x: int(x), reverse=True)
            
            # 2. Yöntem: Depodan Çekme (apt-cache) - İnternet/Repo bazlı
            if not versions:
                try:
                    # Depodaki tüm nvidia-driver-XXX paketlerini listele
                    raw_out = self.runner.run("apt-cache search ^nvidia-driver-[0-9]+$")
                    if raw_out:
                        matches = re.findall(r'nvidia-driver-(\d+)', raw_out)
                        # Sadece mantıklı olanları al (örn: >300)
                        valid_vers = [v for v in set(matches) if len(v) >= 3 and int(v) > 300]
                        versions = sorted(valid_vers, key=lambda x: int(x), reverse=True)
                except Exception:
                    pass

        # Hiçbir şey bulunamazsa güvenli varsayılanlar
        return versions if versions else ["550", "535", "470", "390"] 

    def install_nvidia_closed(self, version=None):
        self.logger.info(f"Kapalı Kaynak NVIDIA kurulumu (Ver: {version or 'Auto'})...")
        commands = self._prepare_install_chain()
        
        # 1. Paket Kurulumları
        if self.pkg_manager == "apt":
            if version:
                commands.append(f"apt-get install -y nvidia-driver-{version} nvidia-settings")
            else:
                commands.append("ubuntu-drivers autoinstall")
        elif self.pkg_manager == "dnf":
            commands.append("dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda")
        elif self.pkg_manager == "pacman":
            commands.append("pacman -Sy --noconfirm nvidia nvidia-utils nvidia-settings")
        elif self.pkg_manager == "zypper":
            commands.append("zypper install -y nvidia-glG05")

        # 2. Son İşlemler (Blacklist & Initramfs)
        commands.extend(self._finalize_installation_chain())
        
        return self._execute_transaction_bulk(commands)

    def install_nvidia_open(self, version=None):
        version = version or "535"
        self.logger.info(f"Açık Kaynak NVIDIA (Open Kernel) kurulumu (Ver: {version})...")
        commands = self._prepare_install_chain()
        
        if self.pkg_manager == "apt":
            pkg_name = f"nvidia-driver-{version}-open"
            commands.append(f"apt-get install -y {pkg_name} nvidia-settings")
        elif self.pkg_manager == "dnf":
            commands.append("dnf install -y akmod-nvidia-open")
        elif self.pkg_manager == "pacman":
            commands.append("pacman -Sy --noconfirm nvidia-open nvidia-utils")

        commands.extend(self._finalize_installation_chain())
        return self._execute_transaction_bulk(commands)

    def create_timeshift_snapshot(self, comment="Driver Pilot Otomatik Yedek"):
        """Timeshift ile sistem yedeği oluşturur."""
        import shutil
        if not shutil.which("timeshift"):
            self.logger.warning("Timeshift yüklü değil, yedek alınamıyor.")
            return False
            
        self.logger.info("Timeshift yedeği oluşturuluyor...")
        # --create --comments "..." --tags D
        cmd = f'pkexec timeshift --create --comments "{comment}" --tags D'
        return self.runner.run(cmd) is not None

    def remove_nvidia(self, deep_clean=True):
        self.logger.info("NVIDIA sürücü kaldırma işlemi...")
        commands = self._backup_config_commands()

        # Blacklist dosyasını temizle
        commands.append("rm -f /etc/modprobe.d/blacklist-nouveau.conf")
        
        # Derin Temizlik: Artık konfigürasyon dosyalarını sil
        if deep_clean:
            commands.append("rm -f /etc/X11/xorg.conf")
            commands.append("rm -f /etc/modprobe.d/nvidia*")
            commands.append("rm -f /etc/modules-load.d/nvidia*")

        if self.pkg_manager == "apt":
            commands.append("apt-get remove --purge -y '^nvidia-.*'")
            commands.append("apt-get autoremove -y")
            commands.append("apt-get install -y xserver-xorg-video-nouveau")
        elif self.pkg_manager == "dnf":
            commands.append("dnf remove -y '*nvidia*'")
        elif self.pkg_manager == "pacman":
            commands.append("pacman -Rs --noconfirm nvidia nvidia-utils nvidia-settings nvidia-open")

        # Initramfs güncelle (Nouveau'yu geri yüklemek için)
        commands.extend(self._update_initramfs_commands())

        return self._execute_transaction_bulk(commands)

    def install_amd_open(self):
        """AMD Açık Kaynak (Mesa) kurulumu/güncellemesi."""
        self.logger.info("AMD Open (Mesa) kurulumu/güncellemesi...")
        commands = self._prepare_install_chain()
        
        if self.pkg_manager == "apt":
            commands.append("apt-get install -y xserver-xorg-video-amdgpu mesa-vulkan-drivers mesa-utils")
        elif self.pkg_manager == "dnf":
            commands.append("dnf install -y xorg-x11-drv-amdgpu mesa-dri-drivers mesa-vulkan-drivers")
        elif self.pkg_manager == "pacman":
            commands.append("pacman -Sy --noconfirm xf86-video-amdgpu mesa vulkan-radeon")
            
        return self._execute_transaction_bulk(commands)

    def install_amd_closed(self):
        """
        AMD Pro sürücüleri karmaşıktır ve genelde script ile kurulur (amdgpu-pro-install).
        Şu anlık desteklemiyoruz.
        """
        self.logger.warning("AMD Pro sürücü kurulumu henüz desteklenmiyor.")
        return False

    def remove_all_drivers(self):
        """Fabrika Ayarlarına Dön: Tüm özel sürücüleri kaldır."""
        self.logger.info("Tüm sürücüler kaldırılıyor (Fabrika Ayarları)...")
        # Önce NVIDIA temizle
        self.remove_nvidia()
        
        # AMD Pro varsa temizle (Basitçe)
        if self.pkg_manager == "apt":
            self.runner.run("pkexec apt-get remove --purge -y amdgpu-pro*")
        
        # Xorg config temizle
        self.runner.run("pkexec rm -f /etc/X11/xorg.conf")
        return True

    def _prepare_install_chain(self):
        """Hazırlık: Yedekleme + Build Tools + Blacklist Oluşturma"""
        chain = []
        chain.extend(self._backup_config_commands())
        
        # Blacklist Nouveau (Garanti Yöntem)
        # echo komutu tek tırnak içinde sorun çıkarabilir, printf daha güvenli veya bash -c içinde hallediyoruz.
        blacklist_content = "blacklist nouveau\noptions nouveau modeset=0"
        chain.append(f"printf '{blacklist_content}' > /etc/modprobe.d/blacklist-nouveau.conf")
        
        # Build Dependencies
        if self.pkg_manager == "apt":
            chain.append("apt-get update")
            chain.append("apt-get install -y build-essential linux-headers-$(uname -r)")
        elif self.pkg_manager == "dnf":
            chain.append("dnf install -y kernel-devel kernel-headers gcc make")
        elif self.pkg_manager == "pacman":
            chain.append("pacman -Sy --noconfirm base-devel linux-headers")
            
        return chain

    def _finalize_installation_chain(self):
        """Kurulum sonrası sistemi boot'a hazırlama (Initramfs)"""
        return self._update_initramfs_commands()

    def _update_initramfs_commands(self):
        cmds = []
        if self.pkg_manager == "apt":
            cmds.append("update-initramfs -u")
        elif self.pkg_manager == "dnf":
            cmds.append("dracut --force")
        elif self.pkg_manager == "pacman":
            cmds.append("mkinitcpio -P")
        elif self.pkg_manager == "zypper":
            cmds.append("mkinitrd")
        return cmds

    def _backup_config_commands(self):
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        return [f"[ -f /etc/X11/xorg.conf ] && cp /etc/X11/xorg.conf /etc/X11/xorg.conf.backup_{timestamp} || true"]

    def _execute_transaction_bulk(self, commands):
        if not commands: return False
        if self.is_macos:
            self.logger.info(f"[SIMULATION] Komutlar: {commands}")
            return True

        full_command = " && ".join(commands)
        
        # Etkileşimsiz mod wrapper içinde zaten var (DEBIAN_FRONTEND)
        # Sadece komutu birleştirip gönderiyoruz.
        
        # Çift tırnak kaçışlarına dikkat ederek pkexec çalıştır
        # Yeni Yöntem: Wrapper Script (Daha temiz UI)
        final_cmd = f'pkexec driver-pilot-root-task "{full_command}"'
        
        self.logger.info("Toplu işlem başlatılıyor...")
        result = self.runner.run(final_cmd)
        
        if result is None:
            self.logger.error("İşlem hatası.")
            return False
        self.logger.info("İşlem tamamlandı.")
        return True
