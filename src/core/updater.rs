#![allow(dead_code)]

// Application self-updater via GitHub Releases API

use crate::config;
use serde::Deserialize;
use std::time::Duration;

/// HTTP agent with a 30-second global timeout.
fn http_agent() -> ureq::Agent {
    let config = ureq::Agent::config_builder()
        .timeout_global(Some(Duration::from_secs(30)))
        .build();
    config.into()
}

#[derive(Debug, Deserialize)]
struct GithubRelease {
    tag_name: String,
    body: Option<String>,
    assets: Vec<GithubAsset>,
}

#[derive(Debug, Deserialize)]
struct GithubAsset {
    name: String,
    browser_download_url: String,
}

#[derive(Debug)]
pub struct UpdateInfo {
    pub has_update: bool,
    pub version: String,
    pub download_url: Option<String>,
    pub release_notes: String,
}

/// Check GitHub releases for updates.
pub fn check_for_updates() -> UpdateInfo {
    let no_update = UpdateInfo {
        has_update: false,
        version: String::new(),
        download_url: None,
        release_notes: String::new(),
    };

    let url = format!(
        "https://api.github.com/repos/{}/releases/latest",
        config::GITHUB_REPO
    );

    let mut response = match http_agent()
        .get(&url)
        .header("User-Agent", &format!("{}-Updater", config::APP_NAME))
        .call()
    {
        Ok(resp) => resp,
        Err(e) => {
            log::warn!("Update check failed: {}", e);
            return no_update;
        }
    };

    let release: GithubRelease = match response.body_mut().read_json() {
        Ok(r) => r,
        Err(e) => {
            log::warn!("Failed to parse GitHub response: {}", e);
            return no_update;
        }
    };

    let latest_tag = release.tag_name.trim_start_matches('v').to_string();
    let current_ver = config::VERSION.trim_start_matches('v');

    if crate::utils::version::compare_versions(&latest_tag, current_ver) > 0 {
        // Find RPM asset (Fedora)
        let rpm_url = release
            .assets
            .iter()
            .find(|a| a.name.ends_with(".rpm"))
            .map(|a| a.browser_download_url.clone());

        UpdateInfo {
            has_update: true,
            version: latest_tag,
            download_url: rpm_url,
            release_notes: release.body.unwrap_or_default(),
        }
    } else {
        no_update
    }
}

/// Download and install RPM update.
pub fn download_and_install(url: &str) -> bool {
    log::info!("Downloading update from: {}", url);

    // Use unique temp path to prevent symlink/TOCTOU attacks
    let tmp_path = format!(
        "/tmp/ro-control-update-{}-{}.rpm",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs()
    );

    // Download
    match http_agent().get(url).call() {
        Ok(response) => {
            let mut file = match std::fs::File::create(&tmp_path) {
                Ok(f) => f,
                Err(e) => {
                    log::error!("Failed to create temp file: {}", e);
                    return false;
                }
            };
            if let Err(e) = std::io::copy(&mut response.into_body().as_reader(), &mut file) {
                log::error!("Download failed: {}", e);
                let _ = std::fs::remove_file(&tmp_path);
                return false;
            }
        }
        Err(e) => {
            log::error!("Download request failed: {}", e);
            return false;
        }
    }

    log::info!("Download complete, installing...");

    // Validate download URL domain
    const TRUSTED_DOMAINS: &[&str] = &[
        "https://github.com/",
        "https://objects.githubusercontent.com/",
    ];
    if !TRUSTED_DOMAINS.iter().any(|d| url.starts_with(d)) {
        log::error!("Untrusted download URL: {}", url);
        let _ = std::fs::remove_file(&tmp_path);
        return false;
    }

    // Install via dnf using multi-arg pkexec
    let output = std::process::Command::new("pkexec")
        .arg("ro-control-root-task")
        .arg(format!("dnf install -y {}", tmp_path))
        .output();

    // Cleanup
    let _ = std::fs::remove_file(&tmp_path);

    match output {
        Ok(o) if o.status.success() => {
            log::info!("Update installed successfully.");
            true
        }
        Ok(o) => {
            let err = String::from_utf8_lossy(&o.stderr);
            log::error!("Update installation failed: {}", err);
            false
        }
        Err(e) => {
            log::error!("Failed to execute update: {}", e);
            false
        }
    }
}

/// Compare semver strings. Delegates to shared utility.
fn compare_versions(v1: &str, v2: &str) -> i32 {
    crate::utils::version::compare_versions(v1, v2)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn compare_equal_versions() {
        assert_eq!(compare_versions("1.0.0", "1.0.0"), 0);
        assert_eq!(compare_versions("2.5.3", "2.5.3"), 0);
    }

    #[test]
    fn compare_greater_version() {
        assert_eq!(compare_versions("2.0.0", "1.0.0"), 1);
        assert_eq!(compare_versions("1.1.0", "1.0.0"), 1);
        assert_eq!(compare_versions("1.0.1", "1.0.0"), 1);
    }

    #[test]
    fn compare_lesser_version() {
        assert_eq!(compare_versions("1.0.0", "2.0.0"), -1);
        assert_eq!(compare_versions("1.0.0", "1.1.0"), -1);
        assert_eq!(compare_versions("1.0.0", "1.0.1"), -1);
    }

    #[test]
    fn compare_different_length_versions() {
        assert_eq!(compare_versions("1.0", "1.0.0"), 0);
        assert_eq!(compare_versions("1.0.1", "1.0"), 1);
        assert_eq!(compare_versions("1", "1.0.0"), 0);
    }

    #[test]
    fn compare_nvidia_style_versions() {
        assert_eq!(compare_versions("565.57.01", "550.120"), 1);
        assert_eq!(compare_versions("535.183", "550.120"), -1);
    }
}
