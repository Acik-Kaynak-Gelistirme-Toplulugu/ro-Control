import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: popup
    required property var fanController
    property var theme: ({})
    property bool darkMode: false
    property real uiScale: 1.0

    // Step 1: "confirm", Step 2: "scanning", Step 3: "done"
    property string step: "confirm"
    property int scanProgress: 0
    property string currentPhaseText: qsTr("Initializing Hardware Probe...")
    property bool phase1Done: false
    property bool phase2Done: false
    property bool phase3Done: false

    readonly property color bgColor: theme && theme.card ? theme.card : (popup.darkMode ? "#241E34" : "#FFFFFF")
    readonly property color cardColor: theme && theme.cardStrong ? theme.cardStrong : (popup.darkMode ? "#2E2742" : "#F8FAFC")
    readonly property color borderColor: theme && theme.border ? theme.border : (popup.darkMode ? "#43385E" : "#E2E8F0")
    readonly property color textColor: theme && theme.text ? theme.text : (popup.darkMode ? "#F8FAFC" : "#0F172A")
    readonly property color softTextColor: theme && theme.textSoft ? theme.textSoft : (popup.darkMode ? "#94A3B8" : "#64748B")
    readonly property color accentColor: theme && theme.accentA ? theme.accentA : (popup.darkMode ? "#818CF8" : "#4F46E5")
    readonly property color accentButtonText: "#FFFFFF"
    readonly property color successBg: theme && theme.successBg ? theme.successBg : (popup.darkMode ? "#143828" : "#ECFDF5")
    readonly property color successText: theme && theme.success ? theme.success : (popup.darkMode ? "#4ADE80" : "#059669")

    modal: true
    focus: true
    closePolicy: (step === "scanning") ? Popup.NoAutoClose : (Popup.CloseOnEscape | Popup.CloseOnPressOutside)
    width: Math.min(parent ? parent.width - 40 : 540, Math.round(540 * popup.uiScale))
    x: Math.round(((parent ? parent.width : 600) - width) / 2)
    y: Math.max(20, Math.round(((parent ? parent.height : 600) - implicitHeight) / 2))
    padding: Math.round(16 * popup.uiScale)

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.94; to: 1.0; duration: 200; easing.type: Easing.OutBack }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.96; duration: 150 }
        }
    }

    function openWizard() {
        step = "confirm";
        scanProgress = 0;
        phase1Done = false;
        phase2Done = false;
        phase3Done = false;
        currentPhaseText = qsTr("Initializing Hardware Probe...");
        popup.open();
    }

    function startScanProcess() {
        step = "scanning";
        scanProgress = 15;
        currentPhaseText = qsTr("Probing Linux HWMON & ACPI kernel thermal controllers...");
        phase1Timer.start();
    }

    Timer {
        id: phase1Timer
        interval: 600
        repeat: false
        onTriggered: {
            popup.phase1Done = true;
            popup.scanProgress = 55;
            popup.currentPhaseText = qsTr("Querying NVIDIA NV-CONTROL & GPU fan tachometers...");
            phase2Timer.start();
        }
    }

    Timer {
        id: phase2Timer
        interval: 700
        repeat: false
        onTriggered: {
            popup.phase2Done = true;
            popup.scanProgress = 85;
            popup.currentPhaseText = qsTr("Calibrating zero-RPM thresholds & refreshing telemetry...");
            if (popup.fanController) {
                popup.fanController.refresh();
            }
            phase3Timer.start();
        }
    }

    Timer {
        id: phase3Timer
        interval: 500
        repeat: false
        onTriggered: {
            popup.phase3Done = true;
            popup.scanProgress = 100;
            popup.step = "done";
        }
    }

    background: Rectangle {
        radius: 16
        color: popup.bgColor
        border.width: 1
        border.color: popup.borderColor
    }

    contentItem: ColumnLayout {
        id: contentColumn
        spacing: Math.round(14 * popup.uiScale)

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                implicitWidth: Math.round(36 * popup.uiScale)
                implicitHeight: Math.round(36 * popup.uiScale)
                radius: Math.round(18 * popup.uiScale)
                color: popup.step === "done" ? popup.successBg : (popup.darkMode ? "#3B3156" : "#EEF2FF")
                border.width: 1
                border.color: popup.step === "done" ? popup.successText : popup.accentColor

                Label {
                    anchors.centerIn: parent
                    text: popup.step === "done" ? "✓" : (popup.step === "scanning" ? "• • •" : "WIZ")
                    color: popup.step === "done" ? popup.successText : popup.accentColor
                    font.pixelSize: Math.round(11 * popup.uiScale)
                    font.weight: Font.Bold
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: popup.step === "confirm"
                          ? qsTr("Fan Setup & Discovery Wizard")
                          : (popup.step === "scanning"
                             ? qsTr("Scanning Thermal & Fan Controllers...")
                             : qsTr("Hardware Discovery Complete"))
                    color: popup.textColor
                    font.pixelSize: Math.round(16 * popup.uiScale)
                    font.weight: Font.DemiBold
                }

                Label {
                    text: popup.step === "confirm"
                          ? qsTr("Enumerate cooling fans, calibrate PWM headers, and sync sensor registers")
                          : (popup.step === "scanning"
                             ? qsTr("Please wait while hardware sensors are probed...")
                             : qsTr("All system cooling devices have been synchronized"))
                    color: popup.softTextColor
                    font.pixelSize: Math.round(11 * popup.uiScale)
                }
            }

            ToolButton {
                id: closeBtn
                visible: popup.step !== "scanning"
                Layout.alignment: Qt.AlignTop | Qt.AlignRight
                implicitWidth: Math.round(32 * popup.uiScale)
                implicitHeight: Math.round(32 * popup.uiScale)
                hoverEnabled: true

                background: Rectangle {
                    radius: Math.round(16 * popup.uiScale)
                    color: closeBtn.hovered ? (popup.darkMode ? "#3B3156" : "#E2E8F0") : "transparent"
                }

                contentItem: Text {
                    text: "✕"
                    color: closeBtn.hovered ? popup.textColor : popup.softTextColor
                    font.pixelSize: Math.round(15 * popup.uiScale)
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                ToolTip {
                    visible: closeBtn.hovered
                    text: qsTr("Close")
                    delay: 400
                }

                onClicked: popup.close()
            }
        }

        // STEP 1: Confirmation View
        ColumnLayout {
            visible: popup.step === "confirm"
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                radius: 10
                color: popup.cardColor
                border.width: 1
                border.color: popup.borderColor
                implicitHeight: confirmInfoLayout.implicitHeight + 24

                ColumnLayout {
                    id: confirmInfoLayout
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Label {
                        text: qsTr("What will this hardware setup wizard do?")
                        color: popup.textColor
                        font.pixelSize: Math.round(13 * popup.uiScale)
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: qsTr("• Scans kernel thermal zones (/sys/class/thermal) and Linux HWMON sensor chips.\n• Probes NVIDIA NV-CONTROL driver registers for dedicated GPU fans.\n• Detects newly connected PWM chassis coolers and GPU fans.\n• Recalibrates RPM tachometers, zero-dB points, and baseline curves.")
                        color: popup.softTextColor
                        font.pixelSize: Math.round(12 * popup.uiScale)
                        lineHeight: 1.4
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                Button {
                    id: cancelBtn
                    text: qsTr("Cancel")
                    implicitHeight: Math.round(36 * popup.uiScale)
                    hoverEnabled: true

                    background: Rectangle {
                        radius: 8
                        color: cancelBtn.down ? (popup.darkMode ? "#3B3156" : "#E2E8F0")
                                              : (cancelBtn.hovered ? (popup.darkMode ? "#342D4A" : "#F1F5F9")
                                                                   : popup.cardColor)
                        border.width: 1
                        border.color: cancelBtn.hovered ? popup.accentColor : popup.borderColor
                    }

                    contentItem: Text {
                        text: cancelBtn.text
                        color: cancelBtn.hovered ? popup.accentColor : popup.textColor
                        font.pixelSize: Math.round(12 * popup.uiScale)
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: popup.close()
                }

                Button {
                    id: startScanBtn
                    text: qsTr("Run Setup Wizard")
                    implicitHeight: Math.round(36 * popup.uiScale)
                    hoverEnabled: true

                    background: Rectangle {
                        radius: 8
                        color: startScanBtn.down ? (popup.darkMode ? "#4F46E5" : "#3730A3")
                                                 : (startScanBtn.hovered ? (popup.darkMode ? "#939BFA" : "#5B52E8")
                                                                         : popup.accentColor)
                    }

                    contentItem: Text {
                        text: startScanBtn.text
                        color: popup.accentButtonText
                        font.pixelSize: Math.round(12 * popup.uiScale)
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: popup.startScanProcess()
                }
            }
        }

        // STEP 2: Scanning & Progress View with Pulsing Animation
        ColumnLayout {
            visible: popup.step === "scanning"
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                radius: 10
                color: popup.cardColor
                border.width: 1
                border.color: popup.borderColor
                implicitHeight: scanningLayout.implicitHeight + 24

                ColumnLayout {
                    id: scanningLayout
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: popup.currentPhaseText
                            color: popup.textColor
                            font.pixelSize: Math.round(13 * popup.uiScale)
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Label {
                            text: popup.scanProgress + "%"
                            color: popup.accentColor
                            font.pixelSize: Math.round(13 * popup.uiScale)
                            font.weight: Font.Bold
                        }
                    }

                    // Progress Bar Capsule
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.round(8 * popup.uiScale)
                        radius: 4
                        color: popup.darkMode ? "#1E2238" : "#E2E8F0"
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * (popup.scanProgress / 100.0)
                            radius: 4
                            color: popup.accentColor

                            Behavior on width {
                                NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                            }
                        }
                    }

                    // Phase Checklist
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            spacing: 8
                            Label {
                                text: popup.phase1Done ? "✓" : "⏳"
                                color: popup.phase1Done ? popup.successText : popup.softTextColor
                                font.weight: Font.Bold
                            }
                            Label {
                                text: qsTr("Linux HWMON & ACPI Controllers")
                                color: popup.phase1Done ? popup.textColor : popup.softTextColor
                                font.pixelSize: Math.round(12 * popup.uiScale)
                                font.weight: popup.phase1Done ? Font.DemiBold : Font.Normal
                            }
                        }

                        RowLayout {
                            spacing: 8
                            Label {
                                text: popup.phase2Done ? "✓" : (popup.phase1Done ? "⏳" : "•")
                                color: popup.phase2Done ? popup.successText : popup.softTextColor
                                font.weight: Font.Bold
                            }
                            Label {
                                text: qsTr("NVIDIA GPU NV-CONTROL Interfaces")
                                color: popup.phase2Done ? popup.textColor : popup.softTextColor
                                font.pixelSize: Math.round(12 * popup.uiScale)
                                font.weight: popup.phase2Done ? Font.DemiBold : Font.Normal
                            }
                        }

                        RowLayout {
                            spacing: 8
                            Label {
                                text: popup.phase3Done ? "✓" : (popup.phase2Done ? "⏳" : "•")
                                color: popup.phase3Done ? popup.successText : popup.softTextColor
                                font.weight: Font.Bold
                            }
                            Label {
                                text: qsTr("Telemetry Calibration & Sensor Sync")
                                color: popup.phase3Done ? popup.textColor : popup.softTextColor
                                font.pixelSize: Math.round(12 * popup.uiScale)
                                font.weight: popup.phase3Done ? Font.DemiBold : Font.Normal
                            }
                        }
                    }
                }
            }
        }

        // STEP 3: Done & Discovery Results View
        ColumnLayout {
            visible: popup.step === "done"
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                radius: 10
                color: popup.successBg
                border.width: 1
                border.color: popup.successText
                implicitHeight: doneLayout.implicitHeight + 24

                ColumnLayout {
                    id: doneLayout
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    RowLayout {
                        spacing: 8
                        Label {
                            text: "✓"
                            color: popup.successText
                            font.pixelSize: Math.round(16 * popup.uiScale)
                            font.weight: Font.Bold
                        }
                        Label {
                            text: qsTr("Hardware Scan Successfully Completed!")
                            color: popup.successText
                            font.pixelSize: Math.round(14 * popup.uiScale)
                            font.weight: Font.Bold
                        }
                    }

                    Label {
                        text: qsTr("%1 Active cooling fan device(s) synchronized and ready for curve tuning.")
                              .arg(popup.fanController ? popup.fanController.systemFanCount : 0)
                        color: popup.textColor
                        font.pixelSize: Math.round(12 * popup.uiScale)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                Button {
                    id: finishBtn
                    text: qsTr("Done")
                    implicitHeight: Math.round(36 * popup.uiScale)
                    hoverEnabled: true

                    background: Rectangle {
                        radius: 8
                        color: finishBtn.down ? (popup.darkMode ? "#4F46E5" : "#3730A3")
                                              : (finishBtn.hovered ? (popup.darkMode ? "#939BFA" : "#5B52E8")
                                                                   : popup.accentColor)
                    }

                    contentItem: Text {
                        text: finishBtn.text
                        color: popup.accentButtonText
                        font.pixelSize: Math.round(12 * popup.uiScale)
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: popup.close()
                }
            }
        }
    }
}
