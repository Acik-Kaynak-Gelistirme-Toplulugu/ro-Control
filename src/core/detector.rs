// System Detector — GPU, CPU, RAM, Distro, Secure Boot detection
// Fedora/Linux native — no macOS simulation

use crate::utils::command;
use regex::Regex;
use std::collections::HashMap;

#[derive(Debug, Clone, Default)]
pub struct GpuInfo {
    pub vendor: String,
    pub model: String,
    pub driver_in_use: String,
    pub secure_boot: bool,
}

#[derive(Debug, Clone, Default)]
pub struct SystemInfo {
    pub gpu: GpuInfo,
    pub cpu: String,
    pub ram: String,
    pub distro: String,
    pub kernel: String,
    pub display_server: String,
}

#[derive(Debug, Clone, Default)]
pub struct OsInfo {
    pub id: String,
    pub version: String,
    pub name: String,
}

/// Detect GPU information using lspci.
pub fn detect_gpu() -> GpuInfo {
    let mut info = GpuInfo {
        vendor: "Unknown".into(),
        model: "Unknown".into(),
        driver_in_use: "Unknown".into(),
        secure_boot: false,
    };

    // 1. GPU Detection via lspci -vmm
    if command::which("lspci") {
        if let Some(output) = command::run("lspci -vmm") {
            let devices: Vec<&str> = output.split("\n\n").collect();
            for device in devices {
                if device.contains("VGA")
                    || device.contains("3D controller")
                    || device.contains("Display controller")
                {
                    let mut details: HashMap<&str, &str> = HashMap::new();
                    for line in device.lines() {
                        if let Some((key, val)) = line.split_once(':') {
                            details.insert(key.trim(), val.trim());
                        }
                    }

                    let vendor = details.get("Vendor").copied().unwrap_or("");
                    let device_name = details.get("Device").copied().unwrap_or("");

                    if info.vendor == "Unknown" {
                        info.vendor = vendor.to_string();
                        info.model = device_name.to_string();
                    }

                    if vendor.contains("NVIDIA") {
                        info.vendor = "NVIDIA".into();
                        info.model = device_name.to_string();
                        break;
                    } else if vendor.contains("Advanced Micro Devices") || vendor.contains("AMD") {
                        info.vendor = "AMD".into();
                        info.model = device_name.to_string();
                        break;
                    } else if vendor.contains("Intel") {
                        info.vendor = "Intel".into();
                        info.model = device_name.to_string();
                        break;
                    }
                }
            }
        }
    }

    if info.vendor == "Unknown" || info.vendor.is_empty() {
        info.vendor = "Sistem".into();
        info.model = "Grafik Bağdaştırıcısı".into();
    }

    // 2. Active driver via lspci -k
    if command::which("lspci") {
        if let Some(output) = command::run("lspci -k") {
            let mut capture_next = false;
            for line in output.lines() {
                if line.contains("VGA") || line.contains("3D controller") {
                    capture_next = true;
                }
                if capture_next && line.contains("Kernel driver in use:") {
                    if let Some((_, driver)) = line.split_once(':') {
                        info.driver_in_use = driver.trim().to_string();
                        break;
                    }
                }
            }
        }
    }

    // 3. Secure Boot via mokutil
    if command::which("mokutil") {
        if let Some(output) = command::run("mokutil --sb-state") {
            info.secure_boot = output.contains("SecureBoot enabled");
        }
    }

    info
}

/// Get full system information.
pub fn get_full_system_info() -> SystemInfo {
    let gpu = detect_gpu();

    SystemInfo {
        gpu,
        cpu: get_cpu_info(),
        ram: get_ram_info(),
        distro: get_distro_info(),
        kernel: get_kernel_info(),
        display_server: std::env::var("XDG_SESSION_TYPE").unwrap_or_else(|_| "Unknown".into()),
    }
}

/// Detect OS information from /etc/os-release.
pub fn detect_os() -> OsInfo {
    let mut info = OsInfo {
        id: "linux".into(),
        version: "unknown".into(),
        name: "Linux".into(),
    };

    if let Ok(contents) = std::fs::read_to_string("/etc/os-release") {
        let mut fields: HashMap<String, String> = HashMap::new();
        for line in contents.lines() {
            if let Some((k, v)) = line.split_once('=') {
                fields.insert(k.to_string(), v.trim_matches('"').to_string());
            }
        }
        if let Some(id) = fields.get("ID") {
            info.id = id.clone();
        }
        if let Some(ver) = fields.get("VERSION_ID") {
            info.version = ver.clone();
        }
        if let Some(name) = fields.get("PRETTY_NAME") {
            info.name = name.clone();
        }
    }

    info
}

/// Determine the package manager based on distro ID.
pub fn get_package_manager() -> Option<&'static str> {
    let os = detect_os();
    match os.id.as_str() {
        "fedora" | "rhel" | "centos" | "rocky" | "almalinux" => Some("dnf"),
        "ubuntu" | "debian" | "linuxmint" | "pop" => Some("apt"),
        "arch" | "manjaro" | "endeavouros" => Some("pacman"),
        "opensuse" | "sles" | "opensuse-leap" | "opensuse-tumbleweed" => Some("zypper"),
        _ => None,
    }
}

fn get_cpu_info() -> String {
    if let Ok(contents) = std::fs::read_to_string("/proc/cpuinfo") {
        for line in contents.lines() {
            if line.starts_with("model name") {
                if let Some((_, val)) = line.split_once(':') {
                    return val.trim().to_string();
                }
            }
        }
    }
    "Unknown".into()
}

fn get_ram_info() -> String {
    if let Some(output) = command::run("LC_ALL=C free -h") {
        for line in output.lines() {
            if line.starts_with("Mem:") {
                let parts: Vec<&str> = line.split_whitespace().collect();
                if parts.len() >= 2 {
                    return parts[1].replace("Gi", " GB").replace("Mi", " MB");
                }
            }
        }
    }
    "Unknown".into()
}

fn get_kernel_info() -> String {
    command::run("uname -r").unwrap_or_else(|| "Unknown".into())
}

fn get_distro_info() -> String {
    let os = detect_os();
    os.name
}

/// Check if RPM Fusion NVIDIA repo is enabled.
pub fn is_rpmfusion_nvidia_enabled() -> bool {
    command::run("dnf repolist enabled")
        .map(|output| output.contains("rpmfusion-nonfree-nvidia-driver"))
        .unwrap_or(false)
}

/// Get available NVIDIA driver versions from DNF.
pub fn get_available_nvidia_versions() -> Vec<String> {
    // On Fedora, NVIDIA driver is provided via RPM Fusion as "akmod-nvidia"
    // We check available versions from dnf
    if let Some(output) = command::run("dnf list available 'akmod-nvidia*' 2>/dev/null") {
        let re = Regex::new(r"akmod-nvidia[^\s]*\s+(\d+\.\d+[\.\d]*)").ok();
        if let Some(re) = re {
            let mut versions: Vec<String> = re
                .captures_iter(&output)
                .filter_map(|cap| cap.get(1).map(|m| m.as_str().to_string()))
                .collect();
            versions.sort_by(|a, b| b.cmp(a)); // Descending
            versions.dedup();
            return versions;
        }
    }
    // Defaults if nothing found
    vec!["565".into(), "550".into(), "535".into()]
}
