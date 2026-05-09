import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page
    required property var systemInfo
    required property var cpuMonitor
    required property var gpuMonitor
    required property var ramMonitor

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
                    implicitHeight: page.gpuMonitor && page.gpuMonitor.available ? 126 : 154
                    radius: 14
                    color: page.cardColor
                    border.width: 1
                    border.color: page.borderColor

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        Label { text: qsTr("CPU"); color: page.softTextColor; font.bold: true }
                        Label { text: page.cpuMonitor ? page.cpuMonitor.usagePercent.toFixed(1) + "%" : "--"; color: page.textColor; font.pixelSize: Math.round(22 * page.uiScale); font.bold: true }
                        Label { text: qsTr("Temperature: %1").arg(page.formatTemp(page.cpuMonitor ? page.cpuMonitor.temperatureC : -1)); color: page.softTextColor }
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
                        Label { text: page.gpuMonitor ? page.gpuMonitor.utilizationPercent + "%" : "--"; color: page.textColor; font.pixelSize: Math.round(22 * page.uiScale); font.bold: true }
                        Label { text: qsTr("Temperature: %1").arg(page.formatTemp(page.gpuMonitor ? page.gpuMonitor.temperatureC : -1)); color: page.softTextColor }
                        Label {
                            visible: page.gpuMonitor && !page.gpuMonitor.available && page.gpuMonitor.statusMessage.length > 0
                            text: page.gpuMonitor ? page.gpuMonitor.statusMessage : ""
                            color: page.softTextColor
                            wrapMode: Text.Wrap
                            width: parent.width
                        }
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
                        Label { text: page.ramMonitor ? page.ramMonitor.usagePercent + "%" : "--"; color: page.textColor; font.pixelSize: Math.round(22 * page.uiScale); font.bold: true }
                        Label { text: qsTr("Usage: %1").arg(page.formatRam(page.ramMonitor ? page.ramMonitor.usedMiB : 0, page.ramMonitor ? page.ramMonitor.totalMiB : 0)); color: page.softTextColor }
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
                        value: page.cpuMonitor ? page.cpuMonitor.usagePercent : 0
                    }

                    Label { text: qsTr("GPU"); color: page.softTextColor }
                    ProgressBar {
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: page.gpuMonitor ? page.gpuMonitor.utilizationPercent : 0
                    }

                    Label { text: qsTr("RAM"); color: page.softTextColor }
                    ProgressBar {
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: page.ramMonitor ? page.ramMonitor.usagePercent : 0
                    }

                }
            }
        }
    }

    Component.onCompleted: {
        if (page.systemInfo)
            page.systemInfo.refresh();
        if (page.cpuMonitor)
            page.cpuMonitor.start();
        if (page.gpuMonitor)
            page.gpuMonitor.start();
        if (page.ramMonitor)
            page.ramMonitor.start();
    }
}
