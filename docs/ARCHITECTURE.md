# Architecture

## Overview

ro-Control is a native Linux desktop application written in Rust, using GTK4 and
libadwaita for its user interface. It manages GPU drivers (primarily NVIDIA) on
Fedora-based systems through DNF and RPM Fusion.

## Module Structure

```
src/
├── main.rs              ← Entry point: logging, i18n, app launch
├── app.rs               ← GtkApplication / AdwApplication bootstrap
├── config.rs            ← Application constants (APP_ID, VERSION, etc.)
│
├── core/                ← Business logic (no UI dependencies)
│   ├── detector.rs      ← Hardware detection (GPU, CPU, RAM, distro, secure boot)
│   ├── installer.rs     ← Driver installation/removal engine (DNF/RPM Fusion)
│   ├── tweaks.rs        ← System tweaks (GPU stats, GameMode, Wayland fix)
│   └── updater.rs       ← Self-update via GitHub Releases API
│
├── ui/                  ← User interface (GTK4 + libadwaita)
│   ├── window.rs        ← Main window, navigation, state management
│   ├── install_view.rs  ← Express/Custom install cards
│   ├── expert_view.rs   ← Advanced driver management + tools
│   ├── perf_view.rs     ← Live performance monitoring dashboard
│   ├── progress_view.rs ← Operation progress with log output
│   └── style.rs         ← CSS theme (Liquid Glass)
│
└── utils/               ← Cross-cutting concerns
    ├── command.rs       ← Shell command execution wrapper
    ├── i18n.rs          ← TR/EN dictionary-based translation
    └── logger.rs        ← Logging setup (env_logger + XDG dirs)
```

## Key Design Decisions

### 1. Privilege Escalation

- Uses **PolicyKit** (`pkexec`) for root operations
- A helper script (`scripts/ro-control-root-task`) wraps privileged commands
- The GUI process itself **never** runs as root

### 2. Driver Management

- **Fedora-first**: Primary target is DNF + RPM Fusion (`akmod-nvidia`)
- **Fallback support**: apt (Ubuntu/Debian), pacman (Arch) maintained for portability
- **Initramfs**: Uses `dracut` on Fedora, `update-initramfs` on Debian, `mkinitcpio` on Arch

### 3. UI Architecture

- **Stack-based navigation**: `GtkStack` with named pages
- **GIO Actions**: Cross-view navigation via `SimpleAction`
- **Thread safety**: Background operations run in `std::thread`, UI updates via `glib::idle_add`
- **Theme**: LibAdwaita handles light/dark mode; custom CSS provides "Liquid Glass" overlay

### 4. Translation

- Simple dictionary-based system using `OnceLock<HashMap>`
- Detects system language from `LANG` / `LC_ALL` environment variables
- Fallback: English
- Future: migrate to gettext for community translations

### 5. Packaging

- **RPM**: Primary distribution format via spec file
- **Flatpak**: Available but limited (GPU driver management requires host access)
- **Makefile**: Standard `make install` / `make uninstall` for manual builds

## Data Flow

```
User Action → UI View → GIO Action → Core Module → command::run() → pkexec → System
                ↑                                         |
                └─────── glib::idle_add (UI update) ──────┘
```

## Security Model

1. Application runs as unprivileged user
2. Privileged commands go through PolicyKit authentication
3. `ro-control-root-task` script restricts what can be executed
4. No network requests require elevated privileges
5. Update downloads go to `/tmp` and install via `dnf`
