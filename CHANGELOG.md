# Changelog

All notable changes to **ro-Control** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.3.0] - 2026-09-01

### Added
- **GPU Power & TDP Management Subsystem:**
  - Dynamic power limit control (`PowerController`) via Polkit and `nvidia-smi`.
  - Power preset switching (`Eco`, `Balanced`, `Performance`, `Custom`).
  - NVIDIA Driver persistence mode toggle and status tracking.
  - CLI integration: `ro-control power status [--json]`, `ro-control power set-limit <watts>`, `ro-control power set-preset <preset>`, `ro-control power set-persistence <on|off>`.
- **System Tray & Thermal Health Guard:**
  - `HealthGuard` subsystem with configurable thermal warning and critical limits.
  - Native desktop notifications (`QSystemTrayIcon::showMessage`) for critical overheating warnings.
  - Live tooltip with GPU temperature, fan RPM, and live power draw.
  - Context menu with quick Fan profile and Power preset switching.
- **Sentinel D-Bus IPC Service & Daemon Mode:**
  - Native D-Bus service registered at `io.github.ProjectRoASD.rocontrol` (`/io/github/ProjectRoASD/rocontrol`).
  - Methods for external telemetry queries (`GetTelemetry`, `GetThermalStatus`, `GetGpuHealth`) and hardware control (`SetFanMode`, `SetFanSpeed`, `SetPowerLimit`, `SetPersistenceMode`).
  - Signals: `ThermalAlert`, `TelemetryUpdated`.
  - Headless daemon CLI command: `ro-control --daemon`.
- **Test Suite Expansion:**
  - Added unit test suites for `PowerController`, `HealthGuard`, and `RoControlDBusService` (12/12 test targets passing 100%).

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
