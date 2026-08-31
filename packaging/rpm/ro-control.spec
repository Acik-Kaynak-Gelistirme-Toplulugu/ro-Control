%global upstream_version %{!?upstream_version:1.2.1}%{?upstream_version}
%global debug_package %{nil}

Name:           ro-control
Version:        %{upstream_version}
Release:        1%{?dist}
Summary:        Smart NVIDIA driver manager and system monitor

License:        GPL-3.0-or-later
Vendor:         Project Ro ASD
Packager:       Project Ro ASD <noreply@github.com>
URL:            https://github.com/Project-Ro-ASD/ro-Control
Source0:        %{name}-%{version}.tar.gz
ExclusiveArch:  x86_64 aarch64

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  extra-cmake-modules
BuildRequires:  ninja-build
BuildRequires:  qt6-qtbase-devel
BuildRequires:  qt6-qtdeclarative-devel
BuildRequires:  qt6-qttools-devel
BuildRequires:  qt6-qtwayland-devel
BuildRequires:  kf6-qqc2-desktop-style
BuildRequires:  polkit-devel

Requires:       qt6-qtbase
Requires:       qt6-qtdeclarative
Requires:       qt6-qtwayland

Requires:       kf6-qqc2-desktop-style
Requires:       polkit
Requires:       /usr/bin/dnf
Requires:       /usr/bin/pkexec
Requires:       /usr/bin/rpm
Requires:       pciutils
Requires:       /usr/bin/free
Recommends:     mokutil
Recommends:     kmod
Recommends:     /usr/bin/sensors
Recommends:     /usr/sbin/akmods
Recommends:     /usr/bin/dracut
Recommends:     /usr/sbin/grubby

%description
ro-Control is a native Qt6 and KDE Plasma desktop application designed for
Linux systems. It provides smart NVIDIA driver detection, installation, and
updates through DNF, multi-fan cooling control with custom temperature curves,
real-time hardware diagnostics (GPU, CPU, VRAM, and RAM telemetry), power threshold
management, and secure Polkit privilege integration.

%prep
%autosetup -c -T -n %{name}-%{version}
tar -xzf %{SOURCE0} --strip-components=1

%build
%cmake \
    -DBUILD_TESTS=ON \
    -DREQUIRE_TRANSLATIONS=ON
%cmake_build

%install
%cmake_install

%check
export HOME="$PWD/.test-home"
export XDG_CONFIG_HOME="$HOME/.config"
mkdir -p "$XDG_CONFIG_HOME"
export QT_QPA_PLATFORM=offscreen
export QT_QUICK_CONTROLS_STYLE=Basic
%ctest --output-on-failure

%files
%license LICENSE
%{_bindir}/ro-control
%{_datadir}/applications/io.github.projectroasd.rocontrol.desktop
%{_datadir}/man/man1/ro-control.1*
%{_datadir}/metainfo/io.github.projectroasd.rocontrol.metainfo.xml
%{_datadir}/icons/hicolor/256x256/apps/ro-control.png
%{_datadir}/icons/hicolor/256x256/apps/io.github.projectroasd.rocontrol.png
%{_datadir}/icons/hicolor/scalable/apps/ro-control.svg
%{_datadir}/icons/hicolor/scalable/apps/io.github.projectroasd.rocontrol.svg
%{_datadir}/bash-completion/completions/ro-control
%{_datadir}/zsh/site-functions/_ro-control
%{_datadir}/fish/vendor_completions.d/ro-control.fish
%{_libexecdir}/ro-control-helper
%{_datadir}/polkit-1/actions/io.github.ProjectRoASD.rocontrol.policy

%changelog
* Mon Aug 31 2026 Project Ro-ASD <contact@roasd.org> - 1.2.1-1
- Build native Fedora 44 packages for x86_64 and aarch64.
- Publish canonical RPM, SRPM, source archive, and checksum artifacts.
- Isolate hardware monitor tests from host GPU sensor state.

* Mon Aug 31 2026 Project Ro-ASD <contact@roasd.org> - 1.2.0-2
- Rebuild for Fedora 44 with canonical binary RPM names and a source RPM artifact.

* Thu Aug 27 2026 ro-Control Maintainers <noreply@github.com> - 1.2.0-1
- Add advanced fan management and telemetry subsystem
- Implement dedicated per-fan control, curves, and mode presets
- Hardware-aware GPU and CPU fan topology discovery
- Robust CI and headless test stabilization

* Sun May 10 2026 ro-Control Maintainers <noreply@github.com> - 1.1.0-2
- Merge runtime assets back into the main architecture RPM
- Make each release RPM installable on its own without a companion noarch package
- Keep AppStream, desktop entry, icons, helper, and policy metadata in the main package

* Sun May 10 2026 ro-Control Maintainers <noreply@github.com> - 1.1.0-1
- Target Fedora 43 for CI, RPM validation, and release builds
- Validate RPM compatibility for x86_64 and aarch64 with store metadata checks
- Align AppStream metadata with real application screenshots and improved package identity

* Mon Mar 30 2026 ro-Control Maintainers <noreply@github.com> - 0.2.1-1
- Limit release outputs to x86_64, aarch64, noarch, and src RPM artifacts
- Split shared desktop assets into a noarch companion package

* Mon Mar 30 2026 ro-Control Maintainers <noreply@github.com> - 0.2.0-1
- Fix installed helper path resolution for privileged operations on system installs
- Activate saved KDE-friendly interface preferences and theme switching in the UI
- Harden Ro-ASD CI and release validation for metadata and RPM packaging
- Limit published RPM outputs to x86_64, aarch64, src, and noarch artifacts only

* Sun Mar 22 2026 ro-Control Maintainers <noreply@github.com> - 0.1.0-1
- Prepare first GitHub Release RPMs for x86_64 and aarch64
- Add explicit Ro-ASD runtime command dependencies and recommendations
- Align RPM release automation with tagged versioned source archives
