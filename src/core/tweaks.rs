#![allow(dead_code)]

// System Tweaks — GPU stats, GameMode, Prime Switch, Flatpak fix, Wayland fix

use crate::utils::command;
use std::fs;
use std::sync::OnceLock;

/// Cached CPU core count — read once from /proc/cpuinfo.
static CPU_COUNT: OnceLock<usize> = OnceLock::new();

/// GPU statistics from nvidia-smi.
#[derive(Debug, Clone, Default)]
pub struct GpuStats {
    pub temp: u32,
    pub load: u32,
    pub mem_used: u32,
    pub mem_total: u32,
}

/// System-level resource statistics.
#[derive(Debug, Clone, Default)]
pub struct SystemStats {
    pub cpu_load: u32,
    pub ram_used: u32,
    pub ram_total: u32,
    pub ram_percent: u32,
    pub cpu_temp: u32,
}

/// Get NVIDIA GPU statistics via nvidia-smi.
pub fn get_gpu_stats() -> GpuStats {
    let mut stats = GpuStats::default();

    if command::which("nvidia-smi") {
        if let Some(res) = command::run(
            "nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits"
        ) {
            let parts: Vec<&str> = res.split(", ").collect();
            if parts.len() >= 4 {
                stats.temp = parts[0].trim().parse().unwrap_or(0);
                stats.load = parts[1].trim().parse().unwrap_or(0);
                stats.mem_used = parts[2].trim().parse().unwrap_or(0);
                stats.mem_total = parts[3].trim().parse().unwrap_or(0);
            }
        }
    }

    stats
}

/// Get system-level statistics (CPU load, RAM, CPU temp).
pub fn get_system_stats() -> SystemStats {
    let mut stats = SystemStats::default();

    // CPU Load from /proc/loadavg
    if let Ok(contents) = fs::read_to_string("/proc/loadavg") {
        let parts: Vec<&str> = contents.split_whitespace().collect();
        if !parts.is_empty() {
            if let Ok(load_avg) = parts[0].parse::<f64>() {
                let cores = num_cpus();
                let percent = (load_avg / cores as f64) * 100.0;
                stats.cpu_load = percent.min(100.0) as u32;
            }
        }
    }

    // RAM from /proc/meminfo
    if let Ok(contents) = fs::read_to_string("/proc/meminfo") {
        let mut mem_total_kb: u64 = 0;
        let mut mem_available_kb: u64 = 0;

        for line in contents.lines() {
            if line.starts_with("MemTotal:") {
                mem_total_kb = parse_meminfo_value(line);
            } else if line.starts_with("MemAvailable:") {
                mem_available_kb = parse_meminfo_value(line);
            }
        }

        if mem_total_kb > 0 {
            let total_mb = mem_total_kb / 1024;
            let avail_mb = mem_available_kb / 1024;
            let used_mb = total_mb.saturating_sub(avail_mb);

            stats.ram_total = total_mb as u32;
            stats.ram_used = used_mb as u32;
            stats.ram_percent = ((used_mb as f64 / total_mb as f64) * 100.0) as u32;
        }
    }

    // CPU Temperature from thermal zone
    if let Ok(contents) = fs::read_to_string("/sys/class/thermal/thermal_zone0/temp") {
        if let Ok(temp_millic) = contents.trim().parse::<u64>() {
            stats.cpu_temp = (temp_millic / 1000) as u32;
        }
    }

    stats
}

/// Check if Feral GameMode is installed.
pub fn is_gamemode_installed() -> bool {
    command::which("gamemoded")
}

/// Install GameMode via DNF.
pub fn install_gamemode() -> Result<String, String> {
    log::info!("GameMode installation starting...");
    let cmd = r#"pkexec ro-control-root-task "dnf install -y gamemode""#;
    let (code, _out, err) = command::run_full(cmd);

    if code != 0 {
        let msg = format!("GameMode installation failed. Code: {}, Err: {}", code, err);
        log::error!("{}", msg);
        Err(msg)
    } else {
        log::info!("GameMode installed successfully.");
        Ok("GameMode installed successfully.".into())
    }
}

/// Check if NVIDIA Prime (switcheroo-control) is supported.
pub fn is_prime_supported() -> bool {
    // Fedora uses switcheroo-control instead of prime-select
    command::which("switcherooctl") || command::which("prime-select")
}

/// Get current graphics profile.
pub fn get_prime_profile() -> String {
    if command::which("switcherooctl") {
        if let Some(output) = command::run("switcherooctl list") {
            if output.contains("Default:") {
                return "switcheroo".into();
            }
        }
    }
    if command::which("prime-select") {
        return command::run("prime-select query")
            .unwrap_or_else(|| "unknown".into())
            .trim()
            .to_string();
    }
    "unknown".into()
}

/// Set NVIDIA Prime profile (requires reboot).
pub fn set_prime_profile(profile: &str) -> bool {
    log::info!("Setting prime profile to: {}", profile);
    let cmd = format!("pkexec prime-select {}", profile);
    let (code, _, err) = command::run_full(&cmd);
    if code != 0 {
        log::error!("Prime profile change failed: {}", err);
        false
    } else {
        true
    }
}

/// Repair Flatpak permissions (NVIDIA runtime, Steam fixes).
pub fn repair_flatpak_permissions() -> Result<String, String> {
    log::info!("Flatpak repair starting...");
    let cmd = r#"pkexec ro-control-root-task "flatpak update -y && flatpak repair""#;
    let (code, out, err) = command::run_full(cmd);

    if code != 0 {
        let msg = format!("Flatpak repair error: {}", err);
        log::error!("{}", msg);
        Err(msg)
    } else {
        // Safe truncation that respects UTF-8 char boundaries
        let limit = 500;
        let truncated = if out.len() <= limit {
            &out
        } else {
            let mut end = limit;
            while end > 0 && !out.is_char_boundary(end) {
                end -= 1;
            }
            &out[..end]
        };
        let msg = format!("Flatpak repair completed.\n\nOutput:\n{}...", truncated);
        log::info!("Flatpak repair completed.");
        Ok(msg)
    }
}

/// Enable NVIDIA DRM modeset for Wayland.
pub fn enable_nvidia_wayland_fix() -> Result<String, String> {
    log::info!("Applying NVIDIA Wayland fix...");

    let param = "nvidia-drm.modeset=1";
    let grub_file = "/etc/default/grub";

    // Check if already applied
    if let Ok(contents) = fs::read_to_string(grub_file) {
        if contents.contains(param) {
            return Ok("Parameter already applied. No action needed.".into());
        }
    }

    // Apply via pkexec
    let sed_cmd = format!(
        r#"sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT\s*=\s*"/&{} /' {}"#,
        param, grub_file
    );

    // Fedora uses grub2-mkconfig instead of update-grub
    let update_cmd = if command::which("grub2-mkconfig") {
        "grub2-mkconfig -o /boot/grub2/grub.cfg"
    } else {
        "update-grub"
    };

    let full_cmd = format!(
        r#"cp {} {}.bak && {} && {}"#,
        grub_file, grub_file, sed_cmd, update_cmd
    );

    let (code, _, err) =
        command::run_full(&format!(r#"pkexec ro-control-root-task "{}""#, full_cmd));

    if code == 0 {
        Ok("Operation successful. REBOOT your computer for changes to take effect.".into())
    } else {
        Err(format!("Error occurred: {}", err))
    }
}

// --- Helpers ---

fn parse_meminfo_value(line: &str) -> u64 {
    let parts: Vec<&str> = line.split_whitespace().collect();
    if parts.len() >= 2 {
        parts[1].parse().unwrap_or(0)
    } else {
        0
    }
}

fn num_cpus() -> usize {
    *CPU_COUNT.get_or_init(|| {
        if let Ok(contents) = fs::read_to_string("/proc/cpuinfo") {
            contents
                .lines()
                .filter(|l| l.starts_with("processor"))
                .count()
                .max(1)
        } else {
            1
        }
    })
}
