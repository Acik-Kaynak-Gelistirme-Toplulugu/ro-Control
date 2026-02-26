pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import "../components"
import io.github.AcikKaynakGelistirmeToplulugu.rocontrol

Item {
    id: page

    required property var monitor
    required property bool darkMode

    readonly property color cSurface:  darkMode ? "#242b35" : "#ffffff"
    readonly property color cBorder:   darkMode ? "#313840" : "#d0d7de"
    readonly property color cText:     darkMode ? "#e6edf3" : "#1f2328"
    readonly property color cTextSub:  darkMode ? "#8b949e" : "#656d76"
    readonly property color cTextMuted:darkMode ? "#6e7681" : "#8c959f"

    onVisibleChanged: {
        if (visible) {
            page.monitor.load_system_info();
            refreshTimer.start();
        } else {
            refreshTimer.stop();
        }
    }

    Timer {
        id: refreshTimer
        interval: 2000; repeat: true; running: false
        onTriggered: page.monitor.refresh()
    }

    Controls.ScrollView {
        anchors.fill: parent

        ColumnLayout {
            width: Math.min(parent.width - 48, 640)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0

            Item { Layout.preferredHeight: 32 }

            Controls.Label {
                text: qsTr("System Monitor")
                font.pixelSize: 20; font.weight: Font.DemiBold; color: page.cText
            }

            Item { Layout.preferredHeight: 4 }

            Controls.Label {
                text: qsTr("Real-time hardware monitoring")
                font.pixelSize: 14; color: page.cTextSub
            }

            Item { Layout.preferredHeight: 20 }

            // ── System Information ──
            Controls.Label {
                text: qsTr("System Information")
                font.pixelSize: 14; font.weight: Font.DemiBold; color: page.cTextSub
            }

            Item { Layout.preferredHeight: 8 }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: sysGrid.implicitHeight + 24
                radius: 10; color: page.cSurface
                border.width: 1; border.color: page.cBorder

                GridLayout {
                    id: sysGrid
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter; anchors.margins: 16
                    columns: 2; columnSpacing: 16; rowSpacing: 8

                    Controls.Label { text: qsTr("OS"); color: page.cTextSub; font.pixelSize: 13 }
                    Controls.Label {
                        text: page.monitor.distro; color: page.cText
                        font.pixelSize: 13; font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight; Layout.fillWidth: true
                    }

                    Controls.Label { text: qsTr("Kernel"); color: page.cTextSub; font.pixelSize: 13 }
                    Controls.Label {
                        text: page.monitor.kernel; color: page.cText
                        font.pixelSize: 13; font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight; Layout.fillWidth: true
                    }

                    Controls.Label { text: qsTr("CPU"); color: page.cTextSub; font.pixelSize: 13 }
                    Controls.Label {
                        text: page.monitor.cpu_name; color: page.cText
                        font.pixelSize: 13; font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight; Layout.fillWidth: true
                    }

                    Controls.Label { text: qsTr("RAM"); color: page.cTextSub; font.pixelSize: 13 }
                    Controls.Label {
                        text: page.monitor.ram_info; color: page.cText
                        font.pixelSize: 13; font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight; Layout.fillWidth: true
                    }

                    Controls.Label { text: qsTr("GPU"); color: page.cTextSub; font.pixelSize: 13 }
                    Controls.Label {
                        text: page.monitor.gpu_full_name; color: page.cText
                        font.pixelSize: 13; font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight; Layout.fillWidth: true
                    }

                    Controls.Label { text: qsTr("Display"); color: page.cTextSub; font.pixelSize: 13 }
                    Controls.Label {
                        text: page.monitor.display_server; color: page.cText
                        font.pixelSize: 13; font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight; Layout.fillWidth: true
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }

            // ── GPU Status ──
            Controls.Label {
                text: qsTr("GPU Status")
                font.pixelSize: 14; font.weight: Font.DemiBold; color: page.cTextSub
            }

            Item { Layout.preferredHeight: 8 }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: gpuStats.implicitHeight + 24
                radius: 10; color: page.cSurface
                border.width: 1; border.color: page.cBorder

                ColumnLayout {
                    id: gpuStats
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter; anchors.margins: 16
                    spacing: 14

                    StatRow {
                        label: qsTr("Temperature"); value: page.monitor.gpu_temp + " \u00B0C"
                        fraction: page.monitor.gpu_temp / 100.0; darkMode: page.darkMode
                    }
                    StatRow {
                        label: qsTr("Load"); value: page.monitor.gpu_load + " %"
                        fraction: page.monitor.gpu_load / 100.0; darkMode: page.darkMode
                    }
                    StatRow {
                        label: qsTr("VRAM")
                        value: page.monitor.gpu_mem_used + " / " + page.monitor.gpu_mem_total + " MB"
                        fraction: page.monitor.gpu_mem_total > 0 ? (1.0 * page.monitor.gpu_mem_used) / page.monitor.gpu_mem_total : 0
                        darkMode: page.darkMode
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }

            // ── System Usage ──
            Controls.Label {
                text: qsTr("System Usage")
                font.pixelSize: 14; font.weight: Font.DemiBold; color: page.cTextSub
            }

            Item { Layout.preferredHeight: 8 }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: cpuStats.implicitHeight + 24
                radius: 10; color: page.cSurface
                border.width: 1; border.color: page.cBorder

                ColumnLayout {
                    id: cpuStats
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter; anchors.margins: 16
                    spacing: 14

                    StatRow {
                        label: qsTr("CPU Load"); value: page.monitor.cpu_load + " %"
                        fraction: page.monitor.cpu_load / 100.0; darkMode: page.darkMode
                    }
                    StatRow {
                        label: qsTr("CPU Temp"); value: page.monitor.cpu_temp + " \u00B0C"
                        fraction: page.monitor.cpu_temp / 100.0; darkMode: page.darkMode
                    }
                    StatRow {
                        label: qsTr("RAM")
                        value: page.monitor.ram_used + " / " + page.monitor.ram_total + " MB"
                        fraction: page.monitor.ram_total > 0 ? (1.0 * page.monitor.ram_used) / page.monitor.ram_total : 0
                        darkMode: page.darkMode
                    }
                }
            }

            Item { Layout.preferredHeight: 32 }
        }
    }
}
