import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page

    property var theme: ({})
    property bool darkMode: false
    property bool showAdvancedInfo: true
    property real uiScale: 1.0

    readonly property color bgColor: theme && theme.card ? theme.card : "#ffffff"
    readonly property color cardColor: theme && theme.cardStrong ? theme.cardStrong : "#f5f8ff"
    readonly property color borderColor: theme && theme.border ? theme.border : "#d9e1f0"
    readonly property color textColor: theme && theme.text ? theme.text : "#12213a"
    readonly property color softTextColor: theme && theme.textSoft ? theme.textSoft : "#6f829e"

    function formatTemp(value) {
        return value > 0 ? value + " C" : qsTr("Unavailable");
    }

    function formatRam(used, total) {
        return total > 0 ? used + " / " + total + " MiB" : qsTr("Unavailable");
    }

    ScrollView {
        id: pageScroll
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: pageScroll.availableWidth
            spacing: 10

            GridLayout {
                Layout.fillWidth: true
                columns: width > 900 ? 3 : 1
                columnSpacing: 10
                rowSpacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 126
                    radius: 14
                    color: page.cardColor
                    border.width: 1
                    border.color: page.borderColor

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        Label { text: qsTr("CPU"); color: page.softTextColor; font.bold: true }
                        Label { text: cpuMonitor.usagePercent.toFixed(1) + "%"; color: page.textColor; font.pixelSize: Math.round(22 * page.uiScale); font.bold: true }
                        Label { text: qsTr("Temperature: %1").arg(page.formatTemp(cpuMonitor.temperatureC)); color: page.softTextColor }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 126
                    radius: 14
                    color: page.cardColor
                    border.width: 1
                    border.color: page.borderColor

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        Label { text: qsTr("GPU"); color: page.softTextColor; font.bold: true }
                        Label { text: gpuMonitor.utilizationPercent + "%"; color: page.textColor; font.pixelSize: Math.round(22 * page.uiScale); font.bold: true }
                        Label { text: qsTr("Temperature: %1").arg(page.formatTemp(gpuMonitor.temperatureC)); color: page.softTextColor }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 126
                    radius: 14
                    color: page.cardColor
                    border.width: 1
                    border.color: page.borderColor

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        Label { text: qsTr("Memory"); color: page.softTextColor; font.bold: true }
                        Label { text: ramMonitor.usagePercent + "%"; color: page.textColor; font.pixelSize: Math.round(22 * page.uiScale); font.bold: true }
                        Label { text: qsTr("Usage: %1").arg(page.formatRam(ramMonitor.usedMiB, ramMonitor.totalMiB)); color: page.softTextColor }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 14
                color: page.cardColor
                border.width: 1
                border.color: page.borderColor
                implicitHeight: chartArea.implicitHeight + 24

                ColumnLayout {
                    id: chartArea
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Label {
                        text: qsTr("Live Resource Bars")
                        color: page.textColor
                        font.pixelSize: Math.round(18 * page.uiScale)
                        font.bold: true
                    }

                    Label { text: qsTr("CPU"); color: page.softTextColor }
                    ProgressBar {
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: cpuMonitor.usagePercent
                    }

                    Label { text: qsTr("GPU"); color: page.softTextColor }
                    ProgressBar {
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: gpuMonitor.utilizationPercent
                    }

                    Label { text: qsTr("RAM"); color: page.softTextColor }
                    ProgressBar {
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: ramMonitor.usagePercent
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Button {
                            text: qsTr("Refresh")
                            onClicked: {
                                cpuMonitor.refresh();
                                gpuMonitor.refresh();
                                ramMonitor.refresh();
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            visible: page.showAdvancedInfo
                            text: qsTr("Interval: %1 ms").arg(cpuMonitor.updateInterval)
                            color: page.softTextColor
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 14
                color: page.cardColor
                border.width: 1
                border.color: page.borderColor
                implicitHeight: detailLayout.implicitHeight + 24

                ColumnLayout {
                    id: detailLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Label {
                        text: qsTr("Detailed Telemetry")
                        color: page.textColor
                        font.pixelSize: Math.round(18 * page.uiScale)
                        font.bold: true
                    }

                    Label {
                        text: qsTr("CPU Temperature: %1").arg(page.formatTemp(cpuMonitor.temperatureC))
                        color: page.softTextColor
                    }

                    Label {
                        text: qsTr("GPU Temperature: %1").arg(page.formatTemp(gpuMonitor.temperatureC))
                        color: page.softTextColor
                    }

                    Label {
                        text: qsTr("GPU Memory: %1 / %2 MiB")
                                  .arg(gpuMonitor.memoryUsedMiB)
                                  .arg(gpuMonitor.memoryTotalMiB)
                        color: page.softTextColor
                    }

                    Label {
                        text: qsTr("RAM Used: %1 / %2 MiB")
                                  .arg(ramMonitor.usedMiB)
                                  .arg(ramMonitor.totalMiB)
                        color: page.softTextColor
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        systemInfo.refresh();
        cpuMonitor.start();
        gpuMonitor.start();
        ramMonitor.start();
        cpuMonitor.refresh();
        gpuMonitor.refresh();
        ramMonitor.refresh();
    }
}
