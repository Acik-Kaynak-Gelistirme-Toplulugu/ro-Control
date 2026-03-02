Name:           ro-control
Version:        1.1.0
Release:        1%{?dist}
Summary:        Smart GPU driver manager for Linux

%global debug_package %{nil}

License:        GPL-3.0-or-later
URL:            https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  rust >= 1.82
BuildRequires:  cargo
BuildRequires:  gcc-c++
BuildRequires:  cmake >= 3.28
BuildRequires:  extra-cmake-modules
BuildRequires:  pkgconfig(Qt6Core)
BuildRequires:  pkgconfig(Qt6Quick)
BuildRequires:  pkgconfig(Qt6Qml)
BuildRequires:  qt6-qtdeclarative-devel
BuildRequires:  kf6-qqc2-desktop-style
BuildRequires:  qt6-qtwayland-devel

ExclusiveArch:  x86_64

Requires:       qt6-qtdeclarative%{?_isa}
Requires:       qt6-qtwayland%{?_isa}
Requires:       qt6-qtsvg%{?_isa}
Requires:       kf6-qqc2-desktop-style
Requires:       polkit
Requires:       pciutils

Recommends:     timeshift
Recommends:     switcheroo-control

Suggests:       gamemode

%description
ro-Control simplifies GPU driver management on Linux desktops. It automatically
detects your graphics hardware, recommends the optimal drivers, and handles the
entire installation process via RPM Fusion — including kernel module compilation,
initramfs regeneration via dracut, and secure boot configuration.

Features include real-time GPU/CPU/RAM monitoring, Feral GameMode integration,
Flatpak/Steam permission repair, and NVIDIA Wayland support configuration.

%prep
%autosetup -n ro-control-%{version}

%build
cargo build --release

%install
# Binary
install -Dm755 target/release/%{name} %{buildroot}%{_bindir}/%{name}
install -Dm755 scripts/ro-control-root-task %{buildroot}%{_bindir}/ro-control-root-task

# Desktop entry
install -Dm644 data/io.github.AcikKaynakGelistirmeToplulugu.ro-control.desktop \
    %{buildroot}%{_datadir}/applications/io.github.AcikKaynakGelistirmeToplulugu.ro-control.desktop

# AppStream metainfo
install -Dm644 data/io.github.AcikKaynakGelistirmeToplulugu.ro-control.metainfo.xml \
    %{buildroot}%{_metainfodir}/io.github.AcikKaynakGelistirmeToplulugu.ro-control.metainfo.xml

# Icons
install -Dm644 data/icons/hicolor/scalable/apps/io.github.AcikKaynakGelistirmeToplulugu.ro-control.svg \
    %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/io.github.AcikKaynakGelistirmeToplulugu.ro-control.svg
install -Dm644 data/icons/hicolor/symbolic/apps/io.github.AcikKaynakGelistirmeToplulugu.ro-control-symbolic.svg \
    %{buildroot}%{_datadir}/icons/hicolor/symbolic/apps/io.github.AcikKaynakGelistirmeToplulugu.ro-control-symbolic.svg

# PolicyKit policy
install -Dm644 data/polkit/io.github.AcikKaynakGelistirmeToplulugu.ro-control.policy \
    %{buildroot}%{_datadir}/polkit-1/actions/io.github.AcikKaynakGelistirmeToplulugu.ro-control.policy

# GSettings schema
install -Dm644 data/io.github.AcikKaynakGelistirmeToplulugu.ro-control.gschema.xml \
    %{buildroot}%{_datadir}/glib-2.0/schemas/io.github.AcikKaynakGelistirmeToplulugu.ro-control.gschema.xml

%post
glib-compile-schemas %{_datadir}/glib-2.0/schemas &>/dev/null || :
update-desktop-database %{_datadir}/applications &>/dev/null || :

%postun
glib-compile-schemas %{_datadir}/glib-2.0/schemas &>/dev/null || :
update-desktop-database %{_datadir}/applications &>/dev/null || :

%files
%license LICENSE
%doc README.md CHANGELOG.md
%{_bindir}/%{name}
%{_bindir}/ro-control-root-task
%{_datadir}/applications/io.github.AcikKaynakGelistirmeToplulugu.ro-control.desktop
%{_metainfodir}/io.github.AcikKaynakGelistirmeToplulugu.ro-control.metainfo.xml
%{_datadir}/icons/hicolor/scalable/apps/io.github.AcikKaynakGelistirmeToplulugu.ro-control.svg
%{_datadir}/icons/hicolor/symbolic/apps/io.github.AcikKaynakGelistirmeToplulugu.ro-control-symbolic.svg
%{_datadir}/polkit-1/actions/io.github.AcikKaynakGelistirmeToplulugu.ro-control.policy
%{_datadir}/glib-2.0/schemas/io.github.AcikKaynakGelistirmeToplulugu.ro-control.gschema.xml

%changelog
* Wed Feb 26 2026 Sopwith <sopwith.osdev@gmail.com> - 1.1.0-1
- Premium Rust Edition UI redesign with modern aesthetic
- StatusBar, CustomProgressBar, GradientButton components
- Animated backgrounds, shimmer effects, gradient overlays
- About dialog and app update dialog with release notes
- Security: root-task script hardened against command injection
- Theme.qml singleton with centralized color palette
- 17-language internationalization (100%% coverage)
- Comprehensive test suite (100+ unit tests)
- All log messages standardized to English

* Sat Feb 14 2026 Sopwith <sopwith.osdev@gmail.com> - 1.0.0-1
- Initial native stable release
- Fedora-native architecture with DNF/RPM Fusion support
- Qt Quick Controls 2 UI with KDE Breeze native style
- NVIDIA driver management (Proprietary & Open Kernel)
- Live GPU/CPU/RAM performance monitoring
- NVIDIA Wayland nvidia-drm.modeset fix
- GameMode and Flatpak repair tools
- 17-language internationalization support
