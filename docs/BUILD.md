# Build & Development Guide

This document details the build prerequisites, compilation steps, test execution, and packaging procedures for developers and OS maintainers.

---

## 1. Build Prerequisites

### Fedora / Ro-ASD (Recommended Toolchain)
```bash
sudo dnf install -y \
  cmake extra-cmake-modules gcc-c++ ninja-build \
  qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qttools-devel qt6-qtwayland-devel \
  kf6-qqc2-desktop-style polkit-devel systemd-rpm-macros desktop-file-utils \
  pciutils mokutil kmod lm_sensors rpm-build
```

### Debian / Ubuntu
```bash
sudo apt update && sudo apt install -y \
  cmake ninja-build g++ build-essential \
  qt6-base-dev qt6-declarative-dev qt6-tools-dev qt6-wayland \
  libpolkit-gobject-1-dev pciutils mokutil kmod lm-sensors
```

### Arch Linux
```bash
sudo pacman -S --needed \
  cmake ninja gcc qt6-base qt6-declarative qt6-tools qt6-wayland \
  polkit pciutils kmod lm_sensors
```

---

## 2. Compiling from Source

```bash
# 1. Clone the repository
git clone https://github.com/Project-Ro-ASD/ro-Control.git
cd ro-Control

# 2. Configure build tree with CMake and Ninja
cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_TESTS=ON

# 3. Compile all targets
cmake --build build --parallel $(nproc)
```

---

## 3. Running Tests

The test suite is built on **QtTest** and managed by **CTest** (12 suites covering hardware detection, fan curves, telemetry parsing, Polkit helper, D-Bus service, CLI, and AppStream metadata):

```bash
ctest --test-dir build --output-on-failure --verbose
```

---

## 4. Building RPM Packages Locally

To generate distribution-ready RPM packages:

```bash
# Create source tarball
mkdir -p ~/rpmbuild/SOURCES ~/rpmbuild/SPECS
tar -czf ~/rpmbuild/SOURCES/ro-control-1.3.0.tar.gz \
  --exclude-vcs --transform 's,^\.,ro-control-1.3.0,' .

# Build Binary and Source RPM
rpmbuild -ba packaging/rpm/ro-control.spec
```

The resulting packages will be placed in:
- Binary RPM: `~/rpmbuild/RPMS/x86_64/ro-control-1.3.0-1.x86_64.rpm`
- Source RPM: `~/rpmbuild/SRPMS/ro-control-1.3.0-1.src.rpm`

---

## 5. Local Code Health & Validation

Run the automated health checker before opening PRs or tagging releases:

```bash
bcheck ro-control
```
