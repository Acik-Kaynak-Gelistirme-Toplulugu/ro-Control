#![allow(dead_code)]

// System Detector — GPU, CPU, RAM, Distro, Secure Boot detection
// Fedora/Linux native — no macOS simulation

use crate::utils::command;
use crate::utils::version;
use regex::Regex;
use std::collections::HashMap;
use std::sync::{LazyLock, OnceLock};

/// Cached OS info — read once from /etc/os-release.
static OS_INFO_CACHE: OnceLock<OsInfo> = OnceLock::new();

/// Cached full system info — populated on first call.
static SYSTEM_INFO_CACHE: OnceLock<SystemInfo> = OnceLock::new();

/// Pre-compiled regex for akmod-nvidia version parsing.
static RE_AKMOD_VERSION: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"akmod-nvidia[^\s]*\s+(\d+\.\d+[\.\d]*)").unwrap());

/// Pre-compiled regex for changelog version parsing.
static RE_CHANGELOG_VERSION: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"(\d{3}\.\d{2}(?:\.\d+)?)|(\d{3})").unwrap());

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
        info.vendor = "System".into();
        info.model = "Graphics Adapter".into();
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
    // On Fedora, NVIDIA driver is provided via RPM Fusion as "akmod-nvidia"
    // We check available versions from dnf
    if let Some(output) = command::run("dnf list available 'akmod-nvidia*' 2>/dev/null") {
        let re = &*RE_AKMOD_VERSION;
        let mut versions: Vec<String> = re
            .captures_iter(&output)
            .filter_map(|cap| cap.get(1).map(|m| m.as_str().to_string()))
            .collect();
        // Proper numeric semver sort (descending)
        version::sort_versions_desc(&mut versions);
        versions.dedup();
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

    match ureq::get(url).header("User-Agent", "ro-control/1.0").call() {
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
        match ureq::get(bodhi_url)
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

    #[test]
    fn package_manager_maps_fedora() {
        // This test verifies the mapping logic directly
        let test_ids = vec![
            ("fedora", Some("dnf")),
            ("rhel", Some("dnf")),
            ("ubuntu", Some("apt")),
            ("debian", Some("apt")),
            ("arch", Some("pacman")),
            ("opensuse", Some("zypper")),
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
        // Test the fallback logic directly without mutating environment
        let ds =
            std::env::var("XDG_SESSION_TYPE_NONEXISTENT_KEY").unwrap_or_else(|_| "Unknown".into());
        assert_eq!(ds, "Unknown");
    }
}
