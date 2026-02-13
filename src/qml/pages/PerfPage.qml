import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import io.github.AcikKaynakGelistirmeToplulugu.rocontrol

// Performance Monitor — Live GPU/CPU/RAM stats + system info
// Shows real-time metrics when driver is installed

Item {
    id: perfPage

    required property var monitor

    // Load system info once when page becomes visible
    onVisibleChanged: {
        if (visible) {
            monitor.load_system_info()
            refreshTimer.start()
        } else {
            refreshTimer.stop()
        }
    }

    // Refresh live stats every 2s ONLY when visible
    Timer {
        id: refreshTimer
        interval: 2000
        repeat: true
        running: false
        onTriggered: monitor.refresh()
    }

    Controls.ScrollView {
        anchors.fill: parent

        ColumnLayout {
            width: Math.min(parent.width, 560)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Item { Layout.preferredHeight: 24 }

            // ─── System Information ───
            Controls.GroupBox {
                Layout.fillWidth: true
                title: qsTr("System Information")

                GridLayout {
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 6
                    anchors.fill: parent

                    Controls.Label { text: qsTr("OS:"); opacity: 0.6 }
                    Controls.Label { text: monitor.distro; Layout.fillWidth: true }

                    Controls.Label { text: qsTr("Kernel:"); opacity: 0.6 }
                    Controls.Label { text: monitor.kernel }

                    Controls.Label { text: qsTr("CPU:"); opacity: 0.6 }
                    Controls.Label { text: monitor.cpu_name }

                    Controls.Label { text: qsTr("RAM:"); opacity: 0.6 }
                    Controls.Label { text: monitor.ram_info }

                    Controls.Label { text: qsTr("GPU:"); opacity: 0.6 }
                    Controls.Label { text: monitor.gpu_full_name }

                    Controls.Label { text: qsTr("Display:"); opacity: 0.6 }
                    Controls.Label { text: monitor.display_server }
                }
            }

            // ─── GPU Live Status ───
            Controls.GroupBox {
                Layout.fillWidth: true
                title: qsTr("GPU Status")

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    StatRow {
                        label: qsTr("Temperature")
                        value: monitor.gpu_temp + " °C"
                        fraction: monitor.gpu_temp / 100.0
                    }

                    StatRow {
                        label: qsTr("Load")
                        value: monitor.gpu_load + " %"
                        fraction: monitor.gpu_load / 100.0
                    }

                    StatRow {
                        label: qsTr("VRAM")
                        value: monitor.gpu_mem_used + " / " + monitor.gpu_mem_total + " MB"
                        fraction: monitor.gpu_mem_total > 0
                            ? monitor.gpu_mem_used / monitor.gpu_mem_total
                            : 0
                    }
                }
            }

            // ─── System Live Status ───
            Controls.GroupBox {
                Layout.fillWidth: true
                title: qsTr("System Usage")

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    StatRow {
                        label: qsTr("CPU Load")
                        value: monitor.cpu_load + " %"
                        fraction: monitor.cpu_load / 100.0
                    }

                    StatRow {
                        label: qsTr("CPU Temp")
                        value: monitor.cpu_temp + " °C"
                        fraction: monitor.cpu_temp / 100.0
                    }

                    StatRow {
                        label: qsTr("RAM")
                        value: monitor.ram_used + " / " + monitor.ram_total + " MB"
                        fraction: monitor.ram_total > 0
                            ? monitor.ram_used / monitor.ram_total
                            : 0
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
