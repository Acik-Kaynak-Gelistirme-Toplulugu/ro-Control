// Application-wide constants

/// Reverse-domain App ID (FreeDesktop / Flatpak standard)
pub const APP_ID: &str = "io.github.AcikKaynakGelistirmeToplulugu.ro-control";

/// Default window dimensions
#[allow(dead_code)]
pub const DEFAULT_WIDTH: i32 = 950;
#[allow(dead_code)]
pub const DEFAULT_HEIGHT: i32 = 680;

/// Binary / package name
pub const APP_NAME: &str = "ro-control";

/// Display name shown in window titles and about dialogs
pub const PRETTY_NAME: &str = "ro-Control";

/// Semantic version (keep in sync with Cargo.toml)
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

/// GitHub owner/repo path
pub const GITHUB_REPO: &str = "Acik-Kaynak-Gelistirme-Toplulugu/ro-Control";

/// Organization / developer name
pub const DEVELOPER_NAME: &str = "Açık Kaynak Geliştirme Topluluğu";

/// Maintainer line
pub const MAINTAINER: &str = "AKGT <info@akgt.dev>";

/// Short description (English)
pub const DESCRIPTION: &str =
    "Smart GPU driver manager for Linux — install, configure and monitor NVIDIA graphics drivers.";

/// Short description (Turkish)
pub const DESCRIPTION_TR: &str =
    "Linux için akıllı GPU sürücü yöneticisi — NVIDIA ekran kartı sürücülerini kurun, yapılandırın ve izleyin.";

/// Project homepage
pub const HOMEPAGE: &str = "https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control";

/// Bug tracker URL
pub const ISSUE_URL: &str = "https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/issues";

/// Changelog (shown in about dialog)
pub const CHANGELOG: &str = "\
v1.2.0  — Security Hardening & CI
  • Root-task rewrite: multi-arg architecture blocks injection
  • Critical fix: kernel version parsing, driver version detection
  • POSIX-portable which() via command -v
  • RPM epoch-aware version regex
  • Log rotation, trusted domain validation
  • CI: Fedora 42, RPM deploy pipeline

v1.1.0  — Rust Edition UI Redesign
  • Premium 🦀 Rust Edition branding and visual identity
  • Modern color palette (blue/purple/emerald)
  • StatusBar, CustomProgressBar, GradientButton components
  • Emoji info grid cards on Performance page
  • Animated backgrounds, shimmer effects, gradient overlays
  • About dialog and app update dialog
  • Log output panel restored in ProgressPage

v1.0.0  — Initial Rust release
  • NVIDIA proprietary driver install via RPM Fusion (akmod-nvidia)
  • NVIDIA Open Kernel module install
  • Live GPU/CPU/RAM performance dashboard
  • Feral GameMode integration
  • Flatpak/Steam permission repair
  • NVIDIA Wayland fix (nvidia-drm.modeset=1)
  • Hybrid graphics switching
  • Auto-update via GitHub Releases
  • Turkish / English bilingual UI
";

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn version_is_set() {
        assert!(!VERSION.is_empty(), "VERSION must not be empty");
        // Should look like semver: at least one digit and one dot
        assert!(
            VERSION.contains('.'),
            "VERSION should be semver: {}",
            VERSION
        );
    }

    #[test]
    fn app_id_is_reverse_domain() {
        assert!(
            APP_ID.chars().filter(|&c| c == '.').count() >= 2,
            "APP_ID must be reverse-domain notation"
        );
        assert!(APP_ID.starts_with("io.github."));
    }

    #[test]
    fn github_repo_has_owner_and_name() {
        assert!(GITHUB_REPO.contains('/'), "GITHUB_REPO must be owner/repo");
        let parts: Vec<&str> = GITHUB_REPO.split('/').collect();
        assert_eq!(parts.len(), 2);
        assert!(!parts[0].is_empty());
        assert!(!parts[1].is_empty());
    }

    #[test]
    fn urls_are_https() {
        assert!(HOMEPAGE.starts_with("https://"));
        assert!(ISSUE_URL.starts_with("https://"));
    }

    #[test]
    fn window_dimensions_sane() {
        const { assert!(DEFAULT_WIDTH > 0 && DEFAULT_WIDTH < 10000) };
        const { assert!(DEFAULT_HEIGHT > 0 && DEFAULT_HEIGHT < 10000) };
    }

    #[test]
    fn changelog_is_not_empty() {
        assert!(!CHANGELOG.is_empty());
        assert!(CHANGELOG.contains("v1."));
    }

    #[test]
    fn names_are_set() {
        assert!(!APP_NAME.is_empty());
        assert!(!PRETTY_NAME.is_empty());
        assert!(!DEVELOPER_NAME.is_empty());
        assert!(!MAINTAINER.is_empty());
        assert!(!DESCRIPTION.is_empty());
        assert!(!DESCRIPTION_TR.is_empty());
    }
}
