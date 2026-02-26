// qmllint disable import
// qmllint disable missing-property
// qmllint disable unqualified
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import "pages"
import io.github.AcikKaynakGelistirmeToplulugu.rocontrol

Controls.ApplicationWindow {
    id: root
    width: 1360
    height: 780
    minimumWidth: 1060
    minimumHeight: 640
    title: "ro-Control"
    visible: true

    property bool darkMode: false

    // ─── Color Palette ───
    readonly property color cBg:       darkMode ? "#1b2028" : "#f5f7f9"
    readonly property color cHeader:   darkMode ? "#1e252e" : "#ffffff"
    readonly property color cSidebar:  darkMode ? "#181e25" : "#f0f2f5"
    readonly property color cSurface:  darkMode ? "#242b35" : "#ffffff"
    readonly property color cBorder:   darkMode ? "#313840" : "#d0d7de"
    readonly property color cBorderSub:darkMode ? "#282f38" : "#e1e4e8"
    readonly property color cText:     darkMode ? "#e6edf3" : "#1f2328"
    readonly property color cTextSub:  darkMode ? "#8b949e" : "#656d76"
    readonly property color cTextMuted:darkMode ? "#6e7681" : "#8c959f"
    readonly property color cPrimary:  "#3daee9"
    readonly property color cNavActive:darkMode ? "#242b35" : "#ffffff"

    background: Rectangle { color: root.cBg }

    // ─── Backend ───
    GpuController {
        id: gpuController
        Component.onCompleted: {
            check_network();
            detect_gpu();
            check_app_update();
        }
    }

    PerfMonitor { id: perfMonitor }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ═══════════════ Header Bar (48px) ═══════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: root.cHeader

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 1
                color: root.cBorder
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18; anchors.rightMargin: 14
                spacing: 0

                // Logo
                Controls.Label {
                    text: "ro-Control"
                    font.pixelSize: 15; font.weight: Font.Bold
                    color: root.cPrimary
                }

                Item { Layout.preferredWidth: 24 }

                // Status info
                RowLayout {
                    spacing: 6

                    Rectangle {
                        implicitWidth: driverPill.implicitWidth + 16
                        implicitHeight: 22; radius: 11
                        color: root.darkMode ? "#282f38" : "#eef1f5"

                        Controls.Label {
                            id: driverPill; anchors.centerIn: parent
                            text: qsTr("Driver: %1").arg(
                                gpuController.driver_in_use.length > 0
                                    ? gpuController.driver_in_use
                                    : (gpuController.is_detecting ? qsTr("Detecting\u2026") : qsTr("N/A")))
                            font.pixelSize: 11; font.weight: Font.Medium
                            color: root.cTextSub
                        }
                    }

                    Rectangle {
                        implicitWidth: gpuPill.implicitWidth + 16
                        implicitHeight: 22; radius: 11
                        color: root.darkMode ? "#282f38" : "#eef1f5"

                        Controls.Label {
                            id: gpuPill; anchors.centerIn: parent
                            text: qsTr("GPU: %1").arg(
                                gpuController.gpu_model.length > 0
                                    ? gpuController.gpu_model
                                    : (gpuController.is_detecting ? qsTr("Detecting\u2026") : qsTr("Unknown")))
                            font.pixelSize: 11; font.weight: Font.Medium
                            color: root.cTextSub
                        }
                    }

                    Rectangle {
                        implicitWidth: sbPill.implicitWidth + 16
                        implicitHeight: 22; radius: 11
                        color: gpuController.secure_boot
                            ? (root.darkMode ? "#3d1418" : "#ffebe9")
                            : (root.darkMode ? "#282f38" : "#eef1f5")

                        Controls.Label {
                            id: sbPill; anchors.centerIn: parent
                            text: qsTr("SecBoot: %1").arg(gpuController.secure_boot ? "ON" : "OFF")
                            font.pixelSize: 11; font.weight: Font.Medium
                            color: gpuController.secure_boot
                                ? (root.darkMode ? "#f85149" : "#cf222e")
                                : root.cTextSub
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Header actions
                Controls.ToolButton {
                    text: root.darkMode ? "\u2600" : "\u263E"
                    font.pixelSize: 17
                    implicitWidth: 36; implicitHeight: 36
                    onClicked: root.darkMode = !root.darkMode
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Toggle theme")
                }

                Controls.ToolButton {
                    text: "\u24D8"
                    font.pixelSize: 17
                    implicitWidth: 36; implicitHeight: 36
                    onClicked: aboutDialog.open()
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("About")
                }
            }
        }

        // ═══════════════ Body ═══════════════
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ─── Sidebar (200px) ───
            Rectangle {
                id: sidebar
                Layout.preferredWidth: 200
                Layout.fillHeight: true
                color: root.cSidebar

                Rectangle {
                    anchors.right: parent.right
                    width: 1; height: parent.height
                    color: root.cBorder; opacity: 0.5
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 12; anchors.bottomMargin: 12
                    anchors.leftMargin: 10; anchors.rightMargin: 10
                    spacing: 4

                    Repeater {
                        model: [
                            { label: qsTr("Install"),  icon: "\u2193", idx: 0 },
                            { label: qsTr("Expert"),   icon: "\u2699", idx: 1 },
                            { label: qsTr("Monitor"),  icon: "\u223F", idx: 2 }
                        ]

                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 40
                            radius: 8
                            color: contentStack.currentIndex === modelData.idx
                                ? root.cNavActive : "transparent"

                            Behavior on color { ColorAnimation { duration: 120 } }

                            // Active accent bar
                            Rectangle {
                                visible: contentStack.currentIndex === modelData.idx
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3; height: 20; radius: 2
                                color: root.cPrimary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: contentStack.currentIndex = parent.modelData.idx

                                Rectangle {
                                    anchors.fill: parent; radius: 8
                                    color: parent.containsMouse && contentStack.currentIndex !== parent.parent.modelData.idx
                                        ? (root.darkMode ? "#242b3540" : "#00000008")
                                        : "transparent"
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14; anchors.rightMargin: 10
                                spacing: 10

                                Controls.Label {
                                    text: modelData.icon
                                    font.pixelSize: 16
                                    color: contentStack.currentIndex === modelData.idx
                                        ? root.cPrimary : root.cTextSub
                                }

                                Controls.Label {
                                    text: modelData.label
                                    font.pixelSize: 14
                                    font.weight: contentStack.currentIndex === modelData.idx
                                        ? Font.DemiBold : Font.Normal
                                    color: contentStack.currentIndex === modelData.idx
                                        ? root.cText : root.cTextSub
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Update notification
                    Rectangle {
                        visible: gpuController.app_update_available
                        Layout.fillWidth: true
                        implicitHeight: 36; radius: 8
                        color: root.darkMode ? "#162d1f" : "#dafbe1"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: updateDialog.open()
                        }

                        Controls.Label {
                            anchors.centerIn: parent
                            text: qsTr("Update v%1").arg(gpuController.app_latest_version)
                            font.pixelSize: 12; font.weight: Font.DemiBold
                            color: root.darkMode ? "#3fb950" : "#1a7f37"
                        }
                    }

                    // Version
                    Controls.Label {
                        text: "v" + (gpuController.app_version.length > 0 ? gpuController.app_version : "\u2026")
                        font.pixelSize: 11; color: root.cTextMuted
                        Layout.leftMargin: 6
                    }
                }
            }

            // ─── Content Area ───
            StackLayout {
                id: contentStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: 0

                InstallPage {
                    controller: gpuController
                    darkMode: root.darkMode
                    onShowExpert: contentStack.currentIndex = 1
                    onShowProgress: contentStack.currentIndex = 3
                }

                ExpertPage {
                    controller: gpuController
                    darkMode: root.darkMode
                    kernelVersion: perfMonitor.kernel
                    onShowProgress: contentStack.currentIndex = 3
                    onGoBack: contentStack.currentIndex = 0
                }

                PerfPage {
                    monitor: perfMonitor
                    darkMode: root.darkMode
                }

                ProgressPage {
                    controller: gpuController
                    darkMode: root.darkMode
                    onFinished: {
                        gpuController.detect_gpu();
                        contentStack.currentIndex = 0;
                    }
                }
            }
        }
    }

    // ─── About Dialog ───
    Controls.Dialog {
        id: aboutDialog
        title: qsTr("About ro-Control")
        modal: true; anchors.centerIn: parent
        standardButtons: Controls.Dialog.Ok

        ColumnLayout {
            spacing: 8; width: 360

            Controls.Label {
                text: "ro-Control"
                font.pixelSize: 18; font.weight: Font.Bold
                color: root.cPrimary
            }

            Controls.Label {
                text: "v" + (gpuController.app_version.length > 0 ? gpuController.app_version : "\u2026")
                font.pixelSize: 14; font.weight: Font.DemiBold; color: root.cText
            }

            Controls.Label {
                text: qsTr("Professional NVIDIA driver manager for Linux systems.")
                wrapMode: Text.WordWrap; color: root.cTextSub; Layout.fillWidth: true
            }

            Controls.Label {
                text: "\u00A9 A\u00E7\u0131k Kaynak Geli\u015Ftirme Toplulu\u011Fu"
                color: root.cTextMuted; font.pixelSize: 12
            }
        }
    }

    // ─── Update Dialog ───
    Controls.Dialog {
        id: updateDialog
        title: qsTr("Application Update")
        modal: true; anchors.centerIn: parent
        standardButtons: Controls.Dialog.Cancel

        ColumnLayout {
            spacing: 12; width: 400

            Controls.Label {
                text: qsTr("A new version of ro-Control is available!")
                font.pixelSize: 15; font.weight: Font.DemiBold; color: root.cText
            }

            RowLayout {
                spacing: 8
                Controls.Label {
                    text: "v" + gpuController.app_version
                    font.pixelSize: 13; color: root.cTextSub
                }
                Controls.Label {
                    text: "\u2192"; font.pixelSize: 13; color: root.cTextMuted
                }
                Controls.Label {
                    text: "v" + gpuController.app_latest_version
                    font.pixelSize: 13; font.weight: Font.DemiBold
                    color: root.darkMode ? "#3fb950" : "#1a7f37"
                }
            }

            Controls.Label {
                visible: gpuController.app_release_notes.length > 0
                text: gpuController.app_release_notes
                wrapMode: Text.WordWrap; color: root.cTextSub
                font.pixelSize: 12; Layout.fillWidth: true
                Layout.maximumHeight: 180; elide: Text.ElideRight
            }

            Controls.Button {
                text: gpuController.app_download_url.length > 0
                    ? qsTr("Download & Install")
                    : qsTr("Visit GitHub")
                Layout.fillWidth: true; font.pixelSize: 14

                contentItem: Controls.Label {
                    text: parent.text; font: parent.font; color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    implicitHeight: 38; radius: 10
                    color: parent.down ? "#2a8ec4" : "#3daee9"
                }

                onClicked: {
                    if (gpuController.app_download_url.length > 0) {
                        gpuController.install_app_update();
                        updateDialog.close();
                    } else {
                        Qt.openUrlExternally("https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/releases/latest");
                    }
                }
            }
        }
    }
}
