# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-02-26

### Added

- Premium "Rust Edition" UI redesign with modern, vibrant aesthetic
- Animated 🦀 branding throughout the application (header, sidebar, progress)
- `StatusBar` component showing Driver, Secure Boot, and GPU info at a glance
- `CustomProgressBar` with gradient fill, color thresholds, glossy overlay, and pulsing indicator
- `GradientButton` with shimmer hover effect
- `StepItem` with emoji status icons and slide-in animations
- Info grid cards on Performance page with emoji icons (💻🔧⚙️🧠🎮📊)
- Animated background gradient on main window
- "Rust Powered" badge in header and sidebar version badge
- About dialog accessible from sidebar Rust badge
- App update dialog with release notes display

### Changed

- Color palette updated to modern blue/purple/emerald scheme
- ActionCard redesigned as Button-based component with gradient overlays
- ExpertPage version selector redesigned with inline radio-button delegates
- All pages now use consistent frontend design language
- Header redesigned with glass effect and 🦀 logo animation

### Fixed

- Missing QML files in `build.rs` (CustomProgressBar, GradientButton, StatusBar)
- `install_log` terminal panel restored in ProgressPage
- `app_update_available` and `install_app_update()` properly connected in UI

[1.1.0]: https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/releases/tag/v1.1.0

## [1.0.0] - 2026-02-14

### Added

- Major architecture refresh focused on performance and memory safety
- Modernized desktop interface across Linux environments
- NVIDIA proprietary driver installation via RPM Fusion (`akmod-nvidia`)
- NVIDIA Open Kernel module installation
- Driver removal with optional deep clean
- Live GPU monitoring (temperature, load, VRAM) via `nvidia-smi`
- Live system monitoring (CPU load, CPU temperature, RAM usage)
- Feral GameMode one-click installation
- Flatpak/Steam permission repair utility
- NVIDIA Wayland fix (`nvidia-drm.modeset=1` via GRUB)
- Hybrid graphics switching (switcheroo-control / prime-select)
- Automatic update checking via GitHub Releases API
- Turkish and English bilingual interface
- PolicyKit integration for secure privilege escalation
- Timeshift snapshot creation before driver operations
- Secure Boot detection and warning
- System diagnostic report generation

### Changed

- Reworked core modules and project layout
- Package management focused on DNF/RPM Fusion (Fedora-first)
- Initramfs regeneration uses `dracut` (Fedora-native)
- Desktop entry and metainfo follow latest FreeDesktop standards
- Icon follows hicolor theme specification (scalable SVG + symbolic)

### Removed

- macOS development simulation mode
- React/Vite web UI (tema/)
- Debian `.deb` packaging (replaced by `.rpm`)
- Unused runtime dependencies

[1.0.0]: https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/releases/tag/v1.0.0
