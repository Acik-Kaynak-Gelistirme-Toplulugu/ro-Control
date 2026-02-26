#![allow(dead_code)]

// Driver Installer — Fedora (DNF) focused NVIDIA/AMD driver management
// Uses pkexec for privilege escalation via PolicyKit

use crate::core::detector;
use crate::utils::command;
use chrono::Local;

/// Log callback type for real-time UI updates.
pub type LogCallback = Box<dyn Fn(&str) + Send + Sync>;

pub struct DriverInstaller {
    pkg_manager: Option<&'static str>,
    log_callback: Option<LogCallback>,
}

impl DriverInstaller {
    pub fn new() -> Self {
        Self {
            pkg_manager: detector::get_package_manager(),
            log_callback: None,
        }
    }

    pub fn set_log_callback(&mut self, callback: LogCallback) {
        self.log_callback = Some(callback);
    }

    fn log(&self, msg: &str) {
        log::info!("{}", msg);
        if let Some(ref cb) = self.log_callback {
            cb(msg);
        }
    }

    /// Install NVIDIA proprietary driver (closed source) via RPM Fusion.
    pub fn install_nvidia_closed(&self) -> bool {
        self.install_nvidia_closed_versioned(None)
    }

    /// Install NVIDIA proprietary driver with optional version pinning.
    pub fn install_nvidia_closed_versioned(&self, version: Option<&str>) -> bool {
        self.log("--- BAŞLATILIYOR: NVIDIA Proprietary (DNF/RPM Fusion) ---");
        let mut commands = self.prepare_install_chain();

        self.log("NVIDIA paketleri hazırlanıyor...");

        match self.pkg_manager {
            Some("dnf") => {
                // Ensure RPM Fusion is enabled
                commands.push("dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true".into());
                let pkg = match version {
                    Some(v) if !v.is_empty() => {
                        self.log(&format!("Sürüm sabitlendi: {}", v));
                        format!("dnf install -y akmod-nvidia-{v}* xorg-x11-drv-nvidia-cuda-{v}* nvidia-settings", v = v)
                    }
                    _ => "dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-settings"
                        .into(),
                };
                commands.push(pkg);
            }
            Some("apt") => {
                let pkg = match version {
                    Some(v) if !v.is_empty() => format!(
                        "apt-get install -y nvidia-driver-{}  nvidia-settings",
                        v.split('.').next().unwrap_or(v)
                    ),
                    _ => "apt-get install -y nvidia-driver nvidia-settings".into(),
                };
                commands.push(pkg);
            }
            Some("pacman") => {
                commands.push("pacman -Sy --noconfirm nvidia nvidia-utils nvidia-settings".into());
            }
            _ => {
                self.log("HATA: Desteklenmeyen paket yöneticisi!");
                return false;
            }
        }

        commands.extend(self.finalize_installation_chain());
        self.execute_transaction_bulk(&commands, "NVIDIA Kapalı Kaynak Kurulumu")
    }

    /// Install NVIDIA open kernel driver.
    pub fn install_nvidia_open(&self) -> bool {
        self.install_nvidia_open_versioned(None)
    }

    /// Install NVIDIA open kernel driver with optional version pinning.
    pub fn install_nvidia_open_versioned(&self, version: Option<&str>) -> bool {
        self.log("--- BAŞLATILIYOR: NVIDIA Open Kernel ---");
        let mut commands = self.prepare_install_chain();

        match self.pkg_manager {
            Some("dnf") => {
                commands.push("dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true".into());
                let pkg = match version {
                    Some(v) if !v.is_empty() => {
                        self.log(&format!("Sürüm sabitlendi: {}", v));
                        format!(
                            "dnf install -y akmod-nvidia-open-{v}* nvidia-settings",
                            v = v
                        )
                    }
                    _ => "dnf install -y akmod-nvidia-open nvidia-settings".into(),
                };
                commands.push(pkg);
            }
            Some("apt") => {
                let pkg = match version {
                    Some(v) if !v.is_empty() => format!(
                        "apt-get install -y nvidia-driver-open-{}  nvidia-settings",
                        v.split('.').next().unwrap_or(v)
                    ),
                    _ => "apt-get install -y nvidia-driver-open nvidia-settings".into(),
                };
                commands.push(pkg);
            }
            Some("pacman") => {
                commands.push("pacman -Sy --noconfirm nvidia-open nvidia-utils".into());
            }
            _ => {
                self.log("HATA: Desteklenmeyen paket yöneticisi!");
                return false;
            }
        }

        commands.extend(self.finalize_installation_chain());
        self.execute_transaction_bulk(&commands, "NVIDIA Açık Kaynak Kurulumu")
    }

    /// Install AMD open source (Mesa) drivers.
    pub fn install_amd_open(&self) -> bool {
        self.log("--- BAŞLATILIYOR: AMD Mesa (Open Source) ---");
        let mut commands = self.prepare_install_chain();

        match self.pkg_manager {
            Some("dnf") => {
                commands.push(
                    "dnf install -y xorg-x11-drv-amdgpu mesa-dri-drivers mesa-vulkan-drivers"
                        .into(),
                );
            }
            Some("apt") => {
                commands.push(
                    "apt-get install -y xserver-xorg-video-amdgpu mesa-vulkan-drivers mesa-utils"
                        .into(),
                );
            }
            Some("pacman") => {
                commands.push("pacman -Sy --noconfirm xf86-video-amdgpu mesa vulkan-radeon".into());
            }
            _ => {
                self.log("HATA: Desteklenmeyen paket yöneticisi!");
                return false;
            }
        }

        self.execute_transaction_bulk(&commands, "AMD Mesa Kurulumu")
    }

    /// Remove NVIDIA drivers and revert to nouveau.
    pub fn remove_nvidia(&self, deep_clean: bool) -> bool {
        self.log("--- BAŞLATILIYOR: NVIDIA Sürücü Kaldırma ---");
        let mut commands = self.backup_config_commands();

        // Remove blacklist
        commands.push("rm -f /etc/modprobe.d/blacklist-nouveau.conf".into());

        if deep_clean {
            commands.push("rm -f /etc/X11/xorg.conf".into());
            commands.push("rm -f /etc/modprobe.d/nvidia*".into());
            commands.push("rm -f /etc/modules-load.d/nvidia*".into());
            commands.push("rm -f /etc/X11/xorg.conf.d/*nvidia*".into());
            commands.push("rm -f /usr/share/vulkan/icd.d/nvidia_icd.json".into());
            commands.push("rm -f /etc/vulkan/icd.d/nvidia_icd.json".into());
        }

        match self.pkg_manager {
            Some("dnf") => {
                commands.push("dnf remove -y '*nvidia*' '*kmod-nvidia*' || true".into());
            }
            Some("apt") => {
                commands.push("apt-get remove --purge -y '^nvidia-.*' '^libnvidia-.*'".into());
                commands.push("apt-get autoremove -y".into());
            }
            Some("pacman") => {
                commands.push("pacman -Rs --noconfirm nvidia nvidia-utils nvidia-settings nvidia-open || true".into());
            }
            _ => {}
        }

        commands.extend(self.update_initramfs_commands());
        self.execute_transaction_bulk(&commands, "Sürücü Kaldırma İşlemi")
    }

    /// Create a Timeshift snapshot before operations.
    pub fn create_timeshift_snapshot(&self) -> bool {
        if !command::which("timeshift") {
            log::warn!("Timeshift not installed, skipping backup.");
            return false;
        }
        self.log("Timeshift yedeği oluşturuluyor...");
        let cmd = r#"pkexec timeshift --create --comments "ro-Control Otomatik Yedek" --tags D"#;
        command::run(cmd).is_some()
    }

    // --- Private helpers ---

    fn prepare_install_chain(&self) -> Vec<String> {
        let mut chain = Vec::new();
        self.log("Adım 1: Mevcut Xorg yapılandırması yedekleniyor...");
        chain.extend(self.backup_config_commands());

        self.log("Adım 2: Nouveau sürücüsü engelleniyor (Blacklist)...");
        chain.push("printf 'blacklist nouveau\\noptions nouveau modeset=0' > /etc/modprobe.d/blacklist-nouveau.conf".into());

        match self.pkg_manager {
            Some("dnf") => {
                chain.push("dnf install -y kernel-devel kernel-headers gcc make".into());
            }
            Some("apt") => {
                chain.push("apt-get update".into());
                chain.push("apt-get install -y build-essential linux-headers-$(uname -r)".into());
            }
            Some("pacman") => {
                chain.push("pacman -Sy --noconfirm base-devel linux-headers".into());
            }
            _ => {}
        }

        chain
    }

    fn finalize_installation_chain(&self) -> Vec<String> {
        self.update_initramfs_commands()
    }

    fn update_initramfs_commands(&self) -> Vec<String> {
        match self.pkg_manager {
            Some("dnf") => vec!["dracut --force".into()],
            Some("apt") => vec!["update-initramfs -u".into()],
            Some("pacman") => vec!["mkinitcpio -P".into()],
            Some("zypper") => vec!["mkinitrd".into()],
            _ => vec![],
        }
    }

    fn backup_config_commands(&self) -> Vec<String> {
        let timestamp = Local::now().format("%Y%m%d_%H%M%S");
        vec![format!(
            "[ -f /etc/X11/xorg.conf ] && cp /etc/X11/xorg.conf /etc/X11/xorg.conf.backup_{} || true",
            timestamp
        )]
    }

    fn execute_transaction_bulk(&self, commands: &[String], task_name: &str) -> bool {
        if commands.is_empty() {
            return false;
        }

        let full_command = commands.join(" && ");
        let final_cmd = format!(r#"pkexec ro-control-root-task "{}""#, full_command);

        let now = Local::now().format("%H:%M:%S");
        self.log(&format!(
            "\n[{}] --- İŞLEM BAŞLATILIYOR: {} ---",
            now, task_name
        ));

        // System diagnostic report
        let sys_info = detector::get_full_system_info();
        self.log("\n[SYSTEM DIAGNOSTIC REPORT]");
        self.log(&format!(
            "OS: {} | Kernel: {}",
            sys_info.distro, sys_info.kernel
        ));
        self.log(&format!("CPU: {} | RAM: {}", sys_info.cpu, sys_info.ram));
        self.log(&format!(
            "GPU: {} {}",
            sys_info.gpu.vendor, sys_info.gpu.model
        ));
        self.log(&format!("Driver In Use: {}", sys_info.gpu.driver_in_use));
        self.log(&"-".repeat(40));

        self.log("\n[EXECUTION PLAN]");
        for (i, cmd) in commands.iter().enumerate() {
            self.log(&format!("{}. {}", i + 1, cmd));
        }
        self.log(&format!("{}\n", "-".repeat(40)));

        self.log("Yetki bekleniyor (Root/Admin)...");
        self.log("Lütfen açılan pencerede şifrenizi girin.\n");

        let (ret_code, out, err) = command::run_full(&final_cmd);

        if ret_code != 0 {
            self.log("\n[!!! CRITICAL ERROR !!!]");
            self.log(&format!("Exit Code: {}", ret_code));
            self.log("Command Output (STDERR):");
            self.log(&if err.is_empty() {
                "(No error output received)".into()
            } else {
                err
            });
            self.log("HATA: İşlem başarısız oldu.");
            return false;
        }

        if !out.is_empty() {
            self.log("\n[Command Output]");
            self.log(&out);
        }

        self.log(&format!("\nBAŞARILI: {} tamamlandı.", task_name));
        self.log("Değişikliklerin etkili olması için sistemi yeniden başlatın.");
        true
    }
}
