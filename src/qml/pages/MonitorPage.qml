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

    readonly property color bgColor: theme && theme.card ? theme.card : "#ffffff"
    readonly property color cardColor: theme && theme.cardStrong ? theme.cardStrong : "#f5f8ff"
    readonly property color borderColor: theme && theme.border ? theme.border : "#d9e1f0"
    readonly property color textColor: theme && theme.text ? theme.text : "#12213a"
    readonly property color softTextColor: theme && theme.textSoft ? theme.textSoft : "#6f829e"
    readonly property color infoBg: theme && theme.infoBg ? theme.infoBg : "#e9f2ff"
    readonly property color accentColor: theme && theme.accentA ? theme.accentA : "#92c7cf"
    readonly property color activeCardColor: theme && theme.card ? theme.card : "#e5e1da"
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

            // ─── Fan Control & Optimization Panel ─────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                radius: 14
                color: page.cardColor
                border.width: 1
                border.color: page.borderColor
                implicitHeight: fanLayout.implicitHeight + 28

                ColumnLayout {
                    id: fanLayout
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: qsTr("GPU Fan Control & Optimization")
                                color: page.textColor
                                font.pixelSize: Math.round(18 * page.uiScale)
                                font.weight: Font.DemiBold
                            }

                            Label {
                                text: page.fanController ? page.fanController.statusMessage : qsTr("Manage fan speed profiles and custom curves.")
                                color: page.softTextColor
                                font.pixelSize: Math.round(12 * page.uiScale)
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                        }

                        Components.InfoBadge {
                            text: page.modeBadgeText()
                            backgroundColor: page.fanController && page.fanController.safetyOverrideActive ? "#d9534f" : page.accentColor
                            foregroundColor: page.textColor
                        }
                    }

                    // Profile Selector Buttons
                    Label {
                        text: qsTr("Optimization Profiles & Modes")
                        color: page.softTextColor
                        font.pixelSize: Math.round(12 * page.uiScale)
                        font.weight: Font.DemiBold
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width > 800 ? 6 : (width > 500 ? 3 : 2)
                        columnSpacing: 8
                        rowSpacing: 8

                        Repeater {
                            model: [
                                { mode: "auto", label: qsTr("⚡ Auto"), desc: qsTr("VBIOS/Driver") },
                                { mode: "silent", label: qsTr("🍃 Silent"), desc: qsTr("Quiet Curve") },
                                { mode: "balanced", label: qsTr("⚖️ Balanced"), desc: qsTr("Optimized") },
                                { mode: "performance", label: qsTr("🔥 Performance"), desc: qsTr("Aggressive") },
                                { mode: "manual", label: qsTr("🛠️ Manual"), desc: qsTr("Fixed Speed") },
                                { mode: "custom", label: qsTr("📈 Custom"), desc: qsTr("User Curve") }
                            ]

                            delegate: Button {
                                id: modeBtn
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: Math.round(52 * page.uiScale)
                                checkable: true
                                checked: page.fanController && page.fanController.fanMode === modelData.mode

                                background: Rectangle {
                                    radius: 10
                                    color: modeBtn.checked ? page.accentColor : page.bgColor
                                    border.width: modeBtn.checked ? 2 : 1
                                    border.color: modeBtn.checked ? page.textColor : page.borderColor
                                }

                                contentItem: Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modeBtn.modelData.label
                                        color: page.textColor
                                        font.pixelSize: Math.round(12 * page.uiScale)
                                        font.weight: modeBtn.checked ? Font.Bold : Font.Medium
                                    }
                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modeBtn.modelData.desc
                                        color: page.softTextColor
                                        font.pixelSize: Math.round(10 * page.uiScale)
                                    }
                                }

                                onClicked: {
                                    if (page.fanController) {
                                        page.fanController.setFanMode(modelData.mode);
                                    }
                                }
                            }
                        }
                    }

                    // Manual Speed Slider (Visible in Manual mode)
                    Rectangle {
                        Layout.fillWidth: true
                        radius: 10
                        color: page.bgColor
                        border.width: 1
                        border.color: page.borderColor
                        implicitHeight: manualCol.implicitHeight + 20
                        visible: page.fanController && page.fanController.fanMode === "manual"

                        ColumnLayout {
                            id: manualCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: qsTr("Manual Fan Speed: %1%").arg(manualSlider.value)
                                    color: page.textColor
                                    font.pixelSize: Math.round(14 * page.uiScale)
                                    font.weight: Font.DemiBold
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: qsTr("Target: %1%").arg(page.fanController ? page.fanController.targetFanSpeedPercent : 0)
                                    color: page.softTextColor
                                    font.pixelSize: Math.round(12 * page.uiScale)
                                }
                            }

                            Slider {
                                id: manualSlider
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                stepSize: 1
                                value: page.fanController ? page.fanController.manualFanSpeedPercent : 50
                                onMoved: {
                                    if (page.fanController) {
                                        page.fanController.setManualFanSpeedPercent(Math.round(value));
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Label { text: qsTr("Presets:"); color: page.softTextColor; font.pixelSize: Math.round(11 * page.uiScale) }
                                Repeater {
                                    model: [30, 50, 75, 100]
                                    delegate: Button {
                                        required property int modelData
                                        text: modelData + "%"
                                        implicitHeight: Math.round(28 * page.uiScale)
                                        background: Rectangle {
                                            radius: 6
                                            color: manualSlider.value === modelData ? page.accentColor : page.cardColor
                                            border.width: 1
                                            border.color: page.borderColor
                                        }
                                        contentItem: Text {
                                            text: parent.text
                                            color: page.textColor
                                            font.pixelSize: Math.round(11 * page.uiScale)
                                            font.weight: Font.Medium
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        onClicked: {
                                            manualSlider.value = modelData;
                                            if (page.fanController) {
                                                page.fanController.setManualFanSpeedPercent(modelData);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Custom Curve Editor (Visible in Custom mode)
                    Rectangle {
                        Layout.fillWidth: true
                        radius: 10
                        color: page.bgColor
                        border.width: 1
                        border.color: page.borderColor
                        implicitHeight: customCol.implicitHeight + 20
                        visible: page.fanController && page.fanController.fanMode === "custom"

                        ColumnLayout {
                            id: customCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: qsTr("Custom Temperature-Fan Curve Points")
                                    color: page.textColor
                                    font.pixelSize: Math.round(14 * page.uiScale)
                                    font.weight: Font.DemiBold
                                    Layout.fillWidth: true
                                }
                                Button {
                                    text: qsTr("Reset to Default Curve")
                                    implicitHeight: Math.round(28 * page.uiScale)
                                    background: Rectangle {
                                        radius: 6
                                        color: page.cardColor
                                        border.width: 1
                                        border.color: page.borderColor
                                    }
                                    contentItem: Text {
                                        text: parent.text
                                        color: page.textColor
                                        font.pixelSize: Math.round(11 * page.uiScale)
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    onClicked: {
                                        if (page.fanController) page.fanController.resetCustomCurve();
                                    }
                                }
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: width > 700 ? 4 : 2
                                columnSpacing: 8
                                rowSpacing: 8

                                Repeater {
                                    model: page.fanController ? page.fanController.customCurvePoints : []

                                    delegate: Rectangle {
                                        id: ptCard
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        implicitHeight: Math.round(80 * page.uiScale)
                                        radius: 8
                                        color: page.cardColor
                                        border.width: 1
                                        border.color: page.borderColor

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 4

                                            Label {
                                                text: qsTr("Point %1: %2 °C").arg(ptCard.index + 1).arg(ptCard.modelData.temp)
                                                color: page.textColor
                                                font.pixelSize: Math.round(12 * page.uiScale)
                                                font.weight: Font.DemiBold
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Label { text: qsTr("Speed:"); color: page.softTextColor; font.pixelSize: Math.round(11 * page.uiScale) }
                                                Slider {
                                                    id: ptSlider
                                                    Layout.fillWidth: true
                                                    from: 0
                                                    to: 100
                                                    stepSize: 5
                                                    value: ptCard.modelData.speed
                                                    onMoved: {
                                                        if (page.fanController) {
                                                            page.fanController.setCustomCurvePoint(ptCard.index, ptCard.modelData.temp, Math.round(value));
                                                        }
                                                    }
                                                }
                                                Label { text: ptCard.modelData.speed + "%"; color: page.textColor; font.pixelSize: Math.round(11 * page.uiScale); font.weight: Font.DemiBold }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Thermal Watchdog & Safety Info Banner
                    Rectangle {
                        Layout.fillWidth: true
                        radius: 8
                        color: page.fanController && page.fanController.safetyOverrideActive ? "#ffebe9" : page.infoBg
                        border.width: 1
                        border.color: page.fanController && page.fanController.safetyOverrideActive ? "#d9534f" : page.borderColor
                        implicitHeight: safetyRow.implicitHeight + 14

                        RowLayout {
                            id: safetyRow
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Label {
                                text: page.fanController && page.fanController.safetyOverrideActive
                                      ? qsTr("⚠️ Thermal Watchdog Warning: GPU is at %1 °C (>= %2 °C). Fan is forced to 100% to protect hardware.")
                                        .arg(page.gpuMonitor ? page.gpuMonitor.temperatureC : 0)
                                        .arg(page.fanController ? page.fanController.thermalThresholdC : 85)
                                      : qsTr("🛡️ Thermal Safety Guard: If GPU temperature reaches %1 °C, 100% fan speed is automatically enforced regardless of profile.")
                                        .arg(page.fanController ? page.fanController.thermalThresholdC : 85)
                                color: page.fanController && page.fanController.safetyOverrideActive ? "#c92a2a" : page.textColor
                                font.pixelSize: Math.round(11 * page.uiScale)
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                        }
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
