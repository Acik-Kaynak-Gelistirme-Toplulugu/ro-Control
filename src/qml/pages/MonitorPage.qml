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
    required property var fanController

    property var theme: ({})
    property bool darkMode: false
    property bool showAdvancedInfo: true
    property real uiScale: 1.0
    property bool telemetryRefreshAnimating: false
    property int telemetryRefreshStep: 0

    readonly property color bgColor: theme && theme.card ? theme.card : (page.darkMode ? "#29233B" : "#FFFFFF")
    readonly property color cardColor: theme && theme.cardStrong ? theme.cardStrong : (page.darkMode ? "#342D4A" : "#F1F5F9")
    readonly property color borderColor: theme && theme.border ? theme.border : (page.darkMode ? "#4D436B" : "#CBD5E1")
    readonly property color textColor: theme && theme.text ? theme.text : (page.darkMode ? "#F8FAFC" : "#0F172A")
    readonly property color softTextColor: theme && theme.textSoft ? theme.textSoft : (page.darkMode ? "#94A3B8" : "#64748B")
    readonly property color infoBg: theme && theme.infoBg ? theme.infoBg : (page.darkMode ? "#1E2548" : "#EFF6FF")
    readonly property color accentColor: theme && theme.accentA ? theme.accentA : (page.darkMode ? "#818CF8" : "#4F46E5")
    readonly property color activeCardColor: theme && theme.card ? theme.card : (page.darkMode ? "#342D4A" : "#E2E8F0")
    readonly property int summaryCardHeight: Math.round(138 * page.uiScale)

    function formatTemp(value) {
        if (value > 0)
            return value + " °C";
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

    function modeTitle(mode) {
        switch (mode) {
        case "silent": return qsTr("Silent (Acoustic)");
        case "balanced": return qsTr("Balanced (Optimized)");
        case "performance": return qsTr("Performance (High Cooling)");
        case "manual": return qsTr("Manual (Fixed Speed)");
        case "custom": return qsTr("Custom Curve");
        case "auto":
        default: return qsTr("Auto (VBIOS / Driver)");
        }
    }

    function modeBadgeText() {
        if (page.fanController && page.fanController.safetyOverrideActive)
            return qsTr("SAFETY OVERRIDE 100%");
        if (!page.fanController || !page.fanController.supported)
            return qsTr("UNSUPPORTED");
        if (!page.fanController.controlSupported)
            return qsTr("TELEMETRY ONLY");
        return page.fanController.fanMode.toUpperCase();
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
        } else if (page.telemetryRefreshStep === 3 && page.fanController) {
            page.fanController.start();
            page.fanController.refresh();
        }

        page.telemetryRefreshStep += 1;
        if (page.telemetryRefreshStep < 4) {
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
            spacing: 12

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
                        Label {
                            text: qsTr("Temp: %1 | Fan: %2%")
                                  .arg(page.formatTemp(page.gpuMonitor ? page.gpuMonitor.temperatureC : -1))
                                  .arg(page.fanController ? page.fanController.currentFanSpeedPercent : (page.gpuMonitor ? page.gpuMonitor.fanSpeedPercent : 0))
                            color: page.softTextColor
                        }
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
                                text: qsTr("Memory");
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

            // System Information Section
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

            // Live Resource Bars Section
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

                    Label { text: qsTr("GPU Fan Speed"); color: page.softTextColor }
                    Label {
                        Layout.fillWidth: true
                        text: qsTr("Speed: %1% | Target: %2% | RPM: %3")
                              .arg(page.fanController ? page.fanController.currentFanSpeedPercent : 0)
                              .arg(page.fanController ? page.fanController.targetFanSpeedPercent : 0)
                              .arg(page.fanController && page.fanController.currentRpm > 0 ? page.fanController.currentRpm : qsTr("Auto"))
                        color: page.softTextColor
                        font.pixelSize: Math.round(12 * page.uiScale)
                    }
                    ProgressBar {
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: page.fanController ? page.fanController.currentFanSpeedPercent : (page.gpuMonitor ? page.gpuMonitor.fanSpeedPercent : 0)
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
        if (page.fanController) {
            page.fanController.start();
            page.fanController.refresh();
        }
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
