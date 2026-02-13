// Application-wide constants

/// Reverse-domain App ID (FreeDesktop / Flatpak standard)
pub const APP_ID: &str = "io.github.AcikKaynakGelistirmeToplulugu.ro-control";

/// Default window dimensions
pub const DEFAULT_WIDTH: i32 = 950;
pub const DEFAULT_HEIGHT: i32 = 680;

/// Binary / package name
pub const APP_NAME: &str = "ro-control";

/// Display name shown in window titles and about dialogs
pub const PRETTY_NAME: &str = "ro-Control";

/// Semantic version (keep in sync with Cargo.toml)
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

/// GitHub owner/repo path
pub const GITHUB_REPO: &str = "Acik-Kaynak-Gelistirme-Toplulugu/ro-control";

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
pub const HOMEPAGE: &str = "https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-control";

/// Bug tracker URL
pub const ISSUE_URL: &str = "https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-control/issues";

/// Changelog (shown in about dialog)
pub const CHANGELOG: &str = "\
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
