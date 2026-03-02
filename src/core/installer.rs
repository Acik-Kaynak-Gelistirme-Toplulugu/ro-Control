#![allow(dead_code)]

// Driver Installer — Fedora (DNF) focused NVIDIA/AMD driver management
// Uses pkexec for privilege escalation via PolicyKit

use crate::core::detector;
use crate::utils::command;
use chrono::Local;
use regex::Regex;
use std::sync::LazyLock;

/// Regex for validating version strings (digits and dots only).
static RE_SAFE_VERSION: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^\d+(\.\d+)*$").unwrap());

/// Validate that a version string contains only safe characters (digits, dots).
fn is_safe_version(v: &str) -> bool {
    RE_SAFE_VERSION.is_match(v)
}

/// Resolve the Fedora release version number for RPM Fusion URLs.
fn fedora_release() -> String {
    command::run("rpm -E %fedora").unwrap_or_else(|| "40".into())
}

/// Resolve the running kernel version for linux-headers.
fn kernel_release() -> String {
    command::run("uname -r").unwrap_or_else(|| "".into())
}

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
        self.log("--- STARTING: NVIDIA Proprietary (DNF/RPM Fusion) ---");

        // Validate version for ALL package managers up-front
        if let Some(v) = version {
            if !v.is_empty() && !is_safe_version(v) {
                self.log(&format!("ERROR: Invalid version format: {}", v));
                return false;
            }
        }

        let mut commands = self.prepare_install_chain();

        self.log("Preparing NVIDIA packages...");

        match self.pkg_manager {
            Some("dnf") => {
                // Ensure RPM Fusion is enabled (resolve Fedora version in Rust, not shell)
                let fedora_ver = fedora_release();
                commands.push(format!(
                    "dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-{fv}.noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-{fv}.noarch.rpm",
                    fv = fedora_ver
                ));
                let pkg = match version {
                    Some(v) if !v.is_empty() => {
                        self.log(&format!("Version pinned: {}", v));
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
                self.log("ERROR: Unsupported package manager!");
                return false;
            }
        }

        commands.extend(self.finalize_installation_chain());
        self.execute_transaction_bulk(&commands, "NVIDIA Proprietary Install")
    }

    /// Install NVIDIA open kernel driver.
    pub fn install_nvidia_open(&self) -> bool {
        self.install_nvidia_open_versioned(None)
    }

    /// Install NVIDIA open kernel driver with optional version pinning.
    pub fn install_nvidia_open_versioned(&self, version: Option<&str>) -> bool {
        self.log("--- STARTING: NVIDIA Open Kernel ---");

        // Validate version for ALL package managers up-front
        if let Some(v) = version {
            if !v.is_empty() && !is_safe_version(v) {
                self.log(&format!("ERROR: Invalid version format: {}", v));
                return false;
            }
        }

        let mut commands = self.prepare_install_chain();

        match self.pkg_manager {
            Some("dnf") => {
                let fedora_ver = fedora_release();
                commands.push(format!(
                    "dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-{fv}.noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-{fv}.noarch.rpm",
                    fv = fedora_ver
                ));
                let pkg = match version {
                    Some(v) if !v.is_empty() => {
                        self.log(&format!("Version pinned: {}", v));
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
                self.log("ERROR: Unsupported package manager!");
                return false;
            }
        }

        commands.extend(self.finalize_installation_chain());
        self.execute_transaction_bulk(&commands, "NVIDIA Open Kernel Install")
    }

    /// Install AMD open source (Mesa) drivers.
    pub fn install_amd_open(&self) -> bool {
        self.log("--- STARTING: AMD Mesa (Open Source) ---");
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
                self.log("ERROR: Unsupported package manager!");
                return false;
            }
        }

        self.execute_transaction_bulk(&commands, "AMD Mesa Install")
    }

    /// Remove NVIDIA drivers and revert to nouveau.
    pub fn remove_nvidia(&self, deep_clean: bool) -> bool {
        self.log("--- STARTING: NVIDIA Driver Removal ---");
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
                // Note: dnf remove returns 0 even when packages are not installed
                commands.push("dnf remove -y *nvidia* *kmod-nvidia*".into());
            }
            Some("apt") => {
                commands.push("apt-get remove --purge -y nvidia-* libnvidia-*".into());
                commands.push("apt-get autoremove -y".into());
            }
            Some("pacman") => {
                commands.push("pacman -Rs --noconfirm nvidia nvidia-utils nvidia-settings nvidia-open".into());
            }
            _ => {}
        }

        commands.extend(self.update_initramfs_commands());
        self.execute_transaction_bulk(&commands, "Driver Removal")
    }

    /// Create a Timeshift snapshot before operations.
    pub fn create_timeshift_snapshot(&self) -> bool {
        if !command::which("timeshift") {
            log::warn!("Timeshift not installed, skipping backup.");
            return false;
        }
        self.log("Creating Timeshift backup...");
        // Route through ro-control-root-task as a separate argument
        let output = std::process::Command::new("pkexec")
            .arg("ro-control-root-task")
            .arg("timeshift --create --comments ro-Control_Auto_Backup --tags D")
            .output();
        match output {
            Ok(o) => o.status.success(),
            Err(e) => {
                self.log(&format!("Timeshift failed: {}", e));
                false
            }
        }
    }

    // --- Private helpers ---

    fn prepare_install_chain(&self) -> Vec<String> {
        let mut chain = Vec::new();
        self.log("Step 1: Backing up current Xorg configuration...");
        chain.extend(self.backup_config_commands());

        self.log("Step 2: Blacklisting nouveau driver...");
        // Write blacklist config: create a temp file in Rust, then cp it via root-task
        // (shell metacharacters > and | are blocked by security filter)
        {
            let content = "blacklist nouveau\noptions nouveau modeset=0\n";
            let tmp = format!(
                "/tmp/ro-control-nouveau-{}-{}.conf",
                std::process::id(),
                std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_secs()
            );
            if let Err(e) = std::fs::write(&tmp, content) {
                self.log(&format!("Failed to write temp blacklist file: {}", e));
            } else {
                chain.push(format!("cp {} /etc/modprobe.d/blacklist-nouveau.conf", tmp));
            }
        }

        match self.pkg_manager {
            Some("dnf") => {
                chain.push("dnf install -y kernel-devel kernel-headers gcc make".into());
            }
            Some("apt") => {
                chain.push("apt-get update".into());
                let kr = kernel_release();
                chain.push(format!(
                    "apt-get install -y build-essential linux-headers-{}",
                    kr
                ));
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
        // Check if xorg.conf exists before asking root to copy it.
        // The existence check runs as user (readable path); only the copy needs root.
        let timestamp = Local::now().format("%Y%m%d_%H%M%S");
        if std::path::Path::new("/etc/X11/xorg.conf").exists() {
            vec![format!(
                "cp /etc/X11/xorg.conf /etc/X11/xorg.conf.backup_{}",
                timestamp
            )]
        } else {
            vec![]
        }
    }

    fn execute_transaction_bulk(&self, commands: &[String], task_name: &str) -> bool {
        if commands.is_empty() {
            return false;
        }

        // Build pkexec command: each command is a separate argument to ro-control-root-task
        // This avoids && chaining and keeps the security filter clean.
        let mut args: Vec<String> = vec!["pkexec".into(), "ro-control-root-task".into()];
        args.extend(commands.iter().cloned());

        let now = Local::now().format("%H:%M:%S");
        self.log(&format!(
            "\n[{}] --- OPERATION STARTING: {} ---",
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

        self.log("Waiting for authorization (Root/Admin)...");
        self.log("Please enter your password in the dialog.\n");

        // Execute: pkexec ro-control-root-task "cmd1" "cmd2" "cmd3" ...
        let output = std::process::Command::new(&args[0])
            .args(&args[1..])
            .output();

        let (ret_code, out, err) = match output {
            Ok(o) => (
                o.status.code().unwrap_or(-1),
                String::from_utf8_lossy(&o.stdout).trim().to_string(),
                String::from_utf8_lossy(&o.stderr).trim().to_string(),
            ),
            Err(e) => (-1, String::new(), e.to_string()),
        };

        if ret_code != 0 {
            self.log("\n[!!! CRITICAL ERROR !!!]");
            self.log(&format!("Exit Code: {}", ret_code));
            self.log("Command Output (STDERR):");
            self.log(&if err.is_empty() {
                "(No error output received)".into()
            } else {
                err
            });
            self.log("ERROR: Operation failed.");
            return false;
        }

        if !out.is_empty() {
            self.log("\n[Command Output]");
            self.log(&out);
        }

        self.log(&format!("\nSUCCESS: {} completed.", task_name));
        self.log("Reboot the system for changes to take effect.");
        true
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Helper: create a DriverInstaller with a known package manager
    fn installer_with_pm(pm: Option<&'static str>) -> DriverInstaller {
        DriverInstaller {
            pkg_manager: pm,
            log_callback: None,
        }
    }

    #[test]
    fn new_installer_has_no_log_callback() {
        let inst = installer_with_pm(Some("dnf"));
        assert!(inst.log_callback.is_none());
    }

    #[test]
    fn update_initramfs_dnf() {
        let inst = installer_with_pm(Some("dnf"));
        let cmds = inst.update_initramfs_commands();
        assert_eq!(cmds, vec!["dracut --force"]);
    }

    #[test]
    fn update_initramfs_apt() {
        let inst = installer_with_pm(Some("apt"));
        let cmds = inst.update_initramfs_commands();
        assert_eq!(cmds, vec!["update-initramfs -u"]);
    }

    #[test]
    fn update_initramfs_pacman() {
        let inst = installer_with_pm(Some("pacman"));
        let cmds = inst.update_initramfs_commands();
        assert_eq!(cmds, vec!["mkinitcpio -P"]);
    }

    #[test]
    fn update_initramfs_zypper() {
        let inst = installer_with_pm(Some("zypper"));
        let cmds = inst.update_initramfs_commands();
        assert_eq!(cmds, vec!["mkinitrd"]);
    }

    #[test]
    fn update_initramfs_unknown_returns_empty() {
        let inst = installer_with_pm(None);
        let cmds = inst.update_initramfs_commands();
        assert!(cmds.is_empty());
    }

    #[test]
    fn backup_config_commands_format() {
        let inst = installer_with_pm(Some("dnf"));
        let cmds = inst.backup_config_commands();
        // Returns empty if /etc/X11/xorg.conf doesn't exist (CI/test environment)
        // If it existed, it would contain "cp" and "xorg.conf"
        for cmd in &cmds {
            assert!(cmd.contains("xorg.conf"));
            assert!(cmd.starts_with("cp "));
        }
    }

    #[test]
    fn prepare_install_chain_dnf_has_kernel_headers() {
        let inst = installer_with_pm(Some("dnf"));
        let chain = inst.prepare_install_chain();
        // Should contain: backup, blacklist nouveau, kernel-devel
        assert!(chain.iter().any(|c| c.contains("blacklist nouveau")));
        assert!(chain.iter().any(|c| c.contains("kernel-devel")));
    }

    #[test]
    fn prepare_install_chain_apt_has_linux_headers() {
        let inst = installer_with_pm(Some("apt"));
        let chain = inst.prepare_install_chain();
        assert!(chain.iter().any(|c| c.contains("linux-headers")));
    }

    #[test]
    fn finalize_chain_equals_initramfs() {
        let inst = installer_with_pm(Some("dnf"));
        assert_eq!(
            inst.finalize_installation_chain(),
            inst.update_initramfs_commands()
        );
    }

    #[test]
    fn set_log_callback_works() {
        let mut inst = installer_with_pm(Some("dnf"));
        let captured = std::sync::Arc::new(std::sync::Mutex::new(Vec::new()));
        let captured_clone = captured.clone();
        inst.set_log_callback(Box::new(move |msg| {
            captured_clone.lock().unwrap().push(msg.to_string());
        }));
        inst.log("test message");
        let logs = captured.lock().unwrap();
        assert_eq!(logs.len(), 1);
        assert_eq!(logs[0], "test message");
    }
}
