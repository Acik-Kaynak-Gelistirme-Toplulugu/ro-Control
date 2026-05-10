# ro-Control

Native Qt6/QML desktop application for NVIDIA driver management and Linux system monitoring.

Primary packaging target:

- Fedora 43 KDE Plasma
- x86_64 and aarch64

## Overview

ro-Control focuses on three things:

- installing, updating, and cleaning NVIDIA drivers on Fedora-oriented Linux systems
- monitoring CPU, GPU, and RAM telemetry in a native desktop UI
- exposing a small CLI for diagnostics and scripted driver operations

The application ships runtime translations for:

- English
- German
- Spanish
- Turkish

## Features

- Driver install, update, deep-clean, and rescan workflows
- Secure Boot detection and related driver warnings
- CPU, GPU, and RAM telemetry dashboard
- Qt-based localization and persistent UI preferences
- CLI commands for status, diagnostics, and driver actions

## Build

Quick local build:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=ON
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

On Fedora development hosts, you can also bootstrap dependencies with:

```bash
./scripts/fedora-bootstrap.sh
```

## Packaging

The repository includes:

- desktop entry metadata
- AppStream metadata
- PolicyKit policy
- shell completions
- RPM packaging files

## Contributing

Use short-lived branches from `main` and open pull requests back to `main`.

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Security

Report vulnerabilities privately when possible.

See [SECURITY.md](SECURITY.md).

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
