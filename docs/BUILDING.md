# Building ro-Control

## Prerequisites

ro-Control is built with Rust, Qt6, and cxx-qt (Rust–Qt bridge).
The UI uses Qt Quick Controls 2 with KDE Breeze style for native KDE Plasma look.

### Fedora (Primary target)

```bash
sudo dnf install cargo cmake extra-cmake-modules gcc-c++ \
    kf6-qqc2-desktop-style \
    qt6-qtdeclarative-devel \
    qt6-qtbase-devel \
    qt6-qtwayland-devel
```

### Arch Linux / Manjaro

```bash
sudo pacman -S cargo cmake extra-cmake-modules qt6-declarative \
    qt6-base qqc2-desktop-style gcc
```

### openSUSE

```bash
sudo zypper install cargo cmake kf6-extra-cmake-modules \
    qt6-declarative-devel kf6-qqc2-desktop-style
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

```
src/
├── main.rs          # Qt6 app entry point (QApplication + QML engine)
├── bridge.rs        # cxx-qt bridge — QObjects exposed to QML
├── config.rs        # App constants (unchanged)
├── core/            # Backend logic (unchanged)
│   ├── detector.rs  # GPU/CPU/OS detection
│   ├── installer.rs # DNF-based driver install
│   ├── tweaks.rs    # GPU stats, GameMode, Wayland fix
│   └── updater.rs   # GitHub release update check
├── utils/           # Utilities (unchanged)
│   ├── command.rs   # Shell command runner
│   ├── i18n.rs      # 16-language translation system
│   └── logger.rs    # env_logger setup
└── qml/             # Qt Quick UI
    ├── Main.qml     # Application window + sidebar nav
    ├── pages/       # Page views
    └── components/  # Reusable QML components
```

### Environment Variables

| Variable                  | Description                                  | Default           |
| ------------------------- | -------------------------------------------- | ----------------- |
| `RUST_LOG`                | Log level (`debug`, `info`, `warn`, `error`) | `info`            |
| `LANG`                    | UI language (`tr_TR.UTF-8` for Turkish)      | System default    |
| `QT_QUICK_CONTROLS_STYLE` | Override QML style                           | `org.kde.desktop` |

### Debugging

```bash
# Run with debug logging
RUST_LOG=debug cargo run

# Run with QML debugging
QML_IMPORT_TRACE=1 cargo run

# Force Breeze dark mode
QT_QUICK_CONTROLS_STYLE=org.kde.desktop cargo run
```
