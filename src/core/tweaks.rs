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

/// Parse nvidia-smi CSV output (temp, utilization, memUsed, memTotal).
pub fn parse_nvidia_smi(output: &str) -> GpuStats {
    let mut stats = GpuStats::default();
    let parts: Vec<&str> = output.split(", ").collect();
    if parts.len() >= 4 {
        stats.temp = parts[0].trim().parse().unwrap_or(0);
        stats.load = parts[1].trim().parse().unwrap_or(0);
        stats.mem_used = parts[2].trim().parse().unwrap_or(0);
        stats.mem_total = parts[3].trim().parse().unwrap_or(0);
    }
    stats
}

/// Get NVIDIA GPU statistics via nvidia-smi.
pub fn get_gpu_stats() -> GpuStats {
    if command::which("nvidia-smi") {
        if let Some(res) = command::run(
            "nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits"
        ) {
            return parse_nvidia_smi(&res);
        }
    }

    GpuStats::default()
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
    let output = std::process::Command::new("pkexec")
        .arg("ro-control-root-task")
        .arg("dnf install -y gamemode")
        .output();

    match output {
        Ok(o) if o.status.success() => {
            log::info!("GameMode installed successfully.");
            Ok("GameMode installed successfully.".into())
        }
        Ok(o) => {
            let err = String::from_utf8_lossy(&o.stderr);
            let msg = format!("GameMode installation failed: {}", err);
            log::error!("{}", msg);
            Err(msg)
        }
        Err(e) => {
            let msg = format!("Failed to execute: {}", e);
            log::error!("{}", msg);
            Err(msg)
        }
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
    // Validate profile against allowed values to prevent command injection
    const ALLOWED_PROFILES: &[&str] = &["nvidia", "intel", "on-demand", "query"];
    if !ALLOWED_PROFILES.contains(&profile) {
        log::error!("Invalid prime profile: {}", profile);
        return false;
    }
    log::info!("Setting prime profile to: {}", profile);
    let output = std::process::Command::new("pkexec")
        .arg("ro-control-root-task")
        .arg(format!("prime-select {}", profile))
        .output();
    match output {
        Ok(o) => {
            if !o.status.success() {
                let err = String::from_utf8_lossy(&o.stderr);
                log::error!("Prime profile change failed: {}", err);
            }
            o.status.success()
        }
        Err(e) => {
            log::error!("Failed to execute prime-select: {}", e);
            false
        }
    }
}

/// Repair Flatpak permissions (NVIDIA runtime, Steam fixes).
pub fn repair_flatpak_permissions() -> Result<String, String> {
    log::info!("Flatpak repair starting...");
    let output = std::process::Command::new("pkexec")
        .arg("ro-control-root-task")
        .arg("flatpak update -y")
        .arg("flatpak repair")
        .output();

    let (code, out, err) = match output {
        Ok(o) => (
            o.status.code().unwrap_or(-1),
            String::from_utf8_lossy(&o.stdout).trim().to_string(),
            String::from_utf8_lossy(&o.stderr).trim().to_string(),
        ),
        Err(e) => (-1, String::new(), e.to_string()),
    };

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
    let grub_content =
        fs::read_to_string(grub_file).map_err(|e| format!("Cannot read {}: {}", grub_file, e))?;

    if grub_content.contains(param) {
        return Ok("Parameter already applied. No action needed.".into());
    }

    // Modify grub config in Rust, write to temp file, then cp via root-task
    let modified = grub_content.replace(
        "GRUB_CMDLINE_LINUX_DEFAULT=\"",
        &format!("GRUB_CMDLINE_LINUX_DEFAULT=\"{} ", param),
    );

    // If the replacement didn't change anything, the line format might differ
    if modified == grub_content {
        return Err("Could not find GRUB_CMDLINE_LINUX_DEFAULT line to modify.".into());
    }

    let tmp = format!("/tmp/ro-control-grub-{}.conf", std::process::id());
    fs::write(&tmp, &modified).map_err(|e| format!("Failed to write temp file: {}", e))?;

    // Fedora uses grub2-mkconfig instead of update-grub
    let update_cmd = if command::which("grub2-mkconfig") {
        "grub2-mkconfig -o /boot/grub2/grub.cfg"
    } else {
        "update-grub"
    };

    // Execute: backup, copy modified grub, update grub config
    let output = std::process::Command::new("pkexec")
        .arg("ro-control-root-task")
        .arg(format!("cp {} {}.bak", grub_file, grub_file))
        .arg(format!("cp {} {}", tmp, grub_file))
        .arg(update_cmd)
        .output();

    // Cleanup temp file
    let _ = fs::remove_file(&tmp);

    match output {
        Ok(o) if o.status.success() => {
            Ok("Operation successful. REBOOT your computer for changes to take effect.".into())
        }
        Ok(o) => {
            let err = String::from_utf8_lossy(&o.stderr);
            Err(format!("Error occurred: {}", err))
        }
        Err(e) => Err(format!("Failed to execute: {}", e)),
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

#[cfg(test)]
mod tests {
    use super::*;

    // ── parse_meminfo_value ─────────────────────────────────────────

    #[test]
    fn parse_meminfo_value_normal() {
        assert_eq!(parse_meminfo_value("MemTotal:       16384000 kB"), 16384000);
    }

    #[test]
    fn parse_meminfo_value_empty_line() {
        assert_eq!(parse_meminfo_value(""), 0);
    }

    #[test]
    fn parse_meminfo_value_no_number() {
        assert_eq!(parse_meminfo_value("MemTotal:"), 0);
    }

    #[test]
    fn parse_meminfo_value_tabs() {
        assert_eq!(parse_meminfo_value("MemAvailable:\t8192000 kB"), 8192000);
    }

    #[test]
    fn parse_meminfo_value_single_digit() {
        assert_eq!(parse_meminfo_value("SwapTotal:       0 kB"), 0);
    }

    #[test]
    fn parse_meminfo_value_large() {
        assert_eq!(
            parse_meminfo_value("MemTotal:       131923456 kB"),
            131923456
        );
    }

    // ── parse_nvidia_smi ────────────────────────────────────────────

    #[test]
    fn parse_nvidia_smi_normal() {
        let output = "75, 92, 4096, 8192";
        let stats = parse_nvidia_smi(output);
        assert_eq!(stats.temp, 75);
        assert_eq!(stats.load, 92);
        assert_eq!(stats.mem_used, 4096);
        assert_eq!(stats.mem_total, 8192);
    }

    #[test]
    fn parse_nvidia_smi_idle() {
        let output = "35, 0, 256, 8192";
        let stats = parse_nvidia_smi(output);
        assert_eq!(stats.temp, 35);
        assert_eq!(stats.load, 0);
        assert_eq!(stats.mem_used, 256);
        assert_eq!(stats.mem_total, 8192);
    }

    #[test]
    fn parse_nvidia_smi_empty() {
        let stats = parse_nvidia_smi("");
        assert_eq!(stats.temp, 0);
        assert_eq!(stats.load, 0);
        assert_eq!(stats.mem_used, 0);
        assert_eq!(stats.mem_total, 0);
    }

    #[test]
    fn parse_nvidia_smi_partial() {
        // Only 2 fields — less than expected 4
        let stats = parse_nvidia_smi("42, 50");
        assert_eq!(stats.temp, 0);
    }

    #[test]
    fn parse_nvidia_smi_garbage() {
        let stats = parse_nvidia_smi("N/A, ERR, 0, 0");
        assert_eq!(stats.temp, 0);
        assert_eq!(stats.load, 0);
        assert_eq!(stats.mem_used, 0);
        assert_eq!(stats.mem_total, 0);
    }

    // ── GpuStats / SystemStats defaults ─────────────────────────────

    #[test]
    fn gpu_stats_default_is_zero() {
        let stats = GpuStats::default();
        assert_eq!(stats.temp, 0);
        assert_eq!(stats.load, 0);
        assert_eq!(stats.mem_used, 0);
        assert_eq!(stats.mem_total, 0);
    }

    #[test]
    fn system_stats_default_is_zero() {
        let stats = SystemStats::default();
        assert_eq!(stats.cpu_load, 0);
        assert_eq!(stats.cpu_temp, 0);
        assert_eq!(stats.ram_used, 0);
        assert_eq!(stats.ram_total, 0);
        assert_eq!(stats.ram_percent, 0);
    }

    // ── UTF-8 safe truncation ───────────────────────────────────────

    #[test]
    fn safe_utf8_truncation() {
        let text = "Hello, world! 🦀 Rust is great";
        let limit = 15;
        let truncated = if text.len() <= limit {
            text
        } else {
            let mut end = limit;
            while end > 0 && !text.is_char_boundary(end) {
                end -= 1;
            }
            &text[..end]
        };
        assert!(truncated.len() <= limit);
        let _ = truncated.to_string();
    }

    #[test]
    fn safe_utf8_truncation_ascii_only() {
        let text = "Hello";
        let limit = 500;
        let truncated = if text.len() <= limit {
            text
        } else {
            &text[..limit]
        };
        assert_eq!(truncated, "Hello");
    }

    #[test]
    fn safe_utf8_truncation_emoji_boundary() {
        let text = "🦀🦀🦀"; // each emoji is 4 bytes, total 12
        let limit = 5; // cuts in middle of second emoji
        let mut end = limit;
        while end > 0 && !text.is_char_boundary(end) {
            end -= 1;
        }
        let truncated = &text[..end];
        assert_eq!(truncated, "🦀"); // should only keep first emoji
    }
}
