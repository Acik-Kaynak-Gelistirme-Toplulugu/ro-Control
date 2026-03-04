# Contributing to ro-Control

Thank you for your interest in contributing to ro-Control! This document explains how to get involved.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Branch Strategy](#branch-strategy)
- [Commit Message Format](#commit-message-format)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Translations](#translations)
- [Reporting Bugs](#reporting-bugs)

---

## Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md). We are committed to providing a welcoming and respectful environment for everyone.

---

## How to Contribute

You can contribute in several ways:

- **Bug reports** — Open an issue using the bug report template
- **Feature requests** — Open an issue using the feature request template
- **Code contributions** — Fix a bug or implement a feature
- **Translations** — Add or improve language support
- **Documentation** — Improve docs, README, or code comments

---

## Branch Strategy

We use a structured branching model:

```
main        ← Stable, release-ready code only. Never push directly.
dev         ← Active development. All features merge here first.
feature/*   ← New features (branched from dev)
fix/*       ← Bug fixes (branched from dev)
release/*   ← Release preparation (branched from dev)
```

**Always branch from `dev`, not `main`.**

```bash
git checkout dev
git pull origin dev
git checkout -b feature/your-feature-name
```

---

## Commit Message Format

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <short description>
```

| Type       | When to use                              |
|------------|------------------------------------------|
| `feat`     | New feature                              |
| `fix`      | Bug fix                                  |
| `docs`     | Documentation only                       |
| `refactor` | Code change that doesn't add/fix         |
| `test`     | Adding or updating tests                 |
| `chore`    | Build system, CI, dependencies           |
| `style`    | Formatting, whitespace (no logic change) |

**Examples:**

```
feat: add real-time GPU temperature monitoring
fix: crash when no NVIDIA GPU is detected
docs: update build instructions for Fedora 41
chore: update CMake minimum version to 3.22
```

---

## Development Setup

### Requirements

| Component | Minimum |
|-----------|---------|
| Fedora    | 40+     |
| GCC       | 13+     |
| CMake     | 3.22+   |
| Qt        | 6.6+    |

### Install Dependencies

```bash
sudo dnf install cmake extra-cmake-modules gcc-c++ \
  qt6-qtbase-devel \
  qt6-qtdeclarative-devel \
  qt6-qtwayland-devel \
  kf6-qqc2-desktop-style
```

### Build

```bash
git clone https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control.git
cd ro-Control
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Debug
make -j$(nproc)
./ro-control
```

### Before Submitting

```bash
# Format your code (clang-format)
find src/ -name "*.cpp" -o -name "*.h" | xargs clang-format -i

# Run tests
cd build && ctest --output-on-failure
```

---

## Pull Request Process

1. Fork the repository
2. Create a branch from `dev`: `git checkout -b feature/your-feature`
3. Make your changes with clear commits
4. Push to your fork: `git push origin feature/your-feature`
5. Open a Pull Request targeting the **`dev`** branch (not `main`)
6. Fill in the PR template completely
7. Wait for review — we aim to respond within 72 hours

**PRs to `main` will be rejected.** All contributions go through `dev` first.

---

## Translations

ro-Control supports multiple languages via `.po` files in the `po/` directory.

To add a new language:

1. Copy `po/en.po` to `po/<lang_code>.po` (e.g., `po/de.po`)
2. Translate the strings
3. Submit a PR with the new file

---

## Reporting Bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) and include:

- Fedora version (`cat /etc/fedora-release`)
- GPU model (`lspci | grep -i nvidia`)
- Current driver version (`nvidia-smi`)
- Steps to reproduce
- Expected vs actual behavior
- Relevant logs (`journalctl -u ro-control`)
