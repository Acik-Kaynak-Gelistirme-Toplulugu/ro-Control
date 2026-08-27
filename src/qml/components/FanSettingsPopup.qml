import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: popup
    required property var fanController
    property var theme: ({})
    property bool darkMode: false
    property real uiScale: 1.0

    property var currentFan: null
    property string activeMode: "auto"
    property int activeManualSpeed: 50
    property int activeThermalThreshold: 85
    property var activeCurvePoints: []
    property bool saveFeedbackVisible: false

    readonly property color bgColor: theme && theme.card ? theme.card : (popup.darkMode ? "#29233B" : "#FFFFFF")
    readonly property color cardColor: theme && theme.cardStrong ? theme.cardStrong : (popup.darkMode ? "#342D4A" : "#F1F5F9")
    readonly property color borderColor: theme && theme.border ? theme.border : (popup.darkMode ? "#4D436B" : "#CBD5E1")
    readonly property color textColor: theme && theme.text ? theme.text : (popup.darkMode ? "#F8FAFC" : "#0F172A")
    readonly property color softTextColor: theme && theme.textSoft ? theme.textSoft : (popup.darkMode ? "#94A3B8" : "#64748B")
    readonly property color accentColor: theme && theme.accentA ? theme.accentA : (popup.darkMode ? "#818CF8" : "#4F46E5")
    readonly property color accentButtonText: "#FFFFFF"
    readonly property color infoBg: theme && theme.infoBg ? theme.infoBg : (popup.darkMode ? "#1E2548" : "#EFF6FF")
    readonly property color warningBg: theme && theme.warningBg ? theme.warningBg : (popup.darkMode ? "#3A2E12" : "#FFFBEB")
    readonly property color warningText: theme && theme.warning ? theme.warning : (popup.darkMode ? "#FBBF24" : "#D97706")
    readonly property color successBg: theme && theme.successBg ? theme.successBg : (popup.darkMode ? "#143828" : "#ECFDF5")
    readonly property color successText: theme && theme.success ? theme.success : (popup.darkMode ? "#4ADE80" : "#059669")

    modal: true
    focus: true
    dim: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    anchors.centerIn: Overlay.overlay

    width: Math.min(Overlay.overlay ? Overlay.overlay.width - 32 : 720, Math.round(720 * popup.uiScale))
    implicitHeight: Math.min(Overlay.overlay ? Overlay.overlay.height - 48 : 820, popupScroll.implicitHeight + 40)

    function openForFan(fanData) {
        if (!fanData)
            return;
        currentFan = fanData;
        activeMode = fanData.mode || "auto";
        activeManualSpeed = fanData.manualSpeedPercent !== undefined ? fanData.manualSpeedPercent : (fanData.speedPercent || 50);
        activeThermalThreshold = fanData.thermalThresholdC || 85;
        
        var pts = [];
        if (fanData.customCurvePoints && fanData.customCurvePoints.length > 0) {
            for (var i = 0; i < fanData.customCurvePoints.length; ++i) {
                pts.push({
                    temp: fanData.customCurvePoints[i].temp || (40 + i * 15),
                    speed: fanData.customCurvePoints[i].speed || (30 + i * 20)
                });
            }
        } else {
            pts = [
                { temp: 40, speed: 30 },
                { temp: 55, speed: 50 },
                { temp: 70, speed: 70 },
                { temp: 85, speed: 100 }
            ];
        }
        activeCurvePoints = pts;
        saveFeedbackVisible = false;
        popup.open();
    }

    function syncLiveFanData() {
        if (!popup.opened || !currentFan || !popup.fanController)
            return;
        var list = popup.fanController.systemFans;
        for (var i = 0; i < list.length; ++i) {
            if (list[i].id === currentFan.id) {
                currentFan = list[i];
                break;
            }
        }
    }

    Connections {
        target: popup.fanController
        function onSystemFansChanged() {
            popup.syncLiveFanData();
        }
        function onCurrentFanSpeedPercentChanged() {
            popup.syncLiveFanData();
        }
        function onCurrentRpmChanged() {
            popup.syncLiveFanData();
        }
    }

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
            return qsTr("Acoustic priority profile. Minimizes fan noise and delays speed ramp-up for quiet operation.");
        case "balanced":
            return qsTr("Dynamically balances thermal dissipation and acoustic comfort based on workload.");
        case "performance":
            return qsTr("Aggressive cooling profile providing maximum sustained airflow for heavy loads.");
        case "manual":
            return qsTr("Locked fixed fan speed percentage set directly by the manual slider.");
        case "custom":
            return qsTr("Multi-point custom temperature-to-speed fan curve with smooth interpolation.");
        case "auto":
        default:
            return qsTr("Automatic cooling curve managed natively by hardware VBIOS / BIOS thermal controllers.");
        }
    }

    function applyAllSettings() {
        if (!currentFan || !popup.fanController)
            return;
        var fanId = currentFan.id;
        popup.fanController.setFanModeForFan(fanId, activeMode);
        popup.fanController.setManualSpeedForFan(fanId, activeManualSpeed);
        popup.fanController.setThermalThresholdForFan(fanId, activeThermalThreshold);
        
        for (var i = 0; i < activeCurvePoints.length; ++i) {
            popup.fanController.setCustomCurvePointForFan(fanId, i, activeCurvePoints[i].temp, activeCurvePoints[i].speed);
        }

        popup.fanController.applyFanConfiguration(fanId);
        saveFeedbackVisible = true;
        feedbackTimer.restart();
    }

    function resetToAutoMode() {
        if (!currentFan || !popup.fanController)
            return;
        activeMode = "auto";
        popup.fanController.resetFanToAuto(currentFan.id);
        saveFeedbackVisible = true;
        feedbackTimer.restart();
    }

    Timer {
        id: feedbackTimer
        interval: 2200
        repeat: false
        onTriggered: popup.saveFeedbackVisible = false
    }

    background: Rectangle {
        radius: 16
        color: popup.bgColor
        border.width: 1
        border.color: popup.borderColor
    }

    contentItem: Item {
        implicitWidth: popup.width - 24
        implicitHeight: Math.min(popupScroll.implicitHeight + 20, Overlay.overlay ? Overlay.overlay.height - 60 : 780)

        ScrollView {
            id: popupScroll
            anchors.fill: parent
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                width: popupScroll.availableWidth
                spacing: Math.round(14 * popup.uiScale)

                // Header Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        implicitWidth: Math.round(44 * popup.uiScale)
                        implicitHeight: Math.round(26 * popup.uiScale)
                        radius: 6
                        color: popup.darkMode ? "#4A3E6D" : "#E2E8F0"

                        Label {
                            anchors.centerIn: parent
                            text: popup.currentFan ? (popup.currentFan.type || "SYS") : "FAN"
                            color: popup.textColor
                            font.pixelSize: Math.round(11 * popup.uiScale)
                            font.weight: Font.Bold
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Label {
                            text: popup.currentFan ? popup.currentFan.name : qsTr("Fan Settings")
                            color: popup.textColor
                            font.pixelSize: Math.round(17 * popup.uiScale)
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Label {
                            text: popup.currentFan ? (qsTr("Device Identifier: %1").arg(popup.currentFan.id)) : ""
                            color: popup.softTextColor
                            font.pixelSize: Math.round(11 * popup.uiScale)
                        }
                    }

                    Button {
                        implicitWidth: Math.round(32 * popup.uiScale)
                        implicitHeight: Math.round(32 * popup.uiScale)
                        background: Rectangle {
                            radius: 16
                            color: parent.hovered ? (popup.darkMode ? "#4A3E6D" : "#E2E8F0") : "transparent"
                        }
                        contentItem: Text {
                            text: "✕"
                            color: popup.softTextColor
                            font.pixelSize: Math.round(14 * popup.uiScale)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: popup.close()
                    }
                }

                // Live Status Overview Card
                Rectangle {
                    Layout.fillWidth: true
                    radius: 12
                    color: popup.cardColor
                    border.width: 1
                    border.color: popup.borderColor
                    implicitHeight: liveMetricsRow.implicitHeight + 22

                    RowLayout {
                        id: liveMetricsRow
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 14

                        // Speed Metric
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: qsTr("Live Speed")
                                color: popup.softTextColor
                                font.pixelSize: Math.round(11 * popup.uiScale)
                            }

                            RowLayout {
                                spacing: 4
                                Label {
                                    text: (popup.currentFan && popup.currentFan.speedPercent !== undefined ? popup.currentFan.speedPercent : 0) + "%"
                                    color: popup.textColor
                                    font.pixelSize: Math.round(18 * popup.uiScale)
                                    font.weight: Font.Bold
                                }
                            }

                            ProgressBar {
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                value: popup.currentFan ? (popup.currentFan.speedPercent || 0) : 0
                            }
                        }

                        Rectangle {
                            implicitWidth: 1
                            Layout.fillHeight: true
                            color: popup.borderColor
                        }

                        // RPM Metric
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: qsTr("Live RPM")
                                color: popup.softTextColor
                                font.pixelSize: Math.round(11 * popup.uiScale)
                            }

                            Label {
                                text: {
                                    if (!popup.currentFan)
                                        return qsTr("--");
                                    if (popup.currentFan.rpm > 0)
                                        return popup.currentFan.rpm + " RPM";
                                    return qsTr("0 RPM");
                                }
                                color: (popup.currentFan && popup.currentFan.rpm > 0) ? popup.textColor : popup.accentColor
                                font.pixelSize: Math.round(15 * popup.uiScale)
                                font.weight: Font.DemiBold
                            }

                            Label {
                                text: (popup.currentFan && (popup.currentFan.isZeroRpm || popup.currentFan.rpm === 0))
                                      ? qsTr("0 RPM Silent Mode")
                                      : qsTr("Active Cooling Airflow")
                                color: popup.softTextColor
                                font.pixelSize: Math.round(10 * popup.uiScale)
                            }
                        }

                        Rectangle {
                            implicitWidth: 1
                            Layout.fillHeight: true
                            color: popup.borderColor
                        }

                        // Temperature Metric
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: qsTr("Temperature")
                                color: popup.softTextColor
                                font.pixelSize: Math.round(11 * popup.uiScale)
                            }

                            Label {
                                text: (popup.currentFan && popup.currentFan.temperatureC > 0)
                                      ? (popup.currentFan.temperatureC + " °C")
                                      : qsTr("--")
                                color: {
                                    var t = popup.currentFan ? popup.currentFan.temperatureC : 0;
                                    if (t >= 80) return popup.warningText;
                                    return popup.textColor;
                                }
                                font.pixelSize: Math.round(16 * popup.uiScale)
                                font.weight: Font.DemiBold
                            }

                            Label {
                                text: {
                                    var t = popup.currentFan ? popup.currentFan.temperatureC : 0;
                                    if (t >= 80) return qsTr("High Load");
                                    if (t >= 60) return qsTr("Moderate");
                                    return qsTr("Cool / Normal");
                                }
                                color: popup.softTextColor
                                font.pixelSize: Math.round(10 * popup.uiScale)
                            }
                        }
                    }
                }

                // Profile Selector for this specific fan
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: qsTr("Optimization Profile")
                        color: popup.textColor
                        font.pixelSize: Math.round(14 * popup.uiScale)
                        font.weight: Font.DemiBold
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width > 520 ? 6 : (width > 340 ? 3 : 2)
                        columnSpacing: 8
                        rowSpacing: 8

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
                                implicitHeight: Math.round(52 * popup.uiScale)

                                background: Rectangle {
                                    radius: 8
                                    color: popup.activeMode === modeBtn.modelData.mode ? popup.accentColor : popup.cardColor
                                    border.width: popup.activeMode === modeBtn.modelData.mode ? 2 : 1
                                    border.color: popup.activeMode === modeBtn.modelData.mode ? popup.accentColor : popup.borderColor
                                }

                                contentItem: Column {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modeBtn.modelData.label
                                        color: popup.activeMode === modeBtn.modelData.mode ? popup.accentButtonText : popup.textColor
                                        font.pixelSize: Math.round(12 * popup.uiScale)
                                        font.weight: popup.activeMode === modeBtn.modelData.mode ? Font.Bold : Font.DemiBold
                                    }

                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modeBtn.modelData.desc
                                        color: popup.activeMode === modeBtn.modelData.mode ? popup.accentButtonText : popup.softTextColor
                                        font.pixelSize: Math.round(9 * popup.uiScale)
                                    }
                                }

                                onClicked: popup.activeMode = modeBtn.modelData.mode
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: popup.modeDescription(popup.activeMode)
                        color: popup.softTextColor
                        font.pixelSize: Math.round(11 * popup.uiScale)
                        wrapMode: Text.Wrap
                    }
                }

                // Dynamic Adjustment Area (Manual vs Custom vs Curves)
                Rectangle {
                    Layout.fillWidth: true
                    radius: 10
                    color: popup.cardColor
                    border.width: 1
                    border.color: popup.borderColor
                    implicitHeight: configAreaLayout.implicitHeight + 20

                    ColumnLayout {
                        id: configAreaLayout
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        // Manual Slider View
                        ColumnLayout {
                            visible: popup.activeMode === "manual"
                            Layout.fillWidth: true
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true

                                Label {
                                    text: qsTr("Manual Fixed Fan Speed")
                                    color: popup.textColor
                                    font.pixelSize: Math.round(13 * popup.uiScale)
                                    font.weight: Font.DemiBold
                                }

                                Item { Layout.fillWidth: true }

                                Label {
                                    text: popup.activeManualSpeed + "%"
                                    color: popup.accentColor
                                    font.pixelSize: Math.round(15 * popup.uiScale)
                                    font.weight: Font.Bold
                                }
                            }

                            Slider {
                                id: manualPopupSlider
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                stepSize: 1
                                value: popup.activeManualSpeed
                                onMoved: popup.activeManualSpeed = Math.round(value)
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Label {
                                    text: qsTr("Quick Presets:")
                                    color: popup.softTextColor
                                    font.pixelSize: Math.round(11 * popup.uiScale)
                                }

                                Repeater {
                                    model: [30, 50, 75, 100]

                                    delegate: Button {
                                        required property int modelData
                                        text: modelData + "%"
                                        implicitHeight: Math.round(26 * popup.uiScale)

                                        background: Rectangle {
                                            radius: 6
                                            color: popup.activeManualSpeed === modelData ? popup.accentColor : popup.bgColor
                                            border.width: 1
                                            border.color: popup.borderColor
                                        }

                                        contentItem: Text {
                                            text: parent.text
                                            color: popup.activeManualSpeed === modelData ? popup.accentButtonText : popup.textColor
                                            font.pixelSize: Math.round(10 * popup.uiScale)
                                            font.weight: Font.Medium
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        onClicked: {
                                            popup.activeManualSpeed = modelData;
                                            manualPopupSlider.value = modelData;
                                        }
                                    }
                                }
                            }
                        }

                        // Custom Curve View
                        ColumnLayout {
                            visible: popup.activeMode === "custom"
                            Layout.fillWidth: true
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true

                                Label {
                                    text: qsTr("Custom Temperature Curve Points")
                                    color: popup.textColor
                                    font.pixelSize: Math.round(13 * popup.uiScale)
                                    font.weight: Font.DemiBold
                                    Layout.fillWidth: true
                                }

                                Button {
                                    text: qsTr("Reset Curve")
                                    implicitHeight: Math.round(26 * popup.uiScale)
                                    onClicked: {
                                        popup.activeCurvePoints = [
                                            { temp: 40, speed: 30 },
                                            { temp: 55, speed: 50 },
                                            { temp: 70, speed: 70 },
                                            { temp: 85, speed: 100 }
                                        ];
                                    }
                                }
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: width > 500 ? 4 : 2
                                columnSpacing: 8
                                rowSpacing: 8

                                Repeater {
                                    model: popup.activeCurvePoints

                                    delegate: Rectangle {
                                        id: curvePtBox
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        implicitHeight: Math.round(76 * popup.uiScale)
                                        radius: 6
                                        color: popup.bgColor
                                        border.width: 1
                                        border.color: popup.borderColor

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 2

                                            Label {
                                                text: qsTr("Point %1: %2 °C").arg(curvePtBox.index + 1).arg(curvePtBox.modelData.temp)
                                                color: popup.textColor
                                                font.pixelSize: Math.round(11 * popup.uiScale)
                                                font.weight: Font.DemiBold
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 4

                                                Slider {
                                                    Layout.fillWidth: true
                                                    from: 0
                                                    to: 100
                                                    stepSize: 5
                                                    value: curvePtBox.modelData.speed
                                                    onMoved: {
                                                        var pts = popup.activeCurvePoints.slice();
                                                        pts[curvePtBox.index].speed = Math.round(value);
                                                        popup.activeCurvePoints = pts;
                                                    }
                                                }

                                                Label {
                                                    text: curvePtBox.modelData.speed + "%"
                                                    color: popup.textColor
                                                    font.pixelSize: Math.round(10 * popup.uiScale)
                                                    font.weight: Font.Bold
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Presets View (Auto / Silent / Balanced / Performance)
                        ColumnLayout {
                            visible: popup.activeMode !== "manual" && popup.activeMode !== "custom"
                            Layout.fillWidth: true
                            spacing: 4

                            Label {
                                text: qsTr("Profile Cooling Behavior")
                                color: popup.textColor
                                font.pixelSize: Math.round(12 * popup.uiScale)
                                font.weight: Font.DemiBold
                            }

                            Label {
                                text: {
                                    if (popup.activeMode === "silent")
                                        return qsTr("Fans stay at 0% RPM under 45°C, ramping up smoothly to 50% at 68°C and 100% at 85°C.");
                                    if (popup.activeMode === "performance")
                                        return qsTr("Active cooling floor at 45% speed, aggressively ramping to 80% at 65°C and 100% at 82°C.");
                                    if (popup.activeMode === "balanced")
                                        return qsTr("Standard curve: 30% baseline cooling, smoothly ramping to 65% at 68°C and 100% at 85°C.");
                                    return qsTr("Native automatic curve dynamically controlled by hardware thermals and firmware.");
                                }
                                color: popup.softTextColor
                                font.pixelSize: Math.round(11 * popup.uiScale)
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                        }

                        // Thermal Emergency Safety Guard
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true

                                Label {
                                    text: qsTr("Emergency 100% Thermal Guard")
                                    color: popup.textColor
                                    font.pixelSize: Math.round(12 * popup.uiScale)
                                    font.weight: Font.DemiBold
                                }

                                Item { Layout.fillWidth: true }

                                Label {
                                    text: popup.activeThermalThreshold + " °C"
                                    color: popup.warningText
                                    font.pixelSize: Math.round(13 * popup.uiScale)
                                    font.weight: Font.Bold
                                }
                            }

                            Slider {
                                Layout.fillWidth: true
                                from: 65
                                to: 100
                                stepSize: 1
                                value: popup.activeThermalThreshold
                                onMoved: popup.activeThermalThreshold = Math.round(value)
                            }
                        }
                    }
                }

                // Success / Feedback Banner
                Rectangle {
                    visible: popup.saveFeedbackVisible
                    Layout.fillWidth: true
                    radius: 8
                    color: popup.successBg
                    border.width: 1
                    border.color: popup.successText
                    implicitHeight: 36

                    Label {
                        anchors.centerIn: parent
                        text: qsTr("✓ Fan configuration applied and saved successfully!")
                        color: popup.successText
                        font.pixelSize: Math.round(12 * popup.uiScale)
                        font.weight: Font.DemiBold
                    }
                }

                // Action Buttons Footer
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Button {
                        text: qsTr("Reset to Auto")
                        implicitHeight: Math.round(38 * popup.uiScale)
                        onClicked: popup.resetToAutoMode()
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: qsTr("Close")
                        implicitHeight: Math.round(38 * popup.uiScale)
                        onClicked: popup.close()
                    }

                    Button {
                        text: qsTr("Apply & Save Settings")
                        implicitHeight: Math.round(38 * popup.uiScale)

                        background: Rectangle {
                            radius: 8
                            color: popup.accentColor
                        }

                        contentItem: Text {
                            text: parent.text
                            color: popup.accentButtonText
                            font.pixelSize: Math.round(12 * popup.uiScale)
                            font.weight: Font.Bold
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: popup.applyAllSettings()
                    }
                }
            }
        }
    }
}
