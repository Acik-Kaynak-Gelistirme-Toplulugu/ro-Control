# ro-Control: GTK4 → Qt6/QML Migration Plan

## Overview

Migrate the UI layer from GTK4+libadwaita to **Qt6 + Qt Quick Controls 2 + QML**
using **cxx-qt** for native KDE Plasma integration. Uses Breeze style for native look
without Kirigami overhead. The Rust backend (`core/`, `utils/`) remains unchanged.

### Why Qt Quick Controls 2 instead of Kirigami?

- **Lighter:** ~8-12 MB RAM vs ~25 MB with Kirigami
- **Faster startup:** No KDE Frameworks initialization
- **Same native look:** `org.kde.desktop` style = Breeze theme automatic
- **Design freedom:** No Kirigami layout constraints for Figma designs
- **Single-purpose app:** Kirigami is for convergent apps (phone+desktop), overkill here

Reference: [KDE Kirigami + Rust Tutorial](https://develop.kde.org/docs/getting-started/kirigami/setup-rust/)

---

## Architecture

```
┌───────────────────────────────────────────────────────┐
│              QML / Qt Quick Controls 2                 │
│  src/qml/                                             │
│  ├── Main.qml              ApplicationWindow          │
│  ├── pages/                                           │
│  │   ├── InstallPage.qml   Express & Custom cards     │
│  │   ├── ExpertPage.qml    Advanced driver mgmt       │
│  │   ├── PerfPage.qml      Live GPU/CPU monitoring    │
│  │   └── ProgressPage.qml  Installation progress      │
│  └── components/                                      │
│      ├── ActionCard.qml    Reusable card component    │
│      ├── StatRow.qml       Metric bar component       │
│      └── StatusBar.qml     Top info bar               │
├───────────────────────────────────────────────────────┤
│              cxx-qt Bridge Layer                       │
│  src/bridge.rs        QObject definitions for QML     │
│  - GpuController      GPU detection & install actions │
│  - PerfMonitor        Live stats (timer-driven)       │
│  - AppConfig          Settings & theme management     │
├───────────────────────────────────────────────────────┤
│              Rust Backend (UNCHANGED)                  │
│  src/core/                                            │
│  ├── detector.rs      GPU/CPU/system detection        │
│  ├── installer.rs     dnf-based driver installation   │
│  ├── tweaks.rs        GPU stats, GameMode             │
│  └── updater.rs       GitHub API update check         │
│  src/utils/                                           │
│  ├── command.rs       Command runner (pkexec)         │
│  ├── i18n.rs          Translation system (16 langs)   │
│  └── logger.rs        Logging                         │
└───────────────────────────────────────────────────────┘
```

---

## New Project Structure

```
ro-control/
├── CMakeLists.txt                    # CMake build (KDE standard)
├── Cargo.toml                        # Updated dependencies
├── build.rs                          # cxx-qt QML module registration
├── src/
│   ├── main.rs                       # Qt app bootstrap (replaces app.rs)
│   ├── bridge.rs                     # cxx-qt QObject definitions
│   ├── config.rs                     # (unchanged)
│   ├── core/                         # (unchanged)
│   │   ├── mod.rs
│   │   ├── detector.rs
│   │   ├── installer.rs
│   │   ├── tweaks.rs
│   │   └── updater.rs
│   ├── utils/                        # (unchanged)
│   │   ├── mod.rs
│   │   ├── command.rs
│   │   ├── i18n.rs
│   │   └── logger.rs
│   └── qml/
│       ├── Main.qml                  # Application window
│       ├── pages/
│       │   ├── InstallPage.qml
│       │   ├── ExpertPage.qml
│       │   ├── PerfPage.qml
│       │   └── ProgressPage.qml
│       └── components/
│           ├── ActionCard.qml
│           ├── StatRow.qml
│           └── StatusBar.qml
├── data/                             # (unchanged - desktop, icons, polkit, etc.)
├── packaging/                        # (updated for Qt6 deps)
├── po/                               # (unchanged)
├── scripts/                          # (unchanged)
└── docs/                             # (unchanged)
```

---

## Phase 1: Build System Setup

### 1.1 Update Cargo.toml

Remove GTK4/libadwaita; add cxx-qt:

```toml
[dependencies]
cxx = "1.0.95"
cxx-qt = "0.7"
cxx-qt-lib = { version = "0.7", features = ["qt_full"] }
cxx-qt-lib-extras = "0.7"

# Keep existing
log = "0.4"
env_logger = "0.11"
ureq = { version = "3", features = ["json"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
regex = "1"
chrono = "0.4"
open = "5"
dirs = "6"

[build-dependencies]
cxx-qt-build = { version = "0.7", features = ["link_qt_object_files"] }
```

### 1.2 Create build.rs

```rust
use cxx_qt_build::{CxxQtBuilder, QmlModule};

fn main() {
    CxxQtBuilder::new()
        .qml_module(QmlModule {
            uri: "io.github.AcikKaynakGelistirmeToplulugu.rocontrol",
            qml_files: &[
                "src/qml/Main.qml",
                "src/qml/pages/InstallPage.qml",
                "src/qml/pages/ExpertPage.qml",
                "src/qml/pages/PerfPage.qml",
                "src/qml/pages/ProgressPage.qml",
            ],
            rust_files: &["src/bridge.rs"],
            ..Default::default()
        })
        .build();
}
```

### 1.3 Create CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.28)
project(ro-control)

find_package(ECM 6.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(ECMUninstallTarget)
include(ECMFindQmlModule)

# Qt Quick Controls 2 with Breeze style (no Kirigami needed)
find_package(KF6 REQUIRED COMPONENTS QQC2DesktopStyle)

set(APP_ID "io.github.AcikKaynakGelistirmeToplulugu.ro-control")

# Cargo build target
add_custom_target(ro-control ALL
    COMMAND cargo build --release --target-dir ${CMAKE_CURRENT_BINARY_DIR}
)

# Install binary
install(
    PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/release/ro-control
    DESTINATION ${KDE_INSTALL_BINDIR}
)

# Install helper script
install(
    PROGRAMS scripts/ro-control-root-task
    DESTINATION ${KDE_INSTALL_BINDIR}
)

# Install desktop file
install(FILES data/${APP_ID}.desktop
    DESTINATION ${KDE_INSTALL_APPDIR})

# Install metainfo
install(FILES data/${APP_ID}.metainfo.xml
    DESTINATION ${KDE_INSTALL_METAINFODIR})

# Install icons
install(FILES data/icons/hicolor/scalable/apps/${APP_ID}.svg
    DESTINATION ${KDE_INSTALL_ICONS}/hicolor/scalable/apps/)

# Install PolicyKit policy
install(FILES data/polkit/${APP_ID}.policy
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/polkit-1/actions/)

# Install GSettings schema
install(FILES data/${APP_ID}.gschema.xml
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/glib-2.0/schemas/)
```

---

## Phase 2: Qt Bootstrap (src/main.rs)

Replace GTK4 app initialization with Qt6:

```rust
#[cxx_qt::bridge]
mod ffi {
    extern "RustQt" {
        #[qobject]
        #[qml_element]
        type GpuController = super::GpuControllerRust;
    }
}

use cxx_qt_lib::{QGuiApplication, QQmlApplicationEngine, QQuickStyle, QString, QUrl};
use cxx_qt_lib_extras::QApplication;

mod bridge;
mod config;
mod core;
mod utils;

fn main() {
    utils::logger::init();
    utils::i18n::init();

    let mut app = QApplication::new();
    let mut engine = QQmlApplicationEngine::new();

    QGuiApplication::set_desktop_file_name(
        &QString::from(config::APP_ID)
    );

    if std::env::var("QT_QUICK_CONTROLS_STYLE").is_err() {
        QQuickStyle::set_style(&QString::from("org.kde.desktop"));
    }

    if let Some(engine) = engine.as_mut() {
        engine.load(&QUrl::from(
            "qrc:/qt/qml/io/github/AcikKaynakGelistirmeToplulugu/rocontrol/src/qml/Main.qml"
        ));
    }

    if let Some(app) = app.as_mut() {
        app.exec();
    }
}
```

---

## Phase 3: Bridge Layer (src/bridge.rs)

Expose Rust backend to QML via cxx-qt QObjects:

```rust
#[cxx_qt::bridge]
mod ffi {
    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(QString, gpu_vendor)]
        #[qproperty(QString, gpu_model)]
        #[qproperty(QString, driver_in_use)]
        #[qproperty(bool, secure_boot)]
        #[qproperty(bool, is_installing)]
        type GpuController = super::GpuControllerRust;

        #[qinvokable]
        fn detect_gpu(self: Pin<&mut GpuController>);

        #[qinvokable]
        fn install_express(self: Pin<&mut GpuController>);

        #[qinvokable]
        fn install_custom(self: Pin<&mut GpuController>, version: &QString);

        #[qinvokable]
        fn remove_drivers(self: Pin<&mut GpuController>);
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(u32, gpu_temp)]
        #[qproperty(u32, gpu_load)]
        #[qproperty(u32, gpu_mem_used)]
        #[qproperty(u32, gpu_mem_total)]
        #[qproperty(u32, cpu_load)]
        #[qproperty(u32, cpu_temp)]
        #[qproperty(u32, ram_used)]
        #[qproperty(u32, ram_total)]
        type PerfMonitor = super::PerfMonitorRust;

        #[qinvokable]
        fn refresh(self: Pin<&mut PerfMonitor>);
    }
}
```

---

## Phase 4: QML UI (Qt Quick Controls 2)

### Main.qml

```qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import io.github.AcikKaynakGelistirmeToplulugu.rocontrol

Controls.ApplicationWindow {
    id: root
    width: 960
    height: 680
    minimumWidth: 800
    minimumHeight: 600
    title: "ro-Control"
    visible: true

    GpuController { id: gpuController }
    PerfMonitor { id: perfMonitor }

    // Sidebar + Content layout
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar navigation
        Rectangle {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            color: palette.base

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8

                Controls.Button {
                    text: qsTr("Install")
                    icon.name: "download"
                    Layout.fillWidth: true
                    onClicked: contentStack.currentIndex = 0
                }
                Controls.Button {
                    text: qsTr("Expert")
                    icon.name: "configure"
                    Layout.fillWidth: true
                    onClicked: contentStack.currentIndex = 1
                }
                Controls.Button {
                    text: qsTr("Monitor")
                    icon.name: "utilities-system-monitor"
                    Layout.fillWidth: true
                    onClicked: contentStack.currentIndex = 2
                }
                Item { Layout.fillHeight: true }
                Controls.Label {
                    text: "v1.0.0"
                    opacity: 0.5
                }
            }
        }

        // Content area
        Controls.StackLayout {
            id: contentStack
            Layout.fillWidth: true
            Layout.fillHeight: true

            InstallPage { controller: gpuController }
            ExpertPage { controller: gpuController }
            PerfPage { monitor: perfMonitor }
            ProgressPage { controller: gpuController }
        }
    }
}
```

---

## Phase 5: Cleanup

### Files to REMOVE (GTK4-specific):

- `src/app.rs` — GTK4 Application builder
- `src/ui/window.rs` — GTK4 MainWindow
- `src/ui/install_view.rs` — GTK4 install view
- `src/ui/expert_view.rs` — GTK4 expert view
- `src/ui/perf_view.rs` — GTK4 performance view
- `src/ui/progress_view.rs` — GTK4 progress view
- `src/ui/style.rs` — GTK4 CSS loader
- `src/ui/mod.rs` — GTK4 UI module

### Files to KEEP (unchanged):

- `src/config.rs`
- `src/core/*` (detector, installer, tweaks, updater)
- `src/utils/*` (command, i18n, logger)
- `data/*` (desktop, icons, polkit, metainfo, gschema)
- `po/*`, `scripts/*`, `docs/*`, `packaging/*`

---

## Build Dependencies (Fedora)

```bash
sudo dnf install \
    cargo cmake extra-cmake-modules \
    kf6-qqc2-desktop-style \
    qt6-qtdeclarative-devel \
    qt6-qtbase-devel \
    qt6-qtwayland-devel \
    gcc-c++
```

> **Note:** `kf6-kirigami2-devel` is NOT required — we use Qt Quick Controls 2 directly.

---

## Migration Order

| Step | Task                                  | Risk   | Files     |
| ---- | ------------------------------------- | ------ | --------- |
| 1    | Update Cargo.toml + create build.rs   | Low    | 2 files   |
| 2    | Create CMakeLists.txt                 | Low    | 1 file    |
| 3    | Rewrite main.rs (Qt bootstrap)        | Medium | 1 file    |
| 4    | Create bridge.rs (GpuController)      | Medium | 1 file    |
| 5    | Create Main.qml + InstallPage.qml     | Low    | 2 files   |
| 6    | Create ExpertPage.qml                 | Low    | 1 file    |
| 7    | Add PerfMonitor bridge + PerfPage.qml | Medium | 2 files   |
| 8    | Add ProgressPage.qml                  | Low    | 1 file    |
| 9    | Remove GTK4 ui/ files                 | Low    | 8 files   |
| 10   | Update Makefile, packaging, CI        | Low    | 4 files   |
| 11   | **UI Polish (Figma design)**          | -      | QML files |

**Total: ~20 files changed, backend untouched**

---

## Figma → QML Workflow

When you're ready to design in Figma:

1. **Create frames** at 960×680 for each page
2. **Use KDE Breeze colors** as your palette
3. **Export/reference** the layout, spacing, colors
4. **Translate to QML** — each Figma component becomes a `.qml` file
5. QML is declarative like CSS — much easier to match Figma than GTK4

The UI can be polished at any time by editing `.qml` files without
touching any Rust code. This is the key advantage of the Qt/QML approach.
