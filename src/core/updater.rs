#![allow(dead_code)]

// Application self-updater via GitHub Releases API

use crate::config;
use serde::Deserialize;

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

    let mut response = match ureq::get(&url)
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

    if compare_versions(&latest_tag, current_ver) > 0 {
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

    let tmp_path = "/tmp/ro-control-update.rpm";

    // Download
    match ureq::get(url).call() {
        Ok(response) => {
            let mut file = match std::fs::File::create(tmp_path) {
                Ok(f) => f,
                Err(e) => {
                    log::error!("Failed to create temp file: {}", e);
                    return false;
                }
            };
            if let Err(e) = std::io::copy(&mut response.into_body().as_reader(), &mut file) {
                log::error!("Download failed: {}", e);
                return false;
            }
        }
        Err(e) => {
            log::error!("Download request failed: {}", e);
            return false;
        }
    }

    log::info!("Download complete, installing...");

    // Install via dnf
    let cmd = format!(
        r#"pkexec ro-control-root-task "dnf install -y {}""#,
        tmp_path
    );
    let (code, _, err) = crate::utils::command::run_full(&cmd);

    // Cleanup
    let _ = std::fs::remove_file(tmp_path);

    if code == 0 {
        log::info!("Update installed successfully.");
        true
    } else {
        log::error!("Update installation failed: {}", err);
        false
    }
}

/// Compare semver strings. Returns positive if v1 > v2.
fn compare_versions(v1: &str, v2: &str) -> i32 {
    let parse =
        |v: &str| -> Vec<u32> { v.split('.').filter_map(|s| s.parse::<u32>().ok()).collect() };

    let p1 = parse(v1);
    let p2 = parse(v2);

    for i in 0..p1.len().max(p2.len()) {
        let a = p1.get(i).copied().unwrap_or(0);
        let b = p2.get(i).copied().unwrap_or(0);
        if a > b {
            return 1;
        }
        if a < b {
            return -1;
        }
    }
    0
}
