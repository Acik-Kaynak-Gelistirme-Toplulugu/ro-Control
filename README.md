<p align="center">
  <img src="data/icons/hicolor/scalable/apps/io.github.AcikKaynakGelistirmeToplulugu.ro-control.svg" width="128" height="128" alt="ro-Control">
</p>

<h1 align="center">ro-Control</h1>

<p align="center">
  <strong>Smart GPU Driver Manager for Linux</strong>
</p>

<p align="center">
  <a href="https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-control/releases"><img src="https://img.shields.io/github/v/release/Acik-Kaynak-Gelistirme-Toplulugu/ro-control?style=flat-square&color=blue" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-green?style=flat-square" alt="License"></a>
  <a href="https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-control/actions"><img src="https://img.shields.io/github/actions/workflow/status/Acik-Kaynak-Gelistirme-Toplulugu/ro-control/ci.yml?style=flat-square&label=CI" alt="CI"></a>
  <img src="https://img.shields.io/badge/language-Rust-orange?style=flat-square" alt="Rust">
  <img src="https://img.shields.io/badge/toolkit-Qt6%20%2B%20QML-41CD52?style=flat-square" alt="Qt6 + QML">
  <img src="https://img.shields.io/badge/platform-Fedora%20Linux-51A2DA?style=flat-square" alt="Fedora">
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#building-from-source">Building</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

---

ro-Control is a native Linux desktop application that simplifies GPU driver management. Built in **Rust** with **Qt6 + QML**, it provides a modern interface for installing, configuring, and monitoring NVIDIA graphics drivers on Fedora and other Linux distributions.

<!-- TODO: Add screenshots
<p align="center">
  <img src="docs/screenshots/install.png" width="45%" alt="Install View">
  <img src="docs/screenshots/performance.png" width="45%" alt="Performance View">
</p>
-->

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

Download the latest release from [Releases](https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-control/releases):

```bash
sudo dnf install ./ro-control-1.0.0-1.fc*.x86_64.rpm
```

### From Source

```bash
# Install dependencies
sudo dnf install cargo cmake extra-cmake-modules gcc-c++ \
  kf6-qqc2-desktop-style \
  qt6-qtdeclarative-devel \
  qt6-qtbase-devel \
  qt6-qtwayland-devel

# Build and install
git clone https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-control.git
cd ro-control
make build
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
ro-control/
├── src/                    # Rust source code
│   ├── core/               #   Business logic (detection, installation, monitoring)
│   ├── qml/                #   Qt6 + QML interface
│   └── utils/              #   Shared utilities (i18n, logging, commands)
├── data/                   # FreeDesktop data files
│   ├── icons/              #   Hicolor theme icons (scalable + symbolic SVG)
│   ├── polkit/             #   PolicyKit authorization policy
│   ├── *.desktop           #   Desktop entry
│   ├── *.metainfo.xml      #   AppStream metadata
│   └── *.gschema.xml       #   GSettings schema
├── packaging/              # Distribution packaging
│   ├── rpm/                #   Fedora RPM spec
│   └── flatpak/            #   Flatpak manifest
├── scripts/                # Helper scripts
├── po/                     # Translation files
├── docs/                   # Documentation
│   ├── ARCHITECTURE.md     #   Technical architecture
│   └── BUILDING.md         #   Build instructions
├── .github/                # CI/CD and issue templates
├── Cargo.toml              # Rust dependencies
├── Makefile                # Build/install targets
├── CHANGELOG.md            # Release history
├── CONTRIBUTING.md         # Contribution guide
└── CODE_OF_CONDUCT.md      # Community guidelines
```

## Contributing

We welcome contributions from everyone! Please read our [Contributing Guide](CONTRIBUTING.md) before submitting a Pull Request.

Quick start:

```bash
git clone https://github.com/YOUR_USERNAME/ro-control.git
cd ro-control
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

---

<div align="center">
  <sub>Built with 🦀 Rust and ❤️ by <a href="https://github.com/Acik-Kaynak-Gelistirme-Toplulugu">Açık Kaynak Geliştirme Topluluğu</a></sub>
</div>
