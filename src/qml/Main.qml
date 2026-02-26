// qmllint disable import
// qmllint disable missing-property
// qmllint disable unqualified
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import "pages"
import "components"
import io.github.AcikKaynakGelistirmeToplulugu.rocontrol

Controls.ApplicationWindow {
    id: root
    width: 1200; height: 800; visible: true
    title: "ro-Control - NVIDIA Driver Manager (Rust Edition)"

    property bool darkMode: false
    property string currentPage: "install"

    readonly property color cBg:      darkMode ? "#0f1419" : "#f5f7fa"
    readonly property color cCard:    darkMode ? "#1e293b" : "#fcfcfc"
    readonly property color cCardGlass: darkMode ? Qt.rgba(0.117,0.16,0.23,0.8) : Qt.rgba(1,1,1,0.9)
    readonly property color cBorder:  darkMode ? "#334155" : "#e5e7eb"
    readonly property color cFg:      darkMode ? "#e2e8f0" : "#1a1d23"
    readonly property color cMutedFg: darkMode ? "#94a3b8" : "#64748b"
    readonly property color cPrimary: darkMode ? "#60a5fa" : "#3b82f6"
    readonly property color cAccent:  darkMode ? "#a78bfa" : "#8b5cf6"
    readonly property color cMuted:   darkMode ? "#1e293b" : "#f1f5f9"
    readonly property color cSuccess: darkMode ? "#34d399" : "#10b981"

    background: Rectangle { color: root.cBg }

    // ─── Backend ───
    GpuController {
        id: gpuController
        Component.onCompleted: { check_network(); detect_gpu(); check_app_update(); }
    }
    PerfMonitor { id: perfMonitor }

    // ─── Animated Background ───
    Rectangle {
        parent: root.contentItem; anchors.fill: parent; z: -1
        color: root.cBg

        Rectangle {
            anchors.fill: parent; opacity: 0.3
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.1) }
                GradientStop { position: 1.0; color: Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.1) }
            }
        }
    }

    // ─── Header ───
    header: Rectangle {
        height: 64; color: root.cCardGlass

        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.cBorder }

        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 24; anchors.rightMargin: 24; spacing: 16

            RowLayout {
                spacing: 12
                Rectangle {
                    width: 40; height: 40; radius: 12
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#EF4444" }
                        GradientStop { position: 1.0; color: "#DC2626" }
                    }
                    Controls.Label { anchors.centerIn: parent; text: "🦀"; font.pixelSize: 20 }
                    SequentialAnimation on rotation {
                        running: true; loops: Animation.Infinite
                        NumberAnimation { from: 0; to: 5; duration: 1000 }
                        NumberAnimation { from: 5; to: -5; duration: 2000 }
                        NumberAnimation { from: -5; to: 0; duration: 1000 }
                    }
                }
                ColumnLayout {
                    spacing: 0
                    Controls.Label { text: "ro-Control"; font.pixelSize: 18; font.weight: Font.Bold; color: root.cFg }
                    Controls.Label { text: "NVIDIA Driver Manager • Rust Edition"; font.pixelSize: 12; color: root.cMutedFg }
                }
            }

            Item { Layout.fillWidth: true }

            // Rust badge
            Rectangle {
                implicitHeight: 32; implicitWidth: _rustBadge.implicitWidth + 16
                radius: 8; color: Qt.rgba(0.937, 0.267, 0.267, 0.1)
                border.width: 1; border.color: Qt.rgba(0.937, 0.267, 0.267, 0.3)
                RowLayout {
                    id: _rustBadge; anchors.centerIn: parent; spacing: 8
                    Controls.Label { text: "🦀"; font.pixelSize: 16 }
                    Controls.Label { text: "Powered by Rust"; font.pixelSize: 14; font.weight: Font.Bold; color: "#EF4444" }
                }
            }

            // Theme toggle
            Controls.ToolButton {
                text: root.darkMode ? "☀️" : "🌙"; font.pixelSize: 20
                implicitWidth: 40; implicitHeight: 40
                onClicked: root.darkMode = !root.darkMode
            }
        }
    }

    // ─── Status Bar ───
    StatusBar {
        id: statusBar
        visible: root.currentPage !== "progress"
        parent: root.contentItem
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        z: 10
        darkMode: root.darkMode
        items: [
            { label: qsTr("Driver"), value: gpuController.driver_in_use.length > 0 ? gpuController.driver_in_use : (gpuController.is_detecting ? qsTr("Detecting…") : "N/A") },
            { label: qsTr("Secure Boot"), value: gpuController.secure_boot ? "ON" : "OFF" },
            { label: qsTr("GPU"), value: gpuController.gpu_model.length > 0 ? gpuController.gpu_model : (gpuController.is_detecting ? qsTr("Detecting…") : "Unknown") }
        ]

        opacity: visible ? 1.0 : 0.0; height: visible ? implicitHeight : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on height { NumberAnimation { duration: 300 } }
    }

    // ─── Body ───
    RowLayout {
        parent: root.contentItem
        anchors.fill: parent; anchors.topMargin: statusBar.visible ? statusBar.height : 0
        spacing: 0

        // ─── Sidebar ───
        Rectangle {
            Layout.preferredWidth: 240; Layout.fillHeight: true
            color: Qt.rgba(root.cCard.r, root.cCard.g, root.cCard.b, 0.6)

            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: root.cBorder }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 12

                Repeater {
                    model: [
                        { id: "install", label: qsTr("Install"),  icon: "📥" },
                        { id: "expert",  label: qsTr("Expert"),   icon: "⚙️" },
                        { id: "monitor", label: qsTr("Monitor"),  icon: "📊" }
                    ]

                    delegate: Controls.Button {
                        Layout.fillWidth: true; implicitHeight: 48
                        required property var modelData
                        readonly property bool isActive: root.currentPage === modelData.id

                        background: Rectangle {
                            radius: 12
                            color: isActive ? root.cPrimary : (parent.hovered ? root.cMuted : "transparent")
                            Behavior on color { ColorAnimation { duration: 300 } }
                            scale: parent.pressed ? 0.98 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150 } }
                        }

                        contentItem: RowLayout {
                            spacing: 12
                            Rectangle {
                                Layout.preferredWidth: 36; Layout.preferredHeight: 36; radius: 8
                                color: isActive ? Qt.rgba(1,1,1,0.2) : root.cMuted
                                Controls.Label { anchors.centerIn: parent; text: modelData.icon; font.pixelSize: 20 }
                            }
                            Controls.Label {
                                text: modelData.label; font.pixelSize: 16
                                font.weight: isActive ? Font.Bold : Font.Normal
                                color: isActive ? "white" : root.cFg
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                visible: isActive; width: 8; height: 8; radius: 4
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "white" }
                                    GradientStop { position: 1.0; color: Qt.rgba(1,1,1,0.8) }
                                }
                            }
                        }

                        onClicked: root.currentPage = modelData.id
                    }
                }

                Item { Layout.fillHeight: true }

                // Rust version badge
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 60; radius: 12
                    color: Qt.rgba(0.937, 0.267, 0.267, 0.1)
                    border.width: 1; border.color: Qt.rgba(0.937, 0.267, 0.267, 0.3)

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: aboutDialog.open()
                    }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 12; spacing: 12
                        Rectangle {
                            Layout.preferredWidth: 36; Layout.preferredHeight: 36; radius: 8
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#EF4444" }
                                GradientStop { position: 1.0; color: "#DC2626" }
                            }
                            Controls.Label { anchors.centerIn: parent; text: "🦀"; font.pixelSize: 18 }
                            SequentialAnimation on scale {
                                running: true; loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 1.1; duration: 2000 }
                                NumberAnimation { from: 1.1; to: 1.0; duration: 2000 }
                            }
                        }
                        ColumnLayout {
                            spacing: 0
                            Controls.Label { text: "Rust Edition"; font.pixelSize: 12; color: root.cMutedFg }
                            Controls.Label {
                                text: "v" + (gpuController.app_version.length > 0 ? gpuController.app_version : "…")
                                font.pixelSize: 14; font.weight: Font.Bold; color: "#EF4444"
                            }
                        }
                    }
                }
            }
        }

        // ─── Content Area ───
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; color: "transparent"

            StackLayout {
                anchors.fill: parent
                currentIndex: {
                    if (root.currentPage === "install") return 0;
                    if (root.currentPage === "expert") return 1;
                    if (root.currentPage === "monitor") return 2;
                    if (root.currentPage === "progress") return 3;
                    return 0;
                }

                InstallPage {
                    controller: gpuController; darkMode: root.darkMode
                    onShowExpert: root.currentPage = "expert"
                    onShowProgress: root.currentPage = "progress"
                }
                ExpertPage {
                    controller: gpuController; darkMode: root.darkMode; kernelVersion: perfMonitor.kernel
                    onShowProgress: root.currentPage = "progress"
                    onGoBack: root.currentPage = "install"
                }
                PerfPage {
                    monitor: perfMonitor; controller: gpuController; darkMode: root.darkMode
                }
                ProgressPage {
                    controller: gpuController; darkMode: root.darkMode
                    onFinished: { gpuController.detect_gpu(); root.currentPage = "install"; }
                }
            }
        }
    }

    // ─── Update Dialog ───
    Controls.Dialog {
        id: updateDialog
        title: qsTr("Update Available")
        modal: true; anchors.centerIn: parent
        standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel
        visible: gpuController.app_update_available

        ColumnLayout {
            spacing: 12
            Controls.Label {
                text: "🦀 " + qsTr("ro-Control v%1 is available!").arg(gpuController.app_latest_version)
                font.pixelSize: 16; font.weight: Font.Bold
            }
            Controls.Label {
                text: gpuController.app_release_notes || qsTr("Bug fixes and improvements.")
                font.pixelSize: 14; wrapMode: Text.WordWrap
                Layout.maximumWidth: 400
            }
            RowLayout {
                spacing: 8
                Controls.Label { text: qsTr("Current:"); font.pixelSize: 12; color: root.cMutedFg }
                Controls.Label { text: "v" + gpuController.app_version; font.pixelSize: 12; font.weight: Font.Bold }
                Controls.Label { text: "→"; font.pixelSize: 12; color: root.cMutedFg }
                Controls.Label { text: "v" + gpuController.app_latest_version; font.pixelSize: 12; font.weight: Font.Bold; color: root.cPrimary }
            }
        }

        onAccepted: gpuController.install_app_update()
    }

    // ─── About Dialog ───
    Controls.Dialog {
        id: aboutDialog
        title: qsTr("About ro-Control")
        modal: true; anchors.centerIn: parent
        standardButtons: Controls.Dialog.Ok

        ColumnLayout {
            spacing: 12
            RowLayout {
                spacing: 12
                Rectangle {
                    width: 48; height: 48; radius: 12
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#EF4444" }
                        GradientStop { position: 1.0; color: "#DC2626" }
                    }
                    Controls.Label { anchors.centerIn: parent; text: "🦀"; font.pixelSize: 24 }
                }
                ColumnLayout {
                    spacing: 2
                    Controls.Label { text: "ro-Control"; font.pixelSize: 18; font.weight: Font.Bold }
                    Controls.Label { text: qsTr("NVIDIA Driver Manager · Rust Edition"); font.pixelSize: 12; color: root.cMutedFg }
                }
            }
            Controls.Label { text: qsTr("Version: %1").arg(gpuController.app_version); font.pixelSize: 14 }
            Controls.Label { text: "© 2024-2025 Açık Kaynak Geliştirme Topluluğu"; font.pixelSize: 12; color: root.cMutedFg }
            Controls.Label { text: qsTr("Licensed under GPL-3.0"); font.pixelSize: 12; color: root.cMutedFg }
        }
    }
}
