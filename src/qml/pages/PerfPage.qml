pragma ComponentBehavior: Bound
// qmllint disable unqualified
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import "../components"
import io.github.AcikKaynakGelistirmeToplulugu.rocontrol

Item {
    id: page

    required property var monitor
    required property var controller

    onVisibleChanged: {
        if (visible) {
            page.monitor.load_system_info();
            _timer.start();
        } else {
            _timer.stop();
        }
    }
    Timer {
        id: _timer
        interval: 2000
        repeat: true
        onTriggered: page.monitor.refresh()
    }

    Controls.ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: 20

            Item {
                Layout.preferredHeight: 12
            }

            // ── Title ──
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 960
                spacing: 12
                Controls.Label {
                    text: qsTr("System Information")
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    color: Theme.foreground
                }
                Controls.Label {
                    text: "Rust Edition"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Theme.primary
                }
            }

            // ── Info Grid ──
            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 960
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 16
                rowSpacing: 16

                Repeater {
                    model: [
                        {
                            icon: "💻",
                            label: qsTr("OS"),
                            value: page.monitor.distro,
                            color: Theme.primary
                        },
                        {
                            icon: "🔧",
                            label: qsTr("Kernel"),
                            value: page.monitor.kernel,
                            color: Theme.accent
                        },
                        {
                            icon: "⚙️",
                            label: qsTr("CPU"),
                            value: page.monitor.cpu_name,
                            color: Theme.warning
                        },
                        {
                            icon: "🧠",
                            label: qsTr("RAM"),
                            value: page.monitor.ram_info,
                            color: Theme.success
                        },
                        {
                            icon: "🎮",
                            label: qsTr("GPU"),
                            value: page.monitor.gpu_full_name,
                            color: Theme.primary
                        },
                        {
                            icon: "📊",
                            label: qsTr("Driver"),
                            value: page.controller.driver_in_use,
                            color: Theme.warning
                        }
                    ]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 90
                        radius: 16
                        color: Theme.card
                        border.width: 1
                        border.color: Theme.border
                        required property var modelData

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 16

                            Rectangle {
                                implicitWidth: 48
                                implicitHeight: 48
                                radius: 12
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0
                                        color: modelData.color
                                    }
                                    GradientStop {
                                        position: 1
                                        color: Qt.darker(modelData.color, 1.2)
                                    }
                                }
                                Controls.Label {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.pixelSize: 24
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Controls.Label {
                                    text: modelData.label
                                    font.pixelSize: 14
                                    color: Theme.mutedForeground
                                }
                                Controls.Label {
                                    text: modelData.value || "N/A"
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                    color: Theme.foreground
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }

            // ── GPU Status ──
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 960
                Layout.fillWidth: true
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    Controls.Label {
                        text: "🎮 " + qsTr("GPU Status")
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }
                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        implicitWidth: _statusRow.implicitWidth + 16
                        implicitHeight: 28
                        radius: 8
                        color: Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.1)
                        border.width: 1
                        border.color: Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.3)
                        RowLayout {
                            id: _statusRow
                            anchors.centerIn: parent
                            spacing: 8
                            Rectangle {
                                implicitWidth: 8
                                implicitHeight: 8
                                radius: 4
                                color: Theme.success
                                SequentialAnimation on opacity {
                                    running: true
                                    loops: Animation.Infinite
                                    NumberAnimation {
                                        from: 1
                                        to: 0.5
                                        duration: 1000
                                    }
                                    NumberAnimation {
                                        from: 0.5
                                        to: 1
                                        duration: 1000
                                    }
                                }
                            }
                            Controls.Label {
                                text: qsTr("Active")
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: Theme.success
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: _gpuStats.implicitHeight + 48
                    radius: 16
                    color: Theme.card
                    border.width: 1
                    border.color: Theme.border

                    ColumnLayout {
                        id: _gpuStats
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 20

                        CustomProgressBar {
                            Layout.fillWidth: true
                            label: "🌡️ " + qsTr("Temperature") + " (" + page.monitor.gpu_temp + "°C)"
                            value: page.monitor.gpu_temp
                            thresholdYellow: 70
                            thresholdRed: 90
                        }
                        CustomProgressBar {
                            Layout.fillWidth: true
                            label: "⚡ " + qsTr("GPU Load")
                            value: page.monitor.gpu_load
                        }
                        CustomProgressBar {
                            Layout.fillWidth: true
                            label: "🧠 " + qsTr("VRAM (%1 / %2 MB)").arg(page.monitor.gpu_mem_used).arg(page.monitor.gpu_mem_total)
                            value: page.monitor.gpu_mem_total > 0 ? Math.round((1.0 * page.monitor.gpu_mem_used) / page.monitor.gpu_mem_total * 100) : 0
                        }
                    }
                }
            }

            // ── System Resources ──
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 960
                Layout.fillWidth: true
                spacing: 16

                Controls.Label {
                    text: "💻 " + qsTr("System Resources")
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    color: Theme.foreground
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: _sysStats.implicitHeight + 48
                    radius: 16
                    color: Theme.card
                    border.width: 1
                    border.color: Theme.border

                    ColumnLayout {
                        id: _sysStats
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 20

                        CustomProgressBar {
                            Layout.fillWidth: true
                            label: "⚙️ " + qsTr("CPU Usage")
                            value: page.monitor.cpu_load
                        }
                        CustomProgressBar {
                            Layout.fillWidth: true
                            label: "🧠 " + qsTr("RAM (%1 / %2 MB)").arg(page.monitor.ram_used).arg(page.monitor.ram_total)
                            value: page.monitor.ram_total > 0 ? Math.round((1.0 * page.monitor.ram_used) / page.monitor.ram_total * 100) : 0
                        }
                    }
                }
            }

            // ── Update Indicator ──
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                Controls.Label {
                    text: "●"
                    font.pixelSize: 14
                    color: Theme.success
                }
                Controls.Label {
                    text: qsTr("Rust monitoring engine · Updating every 2 seconds")
                    font.pixelSize: 14
                    color: Theme.mutedForeground
                    SequentialAnimation on opacity {
                        running: true
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: 0.5
                            to: 1
                            duration: 1000
                        }
                        NumberAnimation {
                            from: 1
                            to: 0.5
                            duration: 1000
                        }
                    }
                }
            }

            Item {
                Layout.preferredHeight: 12
            }
        }
    }
}
