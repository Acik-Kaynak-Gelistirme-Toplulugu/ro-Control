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
    property var powerController: null
    property var healthGuard: null

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
            return qsTr("HARDWARE AUTO");
        if (!page.fanController.controlSupported)
            return qsTr("HARDWARE MANAGED");
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
                            text: {
                                var tempStr = page.formatTemp(page.gpuMonitor ? page.gpuMonitor.temperatureC : -1);
                                var fanPct = page.fanController ? page.fanController.currentFanSpeedPercent : (page.gpuMonitor ? page.gpuMonitor.fanSpeedPercent : 0);
                                var fanRpm = page.fanController ? page.fanController.currentRpm : 0;
                                if (fanRpm > 0) {
                                    return qsTr("Temp: %1 | Fan: %2% (%3 RPM)").arg(tempStr).arg(fanPct).arg(fanRpm);
                                } else if (fanPct === 0) {
                                    return qsTr("Temp: %1 | Fan: 0% (0 RPM)").arg(tempStr);
                                }
                                return qsTr("Temp: %1 | Fan: %2%").arg(tempStr).arg(fanPct);
                            }
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
                                { title: qsTr("Power Source"), value: page.safeText(page.systemInfo ? page.systemInfo.powerSource : "") }
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

            // GPU Performance & Power Telemetry Section
            Rectangle {
                Layout.fillWidth: true
                radius: 14
                color: page.cardColor
                border.width: 1
                border.color: page.borderColor
                implicitHeight: gpuPerfLayout.implicitHeight + 24
                visible: page.showAdvancedInfo && page.gpuMonitor && page.gpuMonitor.available

                ColumnLayout {
                    id: gpuPerfLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("GPU Performance & Power")
                            color: page.textColor
                            font.pixelSize: Math.round(18 * page.uiScale)
                            font.weight: Font.DemiBold
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width > 920 ? 5 : (width > 560 ? 3 : 2)
                        columnSpacing: 8
                        rowSpacing: 8

                        Repeater {
                            model: [
                                {
                                    title: qsTr("Power Draw / Limit"),
                                    value: (page.gpuMonitor && page.gpuMonitor.powerDrawW > 0)
                                           ? (page.gpuMonitor.powerDrawW.toFixed(0) + " W" +
                                              (page.gpuMonitor.powerLimitW > 0 ? (" / " + page.gpuMonitor.powerLimitW.toFixed(0) + " W") : ""))
                                           : qsTr("Dynamic Power")
                                },
                                {
                                    title: qsTr("Graphics Clock"),
                                    value: (page.gpuMonitor && page.gpuMonitor.graphicsClockMHz > 0)
                                           ? (page.gpuMonitor.graphicsClockMHz + " MHz")
                                           : qsTr("Dynamic Clock")
                                },
                                {
                                    title: qsTr("Memory Clock"),
                                    value: (page.gpuMonitor && page.gpuMonitor.memoryClockMHz > 0)
                                           ? (page.gpuMonitor.memoryClockMHz + " MHz")
                                           : qsTr("Dynamic Clock")
                                },
                                {
                                    title: qsTr("PCIe Link"),
                                    value: (page.gpuMonitor && page.gpuMonitor.pcieLinkStatus.length > 0)
                                           ? page.gpuMonitor.pcieLinkStatus
                                           : qsTr("PCIe Auto")
                                },
                                {
                                    title: qsTr("VRAM Allocation"),
                                    value: (page.gpuMonitor && page.gpuMonitor.memoryTotalMiB > 0)
                                           ? (page.gpuMonitor.memoryUsedMiB + " / " + page.gpuMonitor.memoryTotalMiB + " MiB")
                                           : qsTr("Unavailable")
                                },
                                {
                                    title: qsTr("Hotspot / VRAM Temp"),
                                    value: (page.gpuMonitor && page.gpuMonitor.hotspotTemperatureC > 0)
                                           ? (page.gpuMonitor.hotspotTemperatureC + " °C (Hotspot)" +
                                              (page.gpuMonitor.memoryTemperatureC > 0 ? (" / " + page.gpuMonitor.memoryTemperatureC + " °C Mem") : ""))
                                           : ((page.gpuMonitor && page.gpuMonitor.memoryTemperatureC > 0)
                                              ? (page.gpuMonitor.memoryTemperatureC + " °C (Mem)")
                                              : qsTr("Nominal Core"))
                                }
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

            // GPU Task Manager / Active Applications Section
            Rectangle {
                Layout.fillWidth: true
                radius: 14
                color: page.cardColor
                border.width: 1
                border.color: page.borderColor
                implicitHeight: gpuProcLayout.implicitHeight + 24

                ColumnLayout {
                    id: gpuProcLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("GPU Task Manager & Active Processes")
                            color: page.textColor
                            font.pixelSize: Math.round(18 * page.uiScale)
                            font.weight: Font.DemiBold
                        }

                        Components.InfoBadge {
                            text: (page.gpuMonitor && page.gpuMonitor.gpuProcessCount > 0)
                                  ? qsTr("%1 ACTIVE").arg(page.gpuMonitor.gpuProcessCount)
                                  : qsTr("0 ACTIVE")
                            backgroundColor: (page.gpuMonitor && page.gpuMonitor.gpuProcessCount > 0)
                                             ? (page.darkMode ? "#312E81" : "#EEF2FF")
                                             : (page.darkMode ? "#1E293B" : "#F1F5F9")
                            foregroundColor: (page.gpuMonitor && page.gpuMonitor.gpuProcessCount > 0)
                                             ? page.accentColor
                                             : page.softTextColor
                        }
                    }

                    // Empty state when no GPU processes are running
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.round(72 * page.uiScale)
                        radius: 10
                        color: page.bgColor
                        border.width: 1
                        border.color: page.borderColor
                        visible: !page.gpuMonitor || page.gpuMonitor.gpuProcessCount === 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            Rectangle {
                                width: Math.round(36 * page.uiScale)
                                height: Math.round(36 * page.uiScale)
                                radius: 8
                                color: page.darkMode ? "#1E293B" : "#E2E8F0"

                                Label {
                                    anchors.centerIn: parent
                                    text: "✓"
                                    color: "#22C55E"
                                    font.pixelSize: Math.round(18 * page.uiScale)
                                    font.weight: Font.Bold
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: qsTr("No Active GPU Processes")
                                    color: page.textColor
                                    font.pixelSize: Math.round(13 * page.uiScale)
                                    font.weight: Font.DemiBold
                                }

                                Label {
                                    text: qsTr("No applications are currently allocating VRAM or compute resources on this GPU.")
                                    color: page.softTextColor
                                    font.pixelSize: Math.round(11 * page.uiScale)
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    // Process list table when processes exist
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: page.gpuMonitor && page.gpuMonitor.gpuProcessCount > 0

                        // Table header
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            spacing: 12

                            Label {
                                Layout.preferredWidth: Math.round(60 * page.uiScale)
                                text: qsTr("PID")
                                color: page.softTextColor
                                font.pixelSize: Math.round(11 * page.uiScale)
                                font.weight: Font.Bold
                            }

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("PROCESS NAME")
                                color: page.softTextColor
                                font.pixelSize: Math.round(11 * page.uiScale)
                                font.weight: Font.Bold
                            }

                            Label {
                                Layout.preferredWidth: Math.round(110 * page.uiScale)
                                text: qsTr("TYPE")
                                color: page.softTextColor
                                font.pixelSize: Math.round(11 * page.uiScale)
                                font.weight: Font.Bold
                            }

                            Label {
                                Layout.preferredWidth: Math.round(130 * page.uiScale)
                                text: qsTr("VRAM USAGE")
                                color: page.softTextColor
                                font.pixelSize: Math.round(11 * page.uiScale)
                                font.weight: Font.Bold
                                horizontalAlignment: Text.AlignRight
                            }

                            Label {
                                Layout.preferredWidth: Math.round(80 * page.uiScale)
                                text: qsTr("ACTION")
                                color: page.softTextColor
                                font.pixelSize: Math.round(11 * page.uiScale)
                                font.weight: Font.Bold
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        Repeater {
                            model: page.gpuMonitor ? page.gpuMonitor.gpuProcesses : []

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: Math.round(48 * page.uiScale)
                                radius: 8
                                color: page.bgColor
                                border.width: 1
                                border.color: page.borderColor

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    Rectangle {
                                        Layout.preferredWidth: Math.round(60 * page.uiScale)
                                        Layout.preferredHeight: Math.round(24 * page.uiScale)
                                        radius: 4
                                        color: page.darkMode ? "#1E293B" : "#E2E8F0"

                                        Label {
                                            anchors.centerIn: parent
                                            text: modelData.pid
                                            color: page.textColor
                                            font.pixelSize: Math.round(11 * page.uiScale)
                                            font.weight: Font.DemiBold
                                            font.family: (Qt.platform.os === "osx") ? "Menlo" : "Monospace"
                                        }
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        color: page.textColor
                                        font.pixelSize: Math.round(13 * page.uiScale)
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: Math.round(110 * page.uiScale)
                                        Layout.preferredHeight: Math.round(22 * page.uiScale)
                                        radius: 4
                                        color: (modelData.type && modelData.type.indexOf("Compute") !== -1)
                                               ? (page.darkMode ? "#312E81" : "#EEF2FF")
                                               : (page.darkMode ? "#064E3B" : "#ECFDF5")

                                        Label {
                                            anchors.centerIn: parent
                                            text: modelData.type || qsTr("Compute")
                                            color: (modelData.type && modelData.type.indexOf("Compute") !== -1)
                                                   ? (page.darkMode ? "#A5B4FC" : "#4F46E5")
                                                   : (page.darkMode ? "#6EE7B7" : "#059669")
                                            font.pixelSize: Math.round(10 * page.uiScale)
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.preferredWidth: Math.round(130 * page.uiScale)
                                        spacing: 2

                                        Label {
                                            Layout.fillWidth: true
                                            text: modelData.vramMiB + " MiB"
                                            color: page.accentColor
                                            font.pixelSize: Math.round(12 * page.uiScale)
                                            font.weight: Font.DemiBold
                                            horizontalAlignment: Text.AlignRight
                                        }

                                        ProgressBar {
                                            Layout.fillWidth: true
                                            from: 0
                                            to: page.gpuMonitor && page.gpuMonitor.memoryTotalMiB > 0 ? page.gpuMonitor.memoryTotalMiB : 1000
                                            value: modelData.vramMiB
                                            implicitHeight: 4
                                        }
                                    }

                                    Button {
                                        text: qsTr("End")
                                        flat: true
                                        implicitWidth: Math.round(75 * page.uiScale)
                                        implicitHeight: Math.round(30 * page.uiScale)
                                        onClicked: {
                                            if (page.gpuMonitor) {
                                                page.gpuMonitor.killProcess(modelData.pid);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // GPU Power & TDP Management Section
            Rectangle {
                Layout.fillWidth: true
                radius: 14
                color: page.cardColor
                border.width: 1
                border.color: page.borderColor
                implicitHeight: powerArea.implicitHeight + 24
                visible: page.powerController !== null && page.powerController.supported

                ColumnLayout {
                    id: powerArea
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("GPU Power & Performance Management")
                            color: page.textColor
                            font.pixelSize: Math.round(18 * page.uiScale)
                            font.weight: Font.DemiBold
                        }

                        Components.InfoBadge {
                            text: page.powerController && page.powerController.persistenceModeEnabled ? qsTr("PERSISTENCE ON") : qsTr("STANDARD")
                            backgroundColor: page.powerController && page.powerController.persistenceModeEnabled ? "#22c55e" : (page.darkMode ? "#334155" : "#e2e8f0")
                            foregroundColor: page.powerController && page.powerController.persistenceModeEnabled ? "#ffffff" : page.textColor
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Label {
                            text: qsTr("Current Draw: %1 W").arg(page.powerController ? page.powerController.currentPowerDrawW.toFixed(1) : "0.0")
                            color: page.textColor
                            font.pixelSize: Math.round(13 * page.uiScale)
                            font.weight: Font.DemiBold
                        }

                        Label {
                            text: qsTr("Power Limit: %1 W").arg(page.powerController ? page.powerController.powerLimitW.toFixed(0) : "N/A")
                            color: page.accentColor
                            font.pixelSize: Math.round(13 * page.uiScale)
                            font.weight: Font.DemiBold
                        }

                        Item { Layout.fillWidth: true }

                        RowLayout {
                            spacing: 6
                            visible: page.powerController && page.powerController.controlSupported

                            Button {
                                text: qsTr("Eco")
                                highlighted: page.powerController && page.powerController.powerPreset === "eco"
                                onClicked: if (page.powerController) page.powerController.applyPowerPreset("eco")
                            }
                            Button {
                                text: qsTr("Balanced")
                                highlighted: page.powerController && page.powerController.powerPreset === "balanced"
                                onClicked: if (page.powerController) page.powerController.applyPowerPreset("balanced")
                            }
                            Button {
                                text: qsTr("Performance")
                                highlighted: page.powerController && page.powerController.powerPreset === "performance"
                                onClicked: if (page.powerController) page.powerController.applyPowerPreset("performance")
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
