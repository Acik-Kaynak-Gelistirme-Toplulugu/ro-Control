# Architecture

## Overview

ro-Control is a native Linux desktop application focused on GPU driver management
(primarily NVIDIA) on Fedora-based systems through DNF and RPM Fusion.

## Module Structure

```
src/
├── main.rs              ← Entry point: logging, i18n, app launch
├── config.rs            ← Application constants (APP_ID, VERSION, etc.)
├── bridge.rs            ← cxx-qt bridge: GpuController + PerfMonitor QObjects
│
├── core/                ← Business logic (no UI dependencies)
│   ├── detector.rs      ← Hardware detection (GPU, CPU, RAM, distro, secure boot)
│   ├── installer.rs     ← Driver installation/removal engine (DNF/RPM Fusion)
│   ├── tweaks.rs        ← System tweaks (GPU stats, GameMode, Wayland fix)
│   └── updater.rs       ← Self-update via GitHub Releases API
│
├── qml/                 ← User interface files (Rust Edition design)
│   ├── Main.qml         ← Main window: header, sidebar, StatusBar, navigation
│   ├── Theme.qml        ← Singleton: color palette, spacing, radius tokens
│   ├── qmldir           ← QML module directory (Theme singleton registration)
│   ├── pages/
│   │   ├── InstallPage.qml    ← Express/Custom install selection
│   │   ├── ExpertPage.qml     ← Version picker, kernel module, deep clean
│   │   ├── PerfPage.qml       ← System info grid + live GPU/CPU monitoring
│   │   └── ProgressPage.qml   ← Installation progress, logs, steps
│   └── components/
│       ├── ActionCard.qml         ← Clickable card (Button-based, gradient overlay)
│       ├── CustomProgressBar.qml  ← Animated progress bar (thresholds, shimmer)
│       ├── GradientButton.qml     ← Gradient/solid button with shimmer hover
│       ├── StatusBar.qml          ← Header status pills (driver, GPU, SecBoot)
│       └── StepItem.qml           ← Installation step indicator (emoji status)
│
└── utils/               ← Cross-cutting concerns
    ├── command.rs       ← Shell command execution wrapper
    ├── i18n.rs          ← TR/EN dictionary-based translation
    ├── logger.rs        ← Logging setup (simplelog with colored terminal output)
    └── version.rs       ← Shared version parsing, comparison, and sorting
```

## Key Design Decisions

### 1. Privilege Escalation

- Uses **PolicyKit** (`pkexec`) for root operations
- A helper script (`scripts/ro-control-root-task`) wraps privileged commands
- Shell metacharacters (pipes, semicolons, backticks, subshells) are **rejected** before allowlist check
- Only whitelisted command prefixes are allowed to execute as root
- The GUI process itself **never** runs as root

### 2. Driver Management

- **Fedora-first**: Primary target is DNF + RPM Fusion (`akmod-nvidia`)
- **Fallback support**: apt (Ubuntu/Debian), pacman (Arch) maintained for portability
- **Initramfs**: Uses `dracut` on Fedora, `update-initramfs` on Debian, `mkinitcpio` on Arch

### 3. UI Architecture

- **Stack-based navigation** with dedicated page views
- **Action-driven flow** for cross-view state transitions
- **Thread safety**: Background operations run in worker threads, UI updates via event loop
- **Theme-aware interface** with desktop style integration

### 4. Translation

- Simple dictionary-based system using `OnceLock<HashMap>`
- Detects system language from `LANG` / `LC_ALL` environment variables
- Fallback: English
- Future: optional gettext support for community translations

### 5. Packaging

- **RPM**: Primary distribution format via spec file
- **Flatpak**: Available but limited (GPU driver management requires host access)
- **Makefile**: Standard `make install` / `make uninstall` for manual builds

## Data Flow

```
User Action → UI View → GIO Action → Core Module → command::run() → pkexec → System
                ↑                                         |
                └──────── event-loop queue (UI update) ───┘
```

## Security Model

1. Application runs as unprivileged user
2. Privileged commands go through PolicyKit authentication
3. `ro-control-root-task` script restricts what can be executed
4. No network requests require elevated privileges
5. Update downloads go to `/tmp` and install via `dnf`
