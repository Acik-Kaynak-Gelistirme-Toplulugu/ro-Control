# Building ro-Control

## Prerequisites

ro-Control requires the development packages listed below for successful builds.

### Fedora (Primary target)

> **Requires Rust ≥ 1.82.** Install via [rustup](https://rustup.rs/) if your distro ships an older version.

```bash
sudo dnf install cmake extra-cmake-modules gcc-c++ \
    kf6-qqc2-desktop-style \
    qt6-qtdeclarative-devel \
    qt6-qtbase-devel \
    qt6-qtwayland-devel
```

### Arch Linux / Manjaro

```bash
sudo pacman -S cmake extra-cmake-modules qt6-declarative \
    qt6-base qqc2-desktop-style gcc rustup
rustup default stable
```

### openSUSE

```bash
sudo zypper install cmake kf6-extra-cmake-modules \
    qt6-declarative-devel kf6-qqc2-desktop-style gcc-c++
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Building

### Development Build

```bash
cargo build
cargo run
```

### Release Build

```bash
cargo build --release
# Binary: target/release/ro-control (~5 MB)
```

### Using CMake (for install)

```bash
cmake -B build --install-prefix ~/.local
cmake --build build/
cmake --install build/
```

### Using Make (alternative)

```bash
# Build + Install system-wide
make build
sudo make install

# Uninstall
sudo make uninstall

# Run checks
make check
make clippy
make fmt
```

## Packaging

### RPM (Fedora)

```bash
rpmbuild -ba packaging/rpm/ro-control.spec
```

### Flatpak

```bash
flatpak-builder build-dir \
    packaging/flatpak/io.github.AcikKaynakGelistirmeToplulugu.ro-control.yml \
    --force-clean
```

## Development

### Code Quality

```bash
# Format code
cargo fmt

# Lint
cargo clippy --all-targets -- -D warnings -A dead_code -A clippy::incompatible_msrv

# Test
cargo test

# All checks
make lint
```

### Project Structure

```text
src/
├── main.rs          # Application entry point
├── bridge.rs        # CXX-Qt bridge (Rust ↔ QML)
├── config.rs        # App constants (APP_ID, VERSION, etc.)
├── core/            # Backend logic
│   ├── detector.rs  # GPU/CPU/OS hardware detection
│   ├── installer.rs # DNF-based driver install/remove
│   ├── tweaks.rs    # GPU stats, GameMode, Wayland fix
│   └── updater.rs   # GitHub Releases update check
├── utils/           # Shared utilities
│   ├── command.rs   # Shell command runner
│   ├── i18n.rs      # Multi-language translation (17 languages)
│   └── logger.rs    # simplelog setup
└── qml/             # Qt Quick interface files
    ├── Main.qml     # Application window + sidebar nav
    ├── Theme.qml    # Dark/light theme definitions
    ├── pages/       # Install, Expert, Perf, Progress
    └── components/  # Reusable UI components
```

### Environment Variables

| Variable                  | Description                                  | Default           |
| ------------------------- | -------------------------------------------- | ----------------- |
| `RUST_LOG`                | Log level (`debug`, `info`, `warn`, `error`) | `info`            |
| `LANG`                    | UI language (`tr_TR.UTF-8` for Turkish)      | System default    |
| `QT_QUICK_CONTROLS_STYLE` | Override QML style                           | `Fusion`          |

### Debugging

```bash
# Run with debug logging
RUST_LOG=debug cargo run

# Run with QML debugging
QML_IMPORT_TRACE=1 cargo run

# Force Breeze dark mode
QT_QUICK_CONTROLS_STYLE=org.kde.desktop cargo run
```
