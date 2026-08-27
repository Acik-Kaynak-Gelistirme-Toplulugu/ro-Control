# ro-Control

**Native Qt6 / QML Desktop Application for NVIDIA Driver Management, Hardware Telemetry, and Multi-Fan Cooling Control on Ro-ASD.**

[![License: GPL-3.0-or-later](https://img.shields.io/badge/License-GPL--3.0--or--later-blue.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux%20(Fedora%20%7C%20Wayland%20%7C%20X11)-green.svg)](https://github.com/Project-Ro-ASD)
[![Qt: 6.8+](https://img.shields.io/badge/Qt-6.8%2B%20(C%2B%2B20)-orange.svg)](https://www.qt.io/)
[![Build: CMake / Ninja](https://img.shields.io/badge/Build-CMake%20%7C%20Ninja-blueviolet.svg)](CMakeLists.txt)
[![Project: Ro-ASD](https://img.shields.io/badge/Ecosystem-Project--Ro--ASD-red.svg)](https://github.com/Project-Ro-ASD)

---

## Overview

**ro-Control** is a high-performance, native Linux system utility built with **C++20** and **Qt6/QML**. It serves as the primary GPU driver and cooling control center for the **Project-Ro-ASD** Linux ecosystem, providing:

1. **NVIDIA Driver Management:** Automated discovery, installation, updates, and deep-cleaning via distribution package managers (`dnf`, `akmods`, `kmod`).
2. **Real-time Hardware Telemetry:** Sub-second monitoring of CPU, GPU (NVML), RAM, and VRAM with high-contrast, theme-aware visuals.
3. **Advanced Cooling & Fan Suite:** Multi-fan hardware discovery (NVIDIA GPU Fan, Intel/AMD CPU Cooler, Chassis airflow fans), 6 optimization profiles, custom temperature-speed curves, and one-click Coolbits fan control unlock.
4. **Headless CLI & Automation:** Rich command-line interface for headless server administration, JSON telemetry export, and automated driver maintenance scripts.

---

## Key Features

### 1. NVIDIA Driver Manager
- **Automated GPU Detection:** Scans PCI buses (`pciutils`) and kernel modules to detect GeForce, Quadro, and RTX series GPUs.
- **One-Click Installation & Updates:** Interacts with PolKit (`pkexec`) to execute driver transactions securely without running the entire GUI as root.
- **Secure Boot Awareness:** Inspects MOK keys and kernel signature enforcement to warn about unsigned driver modules before reboots.
- **Deep Clean & Recovery:** Complete removal of broken DKMS/Akmods states and clean reinstallation.

### 2. Dedicated Cooling & Fan Suite
- **Multi-Fan Discovery:** Automatically identifies GPU fans, CPU coolers via `coretemp`/sysfs, and motherboard chassis fans.
- **6 Optimization Profiles:**
  - **Auto:** Default hardware VBIOS/BIOS curve.
  - **Silent:** Acoustic priority curve with delayed ramp-up for quiet desktop operation.
  - **Balanced:** Proportional thermal-acoustic equilibrium.
  - **Performance:** Aggressive high-airflow cooling for heavy compute/gaming workloads.
  - **Manual:** Precise user-defined fixed fan speed slider (0–100%).
  - **Custom:** Multi-point interactive temperature-to-speed curve with hysteresis.
- **NVIDIA Coolbits Helper:** Automated detection and setup of `/etc/X11/xorg.conf.d/99-nvidia-coolbits.conf` to unlock manual GPU fan write privileges.
- **Thermal Safety Guard:** Emergency override automatically locks fans to 100% if GPU or CPU temperatures exceed critical thresholds (85°C+).

### 3. Live System Telemetry Dashboard
- GPU Clock speeds (Core/Memory), VRAM allocation, power draw, and per-process GPU memory list.
- CPU utilization percentage, per-core metrics, and package temperatures.
- System RAM usage, available memory, and swap allocation.

### 4. Modern Desktop UI & Accessibility
- **Fluid Layout & High-DPI Support:** Crisp rendering on 1080p, 2K, and 4K displays with stabilized window resizing and fullscreen transitions.
- **Light & Dark Theme Parity:** Fully compliant WCAG AA contrast palettes for optimal readability in any lighting environment.
- **Multilingual Support:** Runtime translations for English (`en`), Turkish (`tr`), German (`de`), and Spanish (`es`).

---

## Build & Installation Guide

### Prerequisites & Dependencies

#### Fedora / RHEL (Recommended)
```bash
sudo dnf install -y \
  cmake extra-cmake-modules gcc-c++ ninja-build \
  qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qttools-devel qt6-qtwayland-devel \
  kf6-qqc2-desktop-style polkit-devel pciutils mokutil kmod lm_sensors
```

#### Debian / Ubuntu / Linux Mint
```bash
sudo apt update && sudo apt install -y \
  cmake ninja-build g++ build-essential \
  qt6-base-dev qt6-declarative-dev qt6-tools-dev qt6-wayland \
  libpolkit-gobject-1-dev pciutils mokutil kmod lm-sensors
```

#### Arch Linux / Manjaro
```bash
sudo pacman -S --needed \
  cmake ninja gcc qt6-base qt6-declarative qt6-tools qt6-wayland \
  polkit pciutils kmod lm_sensors
```

---

### Compiling from Source

```bash
# 1. Clone the repository
git clone https://github.com/Project-Ro-ASD/ro-Control.git
cd ro-Control

# 2. Configure CMake with Ninja
cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_TESTS=ON

# 3. Build all targets in parallel
cmake --build build --parallel $(nproc)

# 4. Run the test suite
ctest --test-dir build --output-on-failure
```

---

### Running the Application

#### Launch Desktop GUI:
```bash
./build/ro-control
```

#### Install to System:
```bash
sudo cmake --install build --prefix /usr
```

---

## CLI & Headless Usage Guide

`ro-control` provides a rich command-line mode for diagnostics, automated server administration, and JSON piping.

### Commands

| Command | Description |
| :--- | :--- |
| `ro-control status` | Prints brief human-readable GPU, driver, and system status. |
| `ro-control status --json` | Exports complete system and GPU telemetry as JSON. |
| `ro-control fan-status` | Displays active fan modes, speeds, RPMs, and temperatures. |
| `ro-control fan-status --json` | Exports multi-fan telemetry as JSON. |
| `ro-control diagnostics` | Comprehensive hardware, Secure Boot, kernel, and driver report. |
| `ro-control check-updates` | Checks repository for available NVIDIA driver packages. |
| `ro-control install-driver` | Triggers non-interactive driver installation via PolKit. |

### CLI Examples

```bash
# Get quick fan telemetry
./build/ro-control fan-status

# Export structured JSON diagnostics
./build/ro-control diagnostics --json | jq .

# Check GPU status in terminal
./build/ro-control status
```

---

## Project Architecture & Layout

```text
ro-Control/
├── CMakeLists.txt              # Root CMake build configuration
├── src/
│   ├── main.cpp                # Application entry point & CLI dispatcher
│   ├── backend/
│   │   ├── fan/                # FanController, curve interpolation, sysfs/NVML/Coolbits
│   │   ├── monitor/            # CpuMonitor, GpuMonitor (NVML), RamMonitor
│   │   ├── nvidia/             # NvidiaDetector, NvidiaInstaller, NvidiaUpdater
│   │   └── system/             # PolkitHelper, SystemInfoProvider, UiPreferences
│   ├── cli/                    # Headless CLI argument parser & JSON formatters
│   └── qml/                    # Qt6/QML Desktop UI
│       ├── Main.qml            # Main ApplicationWindow shell
│       ├── assets/             # SVG icons, logos, refresh assets
│       ├── components/         # Reusable widgets, gauges, toolbars
│       └── pages/              # DriverPage, MonitorPage, FanPage
├── tests/                      # CTest / QTest unit and integration tests
├── scripts/                    # Bootstrap & development watch scripts
└── resources/                  # AppStream metadata, desktop file, PolKit policies
```

---

## Testing

Run the automated test suite with CTest:

```bash
ctest --test-dir build --output-on-failure --verbose
```

Test coverage includes:
- `test_detector`: PCI device scan and NVIDIA hardware recognition.
- `test_fan_controller`: Fan profile curves, hysteresis limits, and thermal safety overrides.
- `test_monitor`: CPU, GPU, RAM telemetry accuracy and threshold parsing.
- `test_system_integration`: PolKit privileged execution and CLI action dispatching.
- `test_driver_page`: UI data models and localized preference loading.

---

## Contributing

Contributions from the open-source community are welcome!
1. Fork the repository on GitHub.
2. Create a feature branch: `git checkout -b feat/my-new-feature`
3. Commit your changes: `git commit -m "feat(cooling): add support for custom sensors"`
4. Push to your branch and open a Pull Request against `main`.

See [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

---

## Security

For security vulnerabilities and reporting procedures, see [SECURITY.md](SECURITY.md).

---

## License

This project is licensed under the **GNU General Public License v3.0 or later** (GPL-3.0-or-later). See [LICENSE](LICENSE) for full details.
