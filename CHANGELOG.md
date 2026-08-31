# Changelog

All notable changes to **ro-Control** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v1.2.1] - 2026-08-31

### Fixed
- Isolated GPU monitor tests from host `hwmon` and PCI device state.
- Validated native Fedora 44 RPM builds on both x86_64 and aarch64 runners.

### Packaging
- Restored canonical NVRA filenames for binary RPM artifacts.
- Added source RPM, exact source archive, and release checksum publication.
- Enabled install and CLI smoke tests for both supported architectures.

---

## [v1.2.0] - 2026-08-27

### Added
- **Dedicated Cooling & Fan Management Subsystem:**
  - Hardware-aware multi-fan detection for CPU and GPU fans via `hwmon` and vendor interfaces.
  - Interactive fan cards with real-time RPM telemetry, percentage indicators, and mode presets (Auto, Quiet, Balanced, Performance).
  - Custom temperature-to-RPM fan curve mapping and persistent configuration.
- **Architecture & CLI Enhancements:**
  - `ro-control --fan-status`, `--set-fan-speed`, and related cooling CLI commands.
  - Unified fan topology reporting across diverse hardware configurations.
- **Build & CI Automation:**
  - CMake custom targets `format` (`clang-format -i`) and `check-format` (`clang-format --dry-run --Werror`).
  - Automated dual-architecture (`x86_64` and `aarch64`) RPM packaging and release pipeline.

### Fixed
- **Headless & Virtualized Runner Compatibility:**
  - Fixed topology initialization in environments without dedicated GPU fan control (virtualized/CI runners), ensuring robust test execution.
- **UI & UX Polish:**
  - Streamlined cooling view layout, cleaned up duplicate setting icons, and aligned GPU naming conventions.
  - Improved responsive sizing and theme integration under KDE Plasma / Wayland.
- **Code Quality:**
  - Standardized C++20 formatting across all source and test files.

---

## [v1.1.0] - 2026-05-10

### Added
- Standalone architecture RPMs for `x86_64` and `aarch64` without companion noarch requirement.
- Full AppStream metadata integration with live screenshots and localized descriptions.
- Shell completions for Bash, Zsh, and Fish.

### Fixed
- Polkit helper permission rules alignment for non-root system control actions.
- Target Fedora 43+ build matrix synchronization.

---

## [v0.2.1] - 2026-03-30

### Added
- Initial power profile management and battery charge threshold control.
- Core D-Bus service integration and daemon lifecycle management.
- Qt6 / QML desktop shell UI foundation.
