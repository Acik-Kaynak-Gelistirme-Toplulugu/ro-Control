import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

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
    property bool telemetryRefreshAnimating: false
    property int telemetryRefreshStep: 0

    readonly property color bgColor: theme && theme.card ? theme.card : "#ffffff"
    readonly property color cardColor: theme && theme.cardStrong ? theme.cardStrong : "#f5f8ff"
    readonly property color borderColor: theme && theme.border ? theme.border : "#d9e1f0"
    readonly property color textColor: theme && theme.text ? theme.text : "#12213a"
    readonly property color softTextColor: theme && theme.textSoft ? theme.textSoft : "#6f829e"
    readonly property color infoBg: theme && theme.infoBg ? theme.infoBg : "#e9f2ff"
    readonly property int summaryCardHeight: Math.round(138 * page.uiScale)

    function formatTemp(value) {
        if (value > 0)
            return value + " C";
        if (page.systemInfo && page.systemInfo.virtualMachine)
            return qsTr("VM sensor unavailable");
        return qsTr("Unavailable");
    }

    function formatRam(used, total) {
        return total > 0 ? used + " / " + total + " MiB" : qsTr("Unavailable");
    }

    function safeText(value) {
        return value && value.length > 0 ? value : qsTr("Unavailable");
    }

    function deviceTypeLabel() {
        if (!page.systemInfo)
            return qsTr("Unavailable");
        return page.systemInfo.deviceType && page.systemInfo.deviceType.length > 0
               ? page.systemInfo.deviceType
               : qsTr("Unavailable");
    }

    function refreshTelemetry() {
        if (page.telemetryRefreshAnimating)
            return;
        page.telemetryRefreshAnimating = true;
        page.telemetryRefreshStep = 0;
        telemetryRefreshQueue.restart();
    }

    function refreshTelemetryStep() {
        if (page.telemetryRefreshStep === 0 && page.ramMonitor) {
            page.ramMonitor.start();
            page.ramMonitor.refresh();
        } else if (page.telemetryRefreshStep === 1 && page.cpuMonitor) {
            page.cpuMonitor.start();
            page.cpuMonitor.refresh();
        } else if (page.telemetryRefreshStep === 2 && page.gpuMonitor) {
            page.gpuMonitor.start();
            page.gpuMonitor.refresh();
        }

        page.telemetryRefreshStep += 1;
        if (page.telemetryRefreshStep < 3) {
            telemetryRefreshQueue.restart();
        } else {
            telemetryRefreshPulse.restart();
        }
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
                    Layout.preferredHeight: page.summaryCardHeight
                    Layout.minimumHeight: page.summaryCardHeight
                    radius: 14
                    color: page.cardColor
                    border.width: 1
                    border.color: page.borderColor

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        Label { text: qsTr("CPU"); color: page.softTextColor; font.weight: Font.DemiBold; font.pixelSize: Math.round(12 * page.uiScale) }
                        Label { text: page.cpuMonitor ? page.cpuMonitor.usagePercent.toFixed(1) + "%" : "--"; color: page.textColor; font.pixelSize: Math.round(22 * page.uiScale); font.weight: Font.DemiBold }
                        Label { text: qsTr("Temperature: %1").arg(page.formatTemp(page.cpuMonitor ? page.cpuMonitor.temperatureC : -1)); color: page.softTextColor }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: page.summaryCardHeight
                    Layout.minimumHeight: page.summaryCardHeight
                    radius: 14
                    color: page.cardColor
                    border.width: 1
                    border.color: page.borderColor

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        Label { text: qsTr("GPU"); color: page.softTextColor; font.weight: Font.DemiBold; font.pixelSize: Math.round(12 * page.uiScale) }
                        Label { text: page.gpuMonitor ? page.gpuMonitor.utilizationPercent + "%" : "--"; color: page.textColor; font.pixelSize: Math.round(22 * page.uiScale); font.weight: Font.DemiBold }
                        Label { text: qsTr("Temperature: %1").arg(page.formatTemp(page.gpuMonitor ? page.gpuMonitor.temperatureC : -1)); color: page.softTextColor }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: page.summaryCardHeight
                    Layout.minimumHeight: page.summaryCardHeight
                    radius: 14
                    color: page.cardColor
                    border.width: 1
                    border.color: page.borderColor

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        RowLayout {
                            width: parent.width
                            spacing: 8

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Memory")
                                color: page.softTextColor
                                font.weight: Font.DemiBold
                                font.pixelSize: Math.round(12 * page.uiScale)
                            }
                        }

                        Label { text: page.ramMonitor ? page.ramMonitor.usagePercent + "%" : "--"; color: page.textColor; font.pixelSize: Math.round(22 * page.uiScale); font.weight: Font.DemiBold }
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
                implicitHeight: systemLayout.implicitHeight + 24
                visible: page.showAdvancedInfo

                ColumnLayout {
                    id: systemLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("System")
                            color: page.textColor
                            font.pixelSize: Math.round(18 * page.uiScale)
                            font.weight: Font.DemiBold
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width > 920 ? 4 : 1
                        columnSpacing: 8
                        rowSpacing: 8

                        Repeater {
                            model: [
                                { title: qsTr("Operating System"), value: page.safeText(page.systemInfo ? page.systemInfo.osName : "") },
                                { title: qsTr("Desktop"), value: page.safeText(page.systemInfo ? page.systemInfo.desktopEnvironment : "") },
                                { title: qsTr("Kernel"), value: page.safeText(page.systemInfo ? page.systemInfo.kernelVersion : "") },
                                { title: qsTr("Device Type"), value: page.deviceTypeLabel() }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: Math.round(76 * page.uiScale)
                                radius: 10
                                color: page.bgColor
                                border.width: 1
                                border.color: page.borderColor

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 4

                                    Label {
                                        width: parent.width
                                        text: modelData.title
                                        color: page.softTextColor
                                        font.pixelSize: Math.round(11 * page.uiScale)
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        width: parent.width
                                        text: modelData.value
                                        color: page.textColor
                                        font.pixelSize: Math.round(13 * page.uiScale)
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                }
                            }
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
                implicitHeight: chartArea.implicitHeight + 24

                ColumnLayout {
                    id: chartArea
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Live Resource Bars")
                            color: page.textColor
                            font.pixelSize: Math.round(18 * page.uiScale)
                            font.weight: Font.DemiBold
                        }

                        Components.RefreshToolButton {
                            id: telemetryRefreshButton
                            busy: page.telemetryRefreshAnimating
                            theme: page.theme
                            darkMode: page.darkMode
                            uiScale: page.uiScale
                            tooltip: qsTr("Refresh telemetry")
                            enabled: !page.telemetryRefreshAnimating
                            onClicked: page.refreshTelemetry()
                        }
                    }

                    Label { text: qsTr("CPU"); color: page.softTextColor }
                    Label {
                        Layout.fillWidth: true
                        text: qsTr("Usage: %1% | Temperature: %2")
                              .arg(page.cpuMonitor ? page.cpuMonitor.usagePercent.toFixed(1) : "--")
                              .arg(page.formatTemp(page.cpuMonitor ? page.cpuMonitor.temperatureC : -1))
                        color: page.softTextColor
                        font.pixelSize: Math.round(12 * page.uiScale)
                    }
                    ProgressBar {
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: page.cpuMonitor ? page.cpuMonitor.usagePercent : 0
                    }

                    Label { text: qsTr("GPU"); color: page.softTextColor }
                    Label {
                        Layout.fillWidth: true
                        text: qsTr("Usage: %1% | Temperature: %2")
                              .arg(page.gpuMonitor ? page.gpuMonitor.utilizationPercent : "--")
                              .arg(page.formatTemp(page.gpuMonitor ? page.gpuMonitor.temperatureC : -1))
                        color: page.softTextColor
                        font.pixelSize: Math.round(12 * page.uiScale)
                    }
                    ProgressBar {
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: page.gpuMonitor ? page.gpuMonitor.utilizationPercent : 0
                    }

                    Label { text: qsTr("RAM"); color: page.softTextColor }
                    Label {
                        Layout.fillWidth: true
                        text: qsTr("Usage: %1 (%2%)")
                              .arg(page.formatRam(page.ramMonitor ? page.ramMonitor.usedMiB : 0, page.ramMonitor ? page.ramMonitor.totalMiB : 0))
                              .arg(page.ramMonitor ? page.ramMonitor.usagePercent : "--")
                        color: page.softTextColor
                        font.pixelSize: Math.round(12 * page.uiScale)
                    }
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

    Timer {
        id: telemetryRefreshPulse
        interval: 300
        repeat: false
        onTriggered: page.telemetryRefreshAnimating = false
    }

    Timer {
        id: telemetryRefreshQueue
        interval: 180
        repeat: false
        onTriggered: page.refreshTelemetryStep()
    }
}
