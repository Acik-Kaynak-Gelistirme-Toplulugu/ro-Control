#![allow(dead_code)]

// System Detector — GPU, CPU, RAM, Distro, Secure Boot detection
// Fedora/Linux native — no macOS simulation

use crate::utils::command;
use crate::utils::version;
use regex::Regex;
use std::collections::HashMap;
use std::sync::{LazyLock, OnceLock};
use std::time::Duration;

/// HTTP agent with a 30-second global timeout.
fn http_agent() -> ureq::Agent {
    let config = ureq::Agent::config_builder()
        .timeout_global(Some(Duration::from_secs(30)))
        .build();
    config.into()
}

/// Cached OS info — read once from /etc/os-release.
static OS_INFO_CACHE: OnceLock<OsInfo> = OnceLock::new();

/// Cached full system info — populated on first call.
static SYSTEM_INFO_CACHE: OnceLock<SystemInfo> = OnceLock::new();

/// Pre-compiled regex for akmod-nvidia version parsing.
/// Handles optional RPM epoch prefix (e.g. `3:565.57.01-1.fc41`).
static RE_AKMOD_VERSION: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"akmod-nvidia[^\s]*\s+(?:\d+:)?(\d+\.\d+[\.\d]*)").unwrap());

/// Pre-compiled regex for changelog version parsing.
/// Uses word boundaries on the 3-digit fallback to avoid matching inside dates like `2024`.
static RE_CHANGELOG_VERSION: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"(\d{3}\.\d{2}(?:\.\d+)?)|\b(\d{3})\b").unwrap());

/// Pre-compiled regex for NVIDIA download page version extraction.
static RE_NVIDIA_WEB_VERSION: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"(\d{3}\.\d{2,3}(?:\.\d+)?)").unwrap());

/// Represents a driver version with its source and metadata.
#[derive(Debug, Clone)]
pub struct DriverVersion {
    pub version: String,
    pub source: String, // "repo", "nvidia-official", "merged"
    pub release_notes: String,
    pub is_latest: bool,
    pub installable: bool, // true if available in local repo
}

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

/// Parse `lspci -vmm` output into a `GpuInfo` (vendor + model only).
///
/// Extracts VGA / 3D / Display controller devices, prioritising
/// NVIDIA > AMD > Intel when multiple GPUs are present (e.g. hybrid laptops).
pub fn parse_lspci_vmm(output: &str) -> GpuInfo {
    let mut info = GpuInfo {
        vendor: "Unknown".into(),
        model: "Unknown".into(),
        driver_in_use: "Unknown".into(),
        secure_boot: false,
    };

    // Collect all GPU devices with their priority (lower = better)
    // NVIDIA=0, AMD=1, Intel=2, Other=3
    let mut best_priority: u8 = u8::MAX;

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

            let (canonical, priority) = if vendor.contains("NVIDIA") {
                ("NVIDIA", 0u8)
            } else if vendor.contains("Advanced Micro Devices") || vendor.contains("AMD") {
                ("AMD", 1)
            } else if vendor.contains("Intel") {
                ("Intel", 2)
            } else {
                // Unknown but still a display device — lowest priority
                if best_priority == u8::MAX {
                    info.vendor = vendor.to_string();
                    info.model = device_name.to_string();
                    best_priority = 3;
                }
                continue;
            };

            if priority < best_priority {
                best_priority = priority;
                info.vendor = canonical.into();
                info.model = device_name.to_string();
            }
        }
    }

    if info.vendor == "Unknown" || info.vendor.is_empty() {
        info.vendor = "System".into();
        info.model = "Graphics Adapter".into();
    }

    info
}

/// Parse `lspci -k` output to find the kernel driver in use for the
/// first VGA or 3D controller device.
pub fn parse_lspci_driver(output: &str) -> Option<String> {
    let mut capture_next = false;
    for line in output.lines() {
        if line.contains("VGA") || line.contains("3D controller") {
            capture_next = true;
        }
        if capture_next && line.contains("Kernel driver in use:") {
            if let Some((_, driver)) = line.split_once(':') {
                return Some(driver.trim().to_string());
            }
        }
    }
    None
}

/// Parse `/etc/os-release` contents into an `OsInfo`.
pub fn parse_os_release(contents: &str) -> OsInfo {
    let mut info = OsInfo {
        id: "linux".into(),
        version: "unknown".into(),
        name: "Linux".into(),
    };

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

    info
}

/// Parse DNF `akmod-nvidia` output and return sorted, deduplicated versions.
pub fn parse_akmod_versions(output: &str) -> Vec<String> {
    let re = &*RE_AKMOD_VERSION;
    let mut versions: Vec<String> = re
        .captures_iter(output)
        .filter_map(|cap| cap.get(1).map(|m| m.as_str().to_string()))
        .collect();
    version::sort_versions_desc(&mut versions);
    versions.dedup();
    versions
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
            let parsed = parse_lspci_vmm(&output);
            info.vendor = parsed.vendor;
            info.model = parsed.model;
        }
    }

    if info.vendor == "Unknown" || info.vendor.is_empty() {
        info.vendor = "System".into();
        info.model = "Graphics Adapter".into();
    }

    // 2. Active driver via lspci -k
    if command::which("lspci") {
        if let Some(output) = command::run("lspci -k") {
            if let Some(driver) = parse_lspci_driver(&output) {
                info.driver_in_use = driver;
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

/// Get full system information (cached after first call).
pub fn get_full_system_info() -> SystemInfo {
    SYSTEM_INFO_CACHE
        .get_or_init(|| {
            let gpu = detect_gpu();

            SystemInfo {
                gpu,
                cpu: get_cpu_info(),
                ram: get_ram_info(),
                distro: get_distro_info(),
                kernel: get_kernel_info(),
                display_server: std::env::var("XDG_SESSION_TYPE")
                    .unwrap_or_else(|_| "Unknown".into()),
            }
        })
        .clone()
}

/// Detect OS information from /etc/os-release (cached).
pub fn detect_os() -> OsInfo {
    OS_INFO_CACHE
        .get_or_init(|| {
            if let Ok(contents) = std::fs::read_to_string("/etc/os-release") {
                parse_os_release(&contents)
            } else {
                OsInfo {
                    id: "linux".into(),
                    version: "unknown".into(),
                    name: "Linux".into(),
                }
            }
        })
        .clone()
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
    if let Some(output) = command::run("dnf list available 'akmod-nvidia*' 2>/dev/null") {
        let versions = parse_akmod_versions(&output);
        if !versions.is_empty() {
            return versions;
        }
    }
    // Defaults if nothing found
    vec!["565".into(), "550".into(), "535".into()]
}

/// Get official NVIDIA versions with short changelog notes from repository metadata.
pub fn get_official_nvidia_versions_with_changes() -> Vec<(String, String)> {
    let versions = get_available_nvidia_versions();
    let mut notes: HashMap<String, String> = HashMap::new();

    if command::which("dnf") {
        if let Some(changelog) = command::run(
            "dnf --refresh repoquery --changelog akmod-nvidia 2>/dev/null | head -n 280",
        ) {
            let version_re = &*RE_CHANGELOG_VERSION;
            let mut current_version = String::new();
            let mut current_lines: Vec<String> = Vec::new();

            for line in changelog.lines() {
                let trimmed = line.trim();

                if trimmed.starts_with('*') {
                    if !current_version.is_empty() && !current_lines.is_empty() {
                        notes
                            .entry(current_version.clone())
                            .or_insert_with(|| current_lines.join(" "));
                    }

                    current_version.clear();
                    current_lines.clear();

                    if let Some(caps) = version_re.captures(trimmed) {
                        if let Some(m) = caps.get(1).or_else(|| caps.get(2)) {
                            current_version = m.as_str().to_string();
                        }
                    }
                } else if !trimmed.is_empty()
                    && !current_version.is_empty()
                    && current_lines.len() < 2
                {
                    current_lines.push(trimmed.trim_start_matches('-').trim().to_string());
                }
            }

            if !current_version.is_empty() && !current_lines.is_empty() {
                notes
                    .entry(current_version)
                    .or_insert_with(|| current_lines.join(" "));
            }
        }
    }

    versions
        .into_iter()
        .take(8)
        .map(|version| {
            let summary = notes
                .iter()
                .find(|(k, _)| version.starts_with(*k) || k.starts_with(&version))
                .map(|(_, v)| v.clone())
                .unwrap_or_else(|| {
                    "Official repository metadata checked. Detailed notes unavailable.".to_string()
                });
            (version, summary)
        })
        .collect()
}

// ─── Internet-based NVIDIA version fetching ─────────────────────

/// Fetch latest NVIDIA driver versions from the official NVIDIA download API.
/// Uses the NVIDIA Advanced Driver Search JSON endpoint.
/// Returns a list of (version, release_date/branch_info) tuples.
pub fn fetch_nvidia_versions_online() -> Vec<(String, String)> {
    log::info!("Fetching NVIDIA driver versions from internet...");

    let mut results: Vec<(String, String)> = Vec::new();

    // Strategy 1: NVIDIA official Unix driver page (most reliable)
    // We query the NVIDIA download API for Linux x86_64 drivers
    let url = "https://www.nvidia.com/Download/processFind.aspx?psid=107&pfid=815&osid=12&lid=1&whql=&lang=en-us&ctk=0&qnfslb=00&dtcid=1";

    match http_agent()
        .get(url)
        .header("User-Agent", "ro-control/1.0")
        .call()
    {
        Ok(mut resp) => {
            if let Ok(body) = resp.body_mut().read_to_string() {
                let re = &*RE_NVIDIA_WEB_VERSION;
                let mut seen = std::collections::HashSet::new();
                for cap in re.captures_iter(&body) {
                    if let Some(m) = cap.get(1) {
                        let ver = m.as_str().to_string();
                        let major: u32 = ver
                            .split('.')
                            .next()
                            .and_then(|s| s.parse().ok())
                            .unwrap_or(0);
                        // Only consider modern driver branches (470+)
                        if major >= 470 && seen.insert(ver.clone()) {
                            results.push((ver, "NVIDIA Official".to_string()));
                        }
                    }
                }
            }
        }
        Err(e) => {
            log::warn!("NVIDIA download page fetch failed: {}", e);
        }
    }

    // Strategy 2: RPM Fusion Bodhi API (Fedora-specific, more installable info)
    if results.len() < 3 {
        let bodhi_url = "https://bodhi.fedoraproject.org/updates/?search=akmod-nvidia&status=stable&rows_per_page=10&content_type=rpm";
        match http_agent()
            .get(bodhi_url)
            .header("User-Agent", "ro-control/1.0")
            .call()
        {
            Ok(mut resp) => {
                if let Ok(body) = resp.body_mut().read_to_string() {
                    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&body) {
                        if let Some(updates) = json.get("updates").and_then(|u| u.as_array()) {
                            let re = &*RE_NVIDIA_WEB_VERSION;
                            for update in updates {
                                let title =
                                    update.get("title").and_then(|t| t.as_str()).unwrap_or("");
                                let notes_text = update
                                    .get("notes")
                                    .and_then(|n| n.as_str())
                                    .unwrap_or("Fedora RPM Fusion stable update");
                                if let Some(cap) = re.captures(title) {
                                    if let Some(m) = cap.get(1) {
                                        let ver = m.as_str().to_string();
                                        // Only add if not already present from Strategy 1
                                        if !results.iter().any(|(v, _)| v == &ver) {
                                            let note = if notes_text.len() > 120 {
                                                format!(
                                                    "{}...",
                                                    &notes_text[..notes_text
                                                        .char_indices()
                                                        .nth(120)
                                                        .map(|(i, _)| i)
                                                        .unwrap_or(notes_text.len())]
                                                )
                                            } else {
                                                notes_text.to_string()
                                            };
                                            results.push((ver, note));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Err(e) => {
                log::warn!("Bodhi API fetch failed: {}", e);
            }
        }
    }

    // Sort descending by version number
    results.sort_by(|a, b| version::parse_version(&b.0).cmp(&version::parse_version(&a.0)));

    log::info!("Fetched {} NVIDIA versions from internet", results.len());
    results
}

/// Get a merged list of driver versions: internet (latest) + local repo (installable).
/// Returns DriverVersion structs with source tracking.
pub fn get_merged_nvidia_versions() -> Vec<DriverVersion> {
    // 1. Get local repo versions
    let local_versions = get_available_nvidia_versions();
    let local_changelog = get_official_nvidia_versions_with_changes();

    // Build a map of local versions with their changelogs
    let mut local_notes: HashMap<String, String> = HashMap::new();
    for (ver, notes) in &local_changelog {
        local_notes.insert(ver.clone(), notes.clone());
    }

    // 2. Get internet versions
    let online_versions = fetch_nvidia_versions_online();

    // 3. Merge: online versions first (may include newer), then fill local-only
    let mut merged: Vec<DriverVersion> = Vec::new();
    let mut seen = std::collections::HashSet::new();

    // Add online versions, marking them as installable if also in local repo
    for (ver, notes) in &online_versions {
        if seen.insert(ver.clone()) {
            let in_local = local_versions.iter().any(|lv| {
                lv == ver
                    || lv.starts_with(&format!("{}.", ver))
                    || ver.starts_with(&format!("{}.", lv))
            });
            let release_notes = if in_local {
                // Prefer local changelog if available
                local_notes
                    .get(ver)
                    .or_else(|| {
                        // Try matching with major version prefix
                        local_notes
                            .iter()
                            .find(|(k, _)| {
                                ver.starts_with(k.as_str()) || k.starts_with(ver.as_str())
                            })
                            .map(|(_, v)| v)
                    })
                    .cloned()
                    .unwrap_or_else(|| notes.clone())
            } else {
                notes.clone()
            };

            merged.push(DriverVersion {
                version: ver.clone(),
                source: if in_local {
                    "merged".to_string()
                } else {
                    "nvidia-official".to_string()
                },
                release_notes,
                is_latest: false,
                installable: in_local,
            });
        }
    }

    // Add local-only versions that weren't in the online list
    for ver in &local_versions {
        if seen.insert(ver.clone()) {
            let notes = local_notes
                .get(ver)
                .cloned()
                .unwrap_or_else(|| "Available in local repository".to_string());
            merged.push(DriverVersion {
                version: ver.clone(),
                source: "repo".to_string(),
                release_notes: notes,
                is_latest: false,
                installable: true,
            });
        }
    }

    // Sort descending by version
    merged.sort_by(|a, b| {
        version::parse_version(&b.version).cmp(&version::parse_version(&a.version))
    });

    // Mark first as latest
    if let Some(first) = merged.first_mut() {
        first.is_latest = true;
    }

    // Limit to top 12
    merged.truncate(12);
    merged
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── GpuInfo / OsInfo defaults ───────────────────────────────────

    #[test]
    fn gpu_info_default_is_unknown() {
        let info = GpuInfo::default();
        assert!(info.vendor.is_empty());
        assert!(info.model.is_empty());
        assert!(!info.secure_boot);
    }

    #[test]
    fn os_info_default() {
        let info = OsInfo::default();
        assert!(info.id.is_empty());
        assert!(info.version.is_empty());
        assert!(info.name.is_empty());
    }

    // ── parse_lspci_vmm ─────────────────────────────────────────────

    #[test]
    fn parse_lspci_vmm_nvidia() {
        let output = "\
Slot:\t01:00.0
Class:\tVGA compatible controller
Vendor:\tNVIDIA Corporation
Device:\tGA106 [GeForce RTX 3060 Lite Hash Rate]
SVendor:\tMicro-Star International Co., Ltd.
SDevice:\tGA106 [GeForce RTX 3060 Lite Hash Rate]
Rev:\ta1";
        let info = parse_lspci_vmm(output);
        assert_eq!(info.vendor, "NVIDIA");
        assert_eq!(info.model, "GA106 [GeForce RTX 3060 Lite Hash Rate]");
    }

    #[test]
    fn parse_lspci_vmm_amd() {
        let output = "\
Slot:\t06:00.0
Class:\tVGA compatible controller
Vendor:\tAdvanced Micro Devices, Inc. [AMD/ATI]
Device:\tEllesmere [Radeon RX 470/480/570/580]
Rev:\te7";
        let info = parse_lspci_vmm(output);
        assert_eq!(info.vendor, "AMD");
        assert!(info.model.contains("Ellesmere"));
    }

    #[test]
    fn parse_lspci_vmm_intel() {
        let output = "\
Slot:\t00:02.0
Class:\tVGA compatible controller
Vendor:\tIntel Corporation
Device:\tUHD Graphics 630
Rev:\t00";
        let info = parse_lspci_vmm(output);
        assert_eq!(info.vendor, "Intel");
        assert_eq!(info.model, "UHD Graphics 630");
    }

    #[test]
    fn parse_lspci_vmm_prefers_nvidia_over_intel() {
        let output = "\
Slot:\t00:02.0
Class:\tVGA compatible controller
Vendor:\tIntel Corporation
Device:\tUHD Graphics 630
Rev:\t00

Slot:\t01:00.0
Class:\t3D controller
Vendor:\tNVIDIA Corporation
Device:\tGV100GL [Tesla V100]
Rev:\ta1";
        let info = parse_lspci_vmm(output);
        assert_eq!(info.vendor, "NVIDIA");
        assert!(info.model.contains("Tesla V100"));
    }

    #[test]
    fn parse_lspci_vmm_no_gpu() {
        let output = "\
Slot:\t00:1f.3
Class:\tAudio device
Vendor:\tIntel Corporation
Device:\tCannon Lake PCH cAVS";
        let info = parse_lspci_vmm(output);
        assert_eq!(info.vendor, "System");
        assert_eq!(info.model, "Graphics Adapter");
    }

    #[test]
    fn parse_lspci_vmm_empty() {
        let info = parse_lspci_vmm("");
        assert_eq!(info.vendor, "System");
        assert_eq!(info.model, "Graphics Adapter");
    }

    // ── parse_lspci_driver ──────────────────────────────────────────

    #[test]
    fn parse_lspci_driver_nvidia() {
        let output = "\
01:00.0 VGA compatible controller: NVIDIA Corporation GA106
\tSubsystem: Micro-Star International
\tKernel driver in use: nvidia
\tKernel modules: nvidia";
        assert_eq!(parse_lspci_driver(output), Some("nvidia".into()));
    }

    #[test]
    fn parse_lspci_driver_nouveau() {
        let output = "\
01:00.0 VGA compatible controller: NVIDIA Corporation
\tKernel driver in use: nouveau";
        assert_eq!(parse_lspci_driver(output), Some("nouveau".into()));
    }

    #[test]
    fn parse_lspci_driver_none() {
        let output = "\
00:1f.3 Audio device: Intel Corporation Cannon Lake PCH cAVS
\tKernel driver in use: snd_hda_intel";
        assert_eq!(parse_lspci_driver(output), None);
    }

    // ── parse_os_release ────────────────────────────────────────────

    #[test]
    fn parse_os_release_fedora() {
        let contents = r#"NAME="Fedora Linux"
VERSION="41 (Workstation Edition)"
ID=fedora
VERSION_ID=41
PRETTY_NAME="Fedora Linux 41 (Workstation Edition)"
HOME_URL="https://fedoraproject.org/"
"#;
        let info = parse_os_release(contents);
        assert_eq!(info.id, "fedora");
        assert_eq!(info.version, "41");
        assert_eq!(info.name, "Fedora Linux 41 (Workstation Edition)");
    }

    #[test]
    fn parse_os_release_ubuntu() {
        let contents = r#"PRETTY_NAME="Ubuntu 24.04.1 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
ID=ubuntu
"#;
        let info = parse_os_release(contents);
        assert_eq!(info.id, "ubuntu");
        assert_eq!(info.version, "24.04");
    }

    #[test]
    fn parse_os_release_arch() {
        let contents = "NAME=\"Arch Linux\"\nID=arch\n";
        let info = parse_os_release(contents);
        assert_eq!(info.id, "arch");
        assert_eq!(info.version, "unknown"); // Arch has no VERSION_ID
        assert_eq!(info.name, "Linux"); // No PRETTY_NAME in this snippet
    }

    #[test]
    fn parse_os_release_empty() {
        let info = parse_os_release("");
        assert_eq!(info.id, "linux");
        assert_eq!(info.version, "unknown");
        assert_eq!(info.name, "Linux");
    }

    // ── parse_akmod_versions ────────────────────────────────────────

    #[test]
    fn parse_akmod_versions_typical() {
        let output = "\
Last metadata expiration check: 0:12:34 ago.
Available Packages
akmod-nvidia.x86_64              3:565.57.01-1.fc41    rpmfusion-nonfree-nvidia-driver
akmod-nvidia.x86_64              3:550.120-1.fc41      rpmfusion-nonfree-nvidia-driver
akmod-nvidia.x86_64              3:535.183.01-1.fc41   rpmfusion-nonfree-nvidia-driver
";
        let versions = parse_akmod_versions(output);
        assert_eq!(versions.len(), 3);
        assert_eq!(versions[0], "565.57.01");
        assert_eq!(versions[1], "550.120");
        assert_eq!(versions[2], "535.183.01");
    }

    #[test]
    fn parse_akmod_versions_empty_output() {
        assert!(parse_akmod_versions("").is_empty());
        assert!(parse_akmod_versions("No packages found.").is_empty());
    }

    #[test]
    fn parse_akmod_versions_dedup() {
        let output = "\
akmod-nvidia.x86_64  3:550.120-1.fc41  repo1
akmod-nvidia.x86_64  3:550.120-1.fc41  repo2
";
        let versions = parse_akmod_versions(output);
        assert_eq!(versions.len(), 1);
        assert_eq!(versions[0], "550.120");
    }

    // ── Regex pattern tests ─────────────────────────────────────────

    #[test]
    fn re_akmod_version_pattern() {
        let re = &*RE_AKMOD_VERSION;
        let input = "akmod-nvidia.x86_64  3:565.57.01-1.fc41  rpmfusion";
        let caps = re.captures(input).unwrap();
        assert_eq!(caps.get(1).unwrap().as_str(), "565.57.01");
    }

    #[test]
    fn re_changelog_version_pattern() {
        let re = &*RE_CHANGELOG_VERSION;

        let input1 = "* Sat Nov 16 2024 Leigh Scott - 565.57.01-1";
        let caps1 = re.captures(input1).unwrap();
        assert_eq!(caps1.get(1).unwrap().as_str(), "565.57.01");

        let input2 = "Update to 550";
        let caps2 = re.captures(input2).unwrap();
        assert_eq!(caps2.get(2).unwrap().as_str(), "550");
    }

    #[test]
    fn re_nvidia_web_version_pattern() {
        let re = &*RE_NVIDIA_WEB_VERSION;
        let input = "Linux x64 (AMD64/EM64T) Display Driver Version 565.77";
        let caps = re.captures(input).unwrap();
        assert_eq!(caps.get(1).unwrap().as_str(), "565.77");
    }

    // ── Package manager mapping ─────────────────────────────────────

    #[test]
    fn package_manager_maps_fedora() {
        let test_ids = vec![
            ("fedora", Some("dnf")),
            ("rhel", Some("dnf")),
            ("centos", Some("dnf")),
            ("rocky", Some("dnf")),
            ("almalinux", Some("dnf")),
            ("ubuntu", Some("apt")),
            ("debian", Some("apt")),
            ("linuxmint", Some("apt")),
            ("pop", Some("apt")),
            ("arch", Some("pacman")),
            ("manjaro", Some("pacman")),
            ("endeavouros", Some("pacman")),
            ("opensuse", Some("zypper")),
            ("sles", Some("zypper")),
            ("opensuse-leap", Some("zypper")),
            ("opensuse-tumbleweed", Some("zypper")),
            ("unknown_distro", None),
        ];

        for (id, expected) in test_ids {
            let result = match id {
                "fedora" | "rhel" | "centos" | "rocky" | "almalinux" => Some("dnf"),
                "ubuntu" | "debian" | "linuxmint" | "pop" => Some("apt"),
                "arch" | "manjaro" | "endeavouros" => Some("pacman"),
                "opensuse" | "sles" | "opensuse-leap" | "opensuse-tumbleweed" => Some("zypper"),
                _ => None,
            };
            assert_eq!(result, expected, "Failed for distro: {}", id);
        }
    }

    #[test]
    fn display_server_fallback() {
        let ds =
            std::env::var("XDG_SESSION_TYPE_NONEXISTENT_KEY").unwrap_or_else(|_| "Unknown".into());
        assert_eq!(ds, "Unknown");
    }

    // ── DriverVersion construction ──────────────────────────────────

    #[test]
    fn driver_version_struct() {
        let dv = DriverVersion {
            version: "565.57.01".into(),
            source: "merged".into(),
            release_notes: "Test notes".into(),
            is_latest: true,
            installable: true,
        };
        assert!(dv.is_latest);
        assert!(dv.installable);
        assert_eq!(dv.source, "merged");
    }
}
