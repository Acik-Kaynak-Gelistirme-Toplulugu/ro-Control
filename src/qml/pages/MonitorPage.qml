import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: page
    required property var cpuMonitor
    required property var gpuMonitor
    required property var ramMonitor

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        Label {
            text: "Sistem Izleme"
            font.pixelSize: 24
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            radius: 10
            border.width: 1
            border.color: "#5f6b86"
            color: "transparent"
            implicitHeight: cpuCol.implicitHeight + 18

            ColumnLayout {
                id: cpuCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Label {
                    text: "CPU"
                    font.bold: true
                }

                Label {
                    text: page.cpuMonitor.available ? "Kullanim: " + page.cpuMonitor.usagePercent.toFixed(1) + "%" : "CPU verisi alinamiyor"
                }

                ProgressBar {
                    from: 0
                    to: 100
                    value: page.cpuMonitor.usagePercent
                    Layout.fillWidth: true
                }

                Label {
                    text: "Sicaklik: " + page.cpuMonitor.temperatureC + " C"
                    visible: page.cpuMonitor.temperatureC > 0
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: 10
            border.width: 1
            border.color: "#5f6b86"
            color: "transparent"
            implicitHeight: gpuCol.implicitHeight + 18

            ColumnLayout {
                id: gpuCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Label {
                    text: "GPU (NVIDIA)"
                    font.bold: true
                }

                Label {
                    text: page.gpuMonitor.available ? (page.gpuMonitor.gpuName.length > 0 ? page.gpuMonitor.gpuName : "NVIDIA GPU") : "nvidia-smi ile veri alinamadi"
                }

                Label {
                    text: "Yuk: " + page.gpuMonitor.utilizationPercent + "%"
                    visible: page.gpuMonitor.available
                }

                ProgressBar {
                    from: 0
                    to: 100
                    value: page.gpuMonitor.utilizationPercent
                    Layout.fillWidth: true
                    visible: page.gpuMonitor.available
                }

                Label {
                    text: "VRAM: " + page.gpuMonitor.memoryUsedMiB + " / " + page.gpuMonitor.memoryTotalMiB + " MiB (" + page.gpuMonitor.memoryUsagePercent + "%)"
                    visible: page.gpuMonitor.available && page.gpuMonitor.memoryTotalMiB > 0
                }

                Label {
                    text: "Sicaklik: " + page.gpuMonitor.temperatureC + " C"
                    visible: page.gpuMonitor.available && page.gpuMonitor.temperatureC > 0
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: 10
            border.width: 1
            border.color: "#5f6b86"
            color: "transparent"
            implicitHeight: ramCol.implicitHeight + 18

            ColumnLayout {
                id: ramCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Label {
                    text: "RAM"
                    font.bold: true
                }

                Label {
                    text: page.ramMonitor.available ? "Kullanim: " + page.ramMonitor.usedMiB + " / " + page.ramMonitor.totalMiB + " MiB (" + page.ramMonitor.usagePercent + "%)" : "RAM verisi alinamiyor"
                }

                ProgressBar {
                    from: 0
                    to: 100
                    value: page.ramMonitor.usagePercent
                    Layout.fillWidth: true
                }
            }
        }

        RowLayout {
            spacing: 8

            Button {
                text: "Yenile"
                onClicked: {
                    page.cpuMonitor.refresh();
                    page.gpuMonitor.refresh();
                    page.ramMonitor.refresh();
                }
            }

            Label {
                text: "Guncelleme araligi: " + page.cpuMonitor.updateInterval + " ms"
                color: "#6d7384"
            }
        }
    }
}
