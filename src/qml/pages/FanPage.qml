import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

Item {
    id: page
    required property var systemInfo
    required property var cpuMonitor
    required property var gpuMonitor
    required property var fanController

    property var theme: ({})
    property bool darkMode: false
    property bool showAdvancedInfo: true
    property real uiScale: 1.0
    property bool refreshAnimating: false

    readonly property color bgColor: theme && theme.card ? theme.card : (page.darkMode ? "#29233B" : "#FFFFFF")
    readonly property color cardColor: theme && theme.cardStrong ? theme.cardStrong : (page.darkMode ? "#342D4A" : "#F1F5F9")
    readonly property color borderColor: theme && theme.border ? theme.border : (page.darkMode ? "#4D436B" : "#CBD5E1")
    readonly property color textColor: theme && theme.text ? theme.text : (page.darkMode ? "#F8FAFC" : "#0F172A")
    readonly property color softTextColor: theme && theme.textSoft ? theme.textSoft : (page.darkMode ? "#94A3B8" : "#64748B")
    readonly property color accentColor: theme && theme.accentA ? theme.accentA : (page.darkMode ? "#818CF8" : "#4F46E5")
    readonly property color accentButtonText: page.darkMode ? "#FFFFFF" : "#FFFFFF"
    readonly property color infoBg: theme && theme.infoBg ? theme.infoBg : (page.darkMode ? "#1E2548" : "#EFF6FF")
    readonly property color warningBg: theme && theme.warningBg ? theme.warningBg : (page.darkMode ? "#3A2E12" : "#FFFBEB")
    readonly property color warningText: theme && theme.warning ? theme.warning : (page.darkMode ? "#FBBF24" : "#D97706")
    readonly property color successBg: theme && theme.successBg ? theme.successBg : (page.darkMode ? "#143828" : "#ECFDF5")
    readonly property color successText: theme && theme.success ? theme.success : (page.darkMode ? "#4ADE80" : "#059669")

    function modeTitle(mode) {
        switch (mode) {
        case "silent": return qsTr("Silent");
        case "balanced": return qsTr("Balanced");
        case "performance": return qsTr("Performance");
        case "manual": return qsTr("Manual");
        case "custom": return qsTr("Custom");
        case "auto":
        default: return qsTr("Auto");
        }
    }

    function modeDescription(mode) {
        switch (mode) {
        case "silent":
            return qsTr("Acoustic priority profile. Maintains low fan speeds and delays ramp-up for quiet operation.");
        case "balanced":
            return qsTr("Optimized profile dynamically balancing thermal dissipation and acoustic comfort.");
        case "performance":
            return qsTr("Aggressive cooling profile providing maximum sustained airflow for heavy workloads.");
        case "manual":
            return qsTr("Fixed fan speed percentage defined directly by the user slider.");
        case "custom":
            return qsTr("Interpolated multi-point temperature-to-speed fan curve.");
        case "auto":
        default:
            return qsTr("Default automatic profile managed natively by hardware VBIOS and kernel drivers.");
        }
    }

    function refreshAll() {
        if (page.refreshAnimating)
            return;
        page.refreshAnimating = true;
        if (page.fanController) {
            page.fanController.start();
            page.fanController.refresh();
        }
        if (page.gpuMonitor)
            page.gpuMonitor.refresh();
        if (page.cpuMonitor)
            page.cpuMonitor.refresh();
        refreshPulse.restart();
    }

    Timer {
        id: refreshPulse
        interval: 400
        repeat: false
        onTriggered: page.refreshAnimating = false
    }

    ScrollView {
        id: pageScroll
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: pageScroll.availableWidth
            spacing: Math.round(14 * page.uiScale)

            // Header Banner
            Rectangle {
                Layout.fillWidth: true
                radius: 14
                color: page.cardColor
                border.width: 1
                border.color: page.borderColor
                implicitHeight: headerRow.implicitHeight + 20

                RowLayout {
                    id: headerRow
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: qsTr("Cooling & Fan Management")
                            color: page.textColor
                            font.pixelSize: Math.round(18 * page.uiScale)
                            font.weight: Font.DemiBold
                        }

                        Label {
                            text: qsTr("Hardware-aware telemetry, cooling profiles, and multi-fan controls across the system.")
                            color: page.softTextColor
                            font.pixelSize: Math.round(12 * page.uiScale)
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                    }

                    // Compact Power Source badge in header
                    Rectangle {
                        visible: page.systemInfo !== null && page.systemInfo.powerSource && page.systemInfo.powerSource.length > 0
                        implicitHeight: Math.round(32 * page.uiScale)
                        implicitWidth: powerBadgeLayout.implicitWidth + Math.round(20 * page.uiScale)
                        radius: 8
                        color: (page.systemInfo && page.systemInfo.onBattery) ? page.warningBg : page.bgColor
                        border.width: 1
                        border.color: (page.systemInfo && page.systemInfo.onBattery) ? page.warningText : page.borderColor

                        RowLayout {
                            id: powerBadgeLayout
                            anchors.centerIn: parent
                            spacing: 6

                            Label {
                                text: (page.systemInfo && page.systemInfo.onBattery) ? "🔋" : "⚡"
                                font.pixelSize: Math.round(12 * page.uiScale)
                            }

                            Label {
                                text: page.systemInfo ? page.systemInfo.powerSource : ""
                                color: (page.systemInfo && page.systemInfo.onBattery) ? page.warningText : page.textColor
                                font.pixelSize: Math.round(12 * page.uiScale)
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    Components.RefreshToolButton {
                        busy: page.refreshAnimating
                        theme: page.theme
                        darkMode: page.darkMode
                        uiScale: page.uiScale
                        tooltip: qsTr("Refresh fan telemetry")
                        enabled: !page.refreshAnimating
                        onClicked: page.refreshAll()
                    }
                }
            }

            // System Fans Overview Grid
            Rectangle {
                Layout.fillWidth: true
                radius: 14
                color: page.cardColor
                border.width: 1
                border.color: page.borderColor
                implicitHeight: fansSectionLayout.implicitHeight + 24

                ColumnLayout {
                    id: fansSectionLayout
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Detected System Fans (%1)").arg(page.fanController ? page.fanController.systemFanCount : 0)
                            color: page.textColor
                            font.pixelSize: Math.round(15 * page.uiScale)
                            font.weight: Font.DemiBold
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width > 1100 ? 3 : (width > 680 ? 2 : 1)
                        columnSpacing: 10
                        rowSpacing: 10

                        Repeater {
                            model: page.fanController ? page.fanController.systemFans : []

                            delegate: Rectangle {
                                id: fanCard
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                implicitHeight: Math.round(144 * page.uiScale)
                                radius: 10
                                color: (page.fanController && page.fanController.selectedFanIndex === fanCard.index)
                                       ? (page.darkMode ? "#383152" : "#E0E7FF")
                                       : page.bgColor
                                border.width: (page.fanController && page.fanController.selectedFanIndex === fanCard.index) ? 2 : 1
                                border.color: (page.fanController && page.fanController.selectedFanIndex === fanCard.index) ? page.accentColor : page.borderColor

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (page.fanController)
                                            page.fanController.selectFan(fanCard.index);
                                        fanSettingsPopup.openForFan(fanCard.modelData);
                                    }
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Rectangle {
                                            implicitWidth: Math.round(44 * page.uiScale)
                                            implicitHeight: Math.round(22 * page.uiScale)
                                            radius: 4
                                            color: page.darkMode ? "#4A3E6D" : "#E2E8F0"

                                            Label {
                                                anchors.centerIn: parent
                                                text: fanCard.modelData.type || "SYS"
                                                color: page.textColor
                                                font.pixelSize: Math.round(10 * page.uiScale)
                                                font.weight: Font.DemiBold
                                            }
                                        }

                                        Label {
                                            text: fanCard.modelData.name || qsTr("Fan Device")
                                            color: page.textColor
                                            font.pixelSize: Math.round(13 * page.uiScale)
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 16

                                        ColumnLayout {
                                            spacing: 1

                                            Label {
                                                text: qsTr("Speed")
                                                color: page.softTextColor
                                                font.pixelSize: Math.round(10 * page.uiScale)
                                            }

                                            Label {
                                                text: (fanCard.modelData.speedPercent !== undefined ? fanCard.modelData.speedPercent : 0) + "%"
                                                color: page.textColor
                                                font.pixelSize: Math.round(15 * page.uiScale)
                                                font.weight: Font.DemiBold
                                            }
                                        }

                                        ColumnLayout {
                                            spacing: 1

                                            Label {
                                                text: qsTr("RPM")
                                                color: page.softTextColor
                                                font.pixelSize: Math.round(10 * page.uiScale)
                                            }

                                            Label {
                                                text: {
                                                    if (!fanCard.modelData)
                                                        return qsTr("--");
                                                    if (fanCard.modelData.rpm > 0)
                                                        return fanCard.modelData.rpm + " RPM";
                                                    return qsTr("0 RPM");
                                                }
                                                color: (fanCard.modelData && fanCard.modelData.rpm > 0) ? page.textColor : page.accentColor
                                                font.pixelSize: Math.round(13 * page.uiScale)
                                                font.weight: Font.Medium
                                            }
                                        }

                                        ColumnLayout {
                                            spacing: 1
                                            Layout.fillWidth: true

                                            Label {
                                                text: qsTr("Temperature")
                                                color: page.softTextColor
                                                font.pixelSize: Math.round(10 * page.uiScale)
                                            }

                                            Label {
                                                text: fanCard.modelData.temperatureC > 0 ? (fanCard.modelData.temperatureC + " °C") : qsTr("--")
                                                color: page.textColor
                                                font.pixelSize: Math.round(13 * page.uiScale)
                                                font.weight: Font.Medium
                                            }
                                        }
                                    }

                                    ProgressBar {
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 100
                                        value: fanCard.modelData.speedPercent || 0
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Fan Control & Profile Settings Section
            Rectangle {
                Layout.fillWidth: true
                radius: 14
                color: page.cardColor
                border.width: 1
                border.color: page.borderColor
                implicitHeight: profileSectionLayout.implicitHeight + 28

                ColumnLayout {
                    id: profileSectionLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: qsTr("Optimization Profiles & Control")
                            color: page.textColor
                            font.pixelSize: Math.round(16 * page.uiScale)
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            implicitWidth: statusBadgeText.implicitWidth + 18
                            implicitHeight: Math.round(28 * page.uiScale)
                            radius: 6
                            color: page.fanController && page.fanController.controlSupported ? page.successBg : page.infoBg
                            border.width: 1
                            border.color: page.fanController && page.fanController.controlSupported ? page.successText : (page.darkMode ? "#4D5B9E" : "#93C5FD")

                            Label {
                                id: statusBadgeText
                                anchors.centerIn: parent
                                text: {
                                    if (page.fanController && page.fanController.controlSupported)
                                        return qsTr("ACTIVE: %1").arg(page.fanController.fanMode.toUpperCase());
                                    return qsTr("MANAGED: %1").arg(page.fanController ? page.fanController.fanMode.toUpperCase() : "AUTO");
                                }
                                color: page.fanController && page.fanController.controlSupported ? page.successText : page.accentColor
                                font.pixelSize: Math.round(11 * page.uiScale)
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    // Profile Selector Buttons with Proportional Centered Widgets
                    GridLayout {
                        Layout.fillWidth: true
                        columns: width > 840 ? 6 : (width > 560 ? 3 : 2)
                        columnSpacing: 10
                        rowSpacing: 10

                        Repeater {
                            model: [
                                { mode: "auto", label: qsTr("Auto"), desc: qsTr("Default") },
                                { mode: "silent", label: qsTr("Silent"), desc: qsTr("Quiet") },
                                { mode: "balanced", label: qsTr("Balanced"), desc: qsTr("Optimized") },
                                { mode: "performance", label: qsTr("Performance"), desc: qsTr("Cooling") },
                                { mode: "manual", label: qsTr("Manual"), desc: qsTr("Fixed") },
                                { mode: "custom", label: qsTr("Custom"), desc: qsTr("Curve") }
                            ]

                            delegate: Button {
                                id: modeBtn
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: Math.round(58 * page.uiScale)

                                background: Rectangle {
                                    radius: 8
                                    color: (page.fanController && page.fanController.fanMode === modeBtn.modelData.mode)
                                           ? page.accentColor
                                           : page.bgColor
                                    border.width: (page.fanController && page.fanController.fanMode === modeBtn.modelData.mode) ? 2 : 1
                                    border.color: (page.fanController && page.fanController.fanMode === modeBtn.modelData.mode)
                                                  ? page.accentColor
                                                  : page.borderColor
                                }

                                contentItem: Column {
                                    anchors.centerIn: parent
                                    spacing: 3

                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modeBtn.modelData.label
                                        color: (page.fanController && page.fanController.fanMode === modeBtn.modelData.mode)
                                               ? page.accentButtonText
                                               : page.textColor
                                        font.pixelSize: Math.round(13 * page.uiScale)
                                        font.weight: (page.fanController && page.fanController.fanMode === modeBtn.modelData.mode) ? Font.Bold : Font.DemiBold
                                    }

                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modeBtn.modelData.desc
                                        color: (page.fanController && page.fanController.fanMode === modeBtn.modelData.mode)
                                               ? page.accentButtonText
                                               : page.softTextColor
                                        font.pixelSize: Math.round(10 * page.uiScale)
                                    }
                                }

                                onClicked: {
                                    if (page.fanController)
                                        page.fanController.setFanMode(modeBtn.modelData.mode);
                                }
                            }
                        }
                    }

                    // Profile Description
                    Label {
                        Layout.fillWidth: true
                        text: page.modeDescription(page.fanController ? page.fanController.fanMode : "auto")
                        color: page.softTextColor
                        font.pixelSize: Math.round(12 * page.uiScale)
                        wrapMode: Text.Wrap
                    }

                    // Battery Profile Sync Toggle
                    Rectangle {
                        Layout.fillWidth: true
                        radius: 8
                        color: page.bgColor
                        border.width: 1
                        border.color: page.borderColor
                        implicitHeight: batterySyncRow.implicitHeight + 16
                        visible: page.fanController !== null

                        RowLayout {
                            id: batterySyncRow
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: qsTr("Battery Profile Sync")
                                    color: page.textColor
                                    font.pixelSize: Math.round(13 * page.uiScale)
                                    font.weight: Font.DemiBold
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: qsTr("Automatically switch to Auto mode when running on battery to preserve energy.")
                                    color: page.softTextColor
                                    font.pixelSize: Math.round(11 * page.uiScale)
                                    wrapMode: Text.Wrap
                                }
                            }

                            Switch {
                                id: batterySyncSwitch
                                checked: page.fanController ? page.fanController.batteryProfileSyncEnabled : false
                                onToggled: {
                                    if (page.fanController)
                                        page.fanController.batteryProfileSyncEnabled = checked;
                                }
                            }
                        }
                    }

                    // Manual Speed Slider (when Manual mode selected)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: page.fanController && page.fanController.fanMode === "manual"

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                text: qsTr("Target Manual Speed")
                                color: page.textColor
                                font.pixelSize: Math.round(13 * page.uiScale)
                                font.weight: Font.DemiBold
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                text: Math.round(manualSlider.value) + "%"
                                color: page.textColor
                                font.pixelSize: Math.round(14 * page.uiScale)
                                font.weight: Font.DemiBold
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
                                if (page.fanController)
                                    page.fanController.setManualFanSpeedPercent(Math.round(value));
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: qsTr("Presets:")
                                color: page.softTextColor
                                font.pixelSize: Math.round(11 * page.uiScale)
                            }

                            Repeater {
                                model: [30, 50, 75, 100]

                                delegate: Button {
                                    id: presetBtn
                                    required property int modelData
                                    text: presetBtn.modelData + "%"
                                    implicitHeight: Math.round(28 * page.uiScale)

                                    background: Rectangle {
                                        radius: 6
                                        color: Math.round(manualSlider.value) === presetBtn.modelData ? page.accentColor : page.bgColor
                                        border.width: 1
                                        border.color: page.borderColor
                                    }

                                    contentItem: Text {
                                        text: presetBtn.text
                                        color: Math.round(manualSlider.value) === presetBtn.modelData ? page.accentButtonText : page.textColor
                                        font.pixelSize: Math.round(11 * page.uiScale)
                                        font.weight: Font.Medium
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    onClicked: {
                                        manualSlider.value = presetBtn.modelData;
                                        if (page.fanController)
                                            page.fanController.setManualFanSpeedPercent(presetBtn.modelData);
                                    }
                                }
                            }
                        }
                    }

                    // Custom Fan Curve Editor (when Custom mode selected)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: page.fanController && page.fanController.fanMode === "custom"

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                text: qsTr("Custom Temperature-Speed Curve")
                                color: page.textColor
                                font.pixelSize: Math.round(13 * page.uiScale)
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                            }

                            Button {
                                text: qsTr("Reset to Default Curve")
                                onClicked: {
                                    if (page.fanController)
                                        page.fanController.resetCustomCurve();
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
                                    id: curvePtCard
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    implicitHeight: Math.round(84 * page.uiScale)
                                    radius: 8
                                    color: page.bgColor
                                    border.width: 1
                                    border.color: page.borderColor

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 4

                                        Label {
                                            text: qsTr("Point %1: %2 °C").arg(curvePtCard.index + 1).arg(curvePtCard.modelData.temp || 0)
                                            color: page.textColor
                                            font.pixelSize: Math.round(12 * page.uiScale)
                                            font.weight: Font.DemiBold
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Slider {
                                                id: ptSlider
                                                Layout.fillWidth: true
                                                from: 0
                                                to: 100
                                                stepSize: 5
                                                value: curvePtCard.modelData.speed || 0
                                                onMoved: {
                                                    if (page.fanController)
                                                        page.fanController.setCustomCurvePoint(curvePtCard.index, curvePtCard.modelData.temp, Math.round(value));
                                                }
                                            }

                                            Label {
                                                text: Math.round(ptSlider.value) + "%"
                                                color: page.textColor
                                                font.pixelSize: Math.round(11 * page.uiScale)
                                                font.weight: Font.DemiBold
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Components.FanSettingsPopup {
        id: fanSettingsPopup
        fanController: page.fanController
        theme: page.theme
        darkMode: page.darkMode
        uiScale: page.uiScale
    }

    Component.onCompleted: {
        if (page.fanController) {
            page.fanController.start();
            page.fanController.refresh();
        }
    }
}
