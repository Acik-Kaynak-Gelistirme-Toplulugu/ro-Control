<p align="center">
  <img src="data/icons/hicolor/scalable/apps/io.github.AcikKaynakGelistirmeToplulugu.ro-control.svg" width="128" height="128" alt="ro-Control">
</p>

<h1 align="center">ro-Control</h1>

<p align="center">
  <strong>Smart GPU Driver Manager for Linux</strong>
</p>

<p align="center">
  <a href="https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/releases"><img src="https://img.shields.io/github/v/release/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control?style=flat-square&color=blue" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-green?style=flat-square" alt="License"></a>
  <a href="https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/actions"><img src="https://img.shields.io/github/actions/workflow/status/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/ci.yml?style=flat-square&label=CI" alt="CI"></a>
  <img src="https://img.shields.io/badge/platform-Fedora%2040+-51A2DA?style=flat-square" alt="Fedora">
  <img src="https://img.shields.io/badge/rust-1.82+-orange?style=flat-square&logo=rust" alt="Rust">
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#building-from-source">Building</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

<p align="center">
  <a href="README.md"><img src="https://img.shields.io/badge/README-English-blue?style=flat-square" alt="README in English"></a>
  <a href="README.tr.md"><img src="https://img.shields.io/badge/README-T%C3%BCrk%C3%A7e-red?style=flat-square" alt="README in Turkish"></a>
</p>

---

ro-Control is a native Linux desktop application built with **Rust** and **Qt6/QML** (via [CXX-Qt](https://github.com/KDAB/cxx-qt)) that simplifies NVIDIA GPU driver management on Fedora. It provides a modern interface for installing, configuring, and monitoring graphics drivers with full PolicyKit integration for secure privilege escalation.

## Features

### 🚀 Smart Driver Management

- **Express Install** — One-click NVIDIA driver setup via RPM Fusion (`akmod-nvidia`)
- **Expert Mode** — Choose between Proprietary and Open Kernel modules
- **Deep Clean** — Remove old driver artifacts to prevent conflicts
- **Secure Boot** — Automatic detection and warnings for unsigned modules

### 📊 Live Performance Monitor

- Real-time GPU temperature, load, and VRAM usage
- CPU load and temperature tracking
- RAM usage monitoring
- Color-coded progress bars (green → yellow → red)

### 🎮 Gaming Optimization

- **Feral GameMode** — One-click installation and management
- **Flatpak/Steam** — Permission repair for Flatpak gaming issues

### 🖥 Display Server

- **Wayland Fix** — Automatic `nvidia-drm.modeset=1` GRUB configuration
- **Hybrid Graphics** — Switch between NVIDIA, Intel, and On-Demand modes

### 🔄 Auto-Updates

- GitHub Releases integration for self-updating
- RPM package download and installation

### 🌍 Internationalization

- English and Turkish bilingual interface
- Extensible translation system

## Installation

### Fedora (RPM)

Download the latest `.rpm` from [Releases](https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/releases):

```bash
sudo dnf install ./ro-control-1.1.0-1.fc40.x86_64.rpm
```

### From Source

> **Requires Rust ≥ 1.82.** Install via [rustup](https://rustup.rs/) if your distro ships an older version.

```bash
# Install build dependencies (Fedora 40+)
sudo dnf install cmake extra-cmake-modules gcc-c++ \
  kf6-qqc2-desktop-style \
  qt6-qtdeclarative-devel \
  qt6-qtbase-devel \
  qt6-qtwayland-devel

# Clone and build
git clone https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control.git
cd ro-Control
cargo build --release

# Install system-wide
sudo make install
```

See [docs/BUILDING.md](docs/BUILDING.md) for detailed build instructions for Fedora, Arch Linux, and openSUSE.

## Usage

Launch from your application menu or terminal:

```bash
ro-control
```

> **Note:** Driver operations require administrator authentication via PolicyKit.

## Project Structure

```text
ro-Control/
├── src/                    # Application source code
│   ├── main.rs             #   Entry point: logging, i18n, app launch
│   ├── bridge.rs           #   CXX-Qt bridge (Rust ↔ QML)
│   ├── config.rs           #   App constants (APP_ID, VERSION, etc.)
│   ├── core/               #   Business logic
│   │   ├── detector.rs     #     GPU/CPU/OS hardware detection
│   │   ├── installer.rs    #     DNF-based driver install/remove
│   │   ├── tweaks.rs       #     GPU stats, GameMode, Wayland fix
│   │   └── updater.rs      #     GitHub Releases update check
│   ├── qml/                #   Qt Quick interface (Rust Edition)
│   │   ├── Main.qml        #     App window, sidebar, StatusBar
│   │   ├── Theme.qml       #     Color palette singleton
│   │   ├── pages/          #     Install, Expert, Perf, Progress
│   │   └── components/     #     ActionCard, CustomProgressBar,
│   │                       #     GradientButton, StatusBar, StepItem
│   └── utils/              #   Shared utilities
│       ├── command.rs      #     Shell command runner
│       ├── i18n.rs         #     TR/EN translation system
│       └── logger.rs       #     simplelog setup
├── data/                   # FreeDesktop data files
│   ├── icons/              #   Hicolor theme icons (scalable + symbolic SVG)
│   ├── polkit/             #   PolicyKit authorization policy
│   ├── *.desktop           #   Desktop entry
│   ├── *.metainfo.xml      #   AppStream metadata
│   └── *.gschema.xml       #   GSettings schema
├── packaging/              # Distribution packaging
│   ├── rpm/                #   Fedora RPM spec
│   └── flatpak/            #   Flatpak manifest
├── scripts/                # Helper scripts (pkexec wrapper)
├── po/                     # Translation files
├── docs/                   # Documentation
│   ├── ARCHITECTURE.md     #   Technical architecture
│   ├── BUILDING.md         #   Build instructions
│   ├── DESIGN_BRIEF.md     #   UI design specification
│   └── VERSIONS.md         #   Version notes
├── .github/                # CI/CD workflows
├── Cargo.toml              # Project manifest
├── Makefile                # Build/install targets
├── CHANGELOG.md            # Release history
└── CONTRIBUTING.md         # Contribution guide
```

## Contributing

We welcome contributions from everyone! Please read our [Contributing Guide](CONTRIBUTING.md) before submitting a Pull Request.

Quick start:

```bash
git clone https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control.git
cd ro-Control
cargo build
cargo run

# Before submitting
cargo fmt --all
cargo clippy --all-targets -- -D warnings -A dead_code -A clippy::incompatible_msrv
cargo test --all-targets
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for a technical overview of the codebase.

## Translators

ro-Control supports multiple languages. See the [Contributing Guide](CONTRIBUTING.md#-translations) for instructions on adding new translations.

Currently supported: **English**, **Türkçe**

## License

This project is licensed under the [GPL-3.0](LICENSE) license.
