# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-14

### Added

- Complete rewrite in Rust for native performance and memory safety
- GTK4 + libadwaita UI — compatible with KDE Plasma, GNOME, and other desktops
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

- Migrated from Python/PyGObject to Rust/gtk4-rs
- Package management focused on DNF/RPM Fusion (Fedora-first)
- Initramfs regeneration uses `dracut` (Fedora-native)
- Desktop entry and metainfo follow latest FreeDesktop standards
- Icon follows hicolor theme specification (scalable SVG + symbolic)

### Removed

- macOS development simulation mode
- React/Vite web UI (tema/)
- Debian `.deb` packaging (replaced by `.rpm`)
- Python runtime dependency

[1.0.0]: https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/releases/tag/v1.0.0
