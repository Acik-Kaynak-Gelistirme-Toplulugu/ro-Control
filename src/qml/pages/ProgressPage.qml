pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import "../components"
import io.github.AcikKaynakGelistirmeToplulugu.rocontrol

Item {
    id: page

    required property var controller
    required property bool darkMode
    signal finished

    readonly property color cCard:    darkMode ? "#1e293b" : "#fcfcfc"
    readonly property color cBorder:  darkMode ? "#334155" : "#e5e7eb"
    readonly property color cFg:      darkMode ? "#e2e8f0" : "#1a1d23"
    readonly property color cMutedFg: darkMode ? "#94a3b8" : "#64748b"
    readonly property color cPrimary: darkMode ? "#60a5fa" : "#3b82f6"
    readonly property color cAccent:  darkMode ? "#a78bfa" : "#8b5cf6"
    readonly property color cMuted:   darkMode ? "#1e293b" : "#f1f5f9"
    readonly property color cWarning: darkMode ? "#fbbf24" : "#f59e0b"
    readonly property color cError:   darkMode ? "#f87171" : "#ef4444"

    readonly property var steps: [
        { step: qsTr("Checking compatibility..."),  threshold: 10 },
        { step: qsTr("Downloading packages..."),    threshold: 30 },
        { step: qsTr("Installing akmod-nvidia..."), threshold: 60 },
        { step: qsTr("Building kernel module..."),  threshold: 85 },
        { step: qsTr("Running dracut..."),          threshold: 100 }
    ]

    function getStepStatus(index) {
        var prog = page.controller.install_progress;
        var thr = steps[index].threshold;
        var prev = index > 0 ? steps[index - 1].threshold : 0;
        if (prog >= thr) return "done";
        if (prog > prev) return "running";
        return "pending";
    }

    Controls.ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width; spacing: 24

            Item { Layout.preferredHeight: 24 }

            // ── Hero ──
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter; spacing: 20

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 96; height: 96; radius: 20
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: page.cPrimary }
                        GradientStop { position: 1.0; color: page.cAccent }
                    }
                    Controls.Label { anchors.centerIn: parent; text: "🛡️"; font.pixelSize: 48 }

                    RotationAnimator on rotation { running: page.controller.is_installing; from: 0; to: 360; duration: 3000; loops: Animation.Infinite }
                    SequentialAnimation on scale {
                        running: page.controller.is_installing; loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 1.05; duration: 1000 }
                        NumberAnimation { from: 1.05; to: 1.0; duration: 1000 }
                    }
                }

                Controls.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: page.controller.current_status === "removing"
                        ? qsTr("Removing Drivers…") : qsTr("Installing nvidia-%1").arg(page.controller.best_version)
                    font.pixelSize: 24; font.weight: Font.Bold; color: page.cFg
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter; spacing: 8
                    Controls.Label { text: qsTr("This may take a few minutes •"); font.pixelSize: 16; color: page.cMutedFg }
                    Controls.Label { text: "Rust Edition"; font.pixelSize: 16; font.weight: Font.Bold; color: page.cPrimary }
                }
            }

            // ── Progress Bar ──
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter; Layout.maximumWidth: 720; Layout.fillWidth: true; spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    Controls.Label { text: qsTr("Progress"); font.pixelSize: 14; font.weight: Font.Medium; color: page.cMutedFg }
                    Item { Layout.fillWidth: true }
                    Controls.Label { text: page.controller.install_progress + "%"; font.pixelSize: 24; font.weight: Font.Bold; color: page.cPrimary; font.family: "monospace" }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 16; radius: 8; color: page.cMuted

                    Rectangle {
                        width: parent.width * Math.min(100, Math.max(0, page.controller.install_progress)) / 100
                        height: parent.height; radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#EF4444" }
                            GradientStop { position: 0.5; color: "#DC2626" }
                            GradientStop { position: 1.0; color: "#EF4444" }
                        }
                        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

                        Rectangle {
                            anchors.fill: parent; radius: parent.radius
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(1,1,1,0.3) }
                                GradientStop { position: 0.5; color: Qt.rgba(1,1,1,0.1) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }
                        Rectangle {
                            anchors.fill: parent; radius: parent.radius; opacity: 0.4
                            gradient: Gradient {
                                GradientStop { position: _shimmer.pos - 0.3; color: "transparent" }
                                GradientStop { position: _shimmer.pos;       color: "white" }
                                GradientStop { position: _shimmer.pos + 0.3; color: "transparent" }
                                orientation: Gradient.Horizontal
                            }
                            QtObject { id: _shimmer; property real pos: -0.3 }
                            SequentialAnimation on _shimmer.pos {
                                running: page.controller.is_installing; loops: Animation.Infinite
                                NumberAnimation { from: -0.3; to: 1.3; duration: 1500 }
                            }
                        }
                        Controls.Label {
                            visible: page.controller.is_installing; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            text: "●"; font.pixelSize: 14; color: "white"
                            SequentialAnimation on opacity {
                                running: page.controller.is_installing; loops: Animation.Infinite
                                NumberAnimation { from: 1; to: 0.3; duration: 750 }
                                NumberAnimation { from: 0.3; to: 1; duration: 750 }
                            }
                        }
                    }
                }
            }

            // ── Installation Log ──
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter; Layout.maximumWidth: 720; Layout.fillWidth: true; spacing: 16

                Controls.Label { text: "⚙️ " + qsTr("Installation Log"); font.pixelSize: 18; font.weight: Font.Bold; color: page.cFg }

                Rectangle {
                    Layout.fillWidth: true; implicitHeight: Math.min(320, _stepsCol.implicitHeight + 40)
                    radius: 16; color: page.cCard; border.width: 1; border.color: page.cBorder; clip: true

                    ColumnLayout {
                        id: _stepsCol; anchors.fill: parent; anchors.margins: 20; spacing: 12

                        Repeater {
                            model: page.steps
                            delegate: StepItem {
                                Layout.fillWidth: true
                                status: page.getStepStatus(index)
                                label: modelData.step
                                darkMode: page.darkMode
                                required property int index
                                required property var modelData
                            }
                        }
                    }
                }
            }

            // ── Log Output ──
            Rectangle {
                Layout.alignment: Qt.AlignHCenter; Layout.maximumWidth: 720; Layout.fillWidth: true
                Layout.preferredHeight: 200; radius: 16
                color: darkMode ? "#161b22" : "#f6f8fa"
                border.width: 1; border.color: page.cBorder

                ColumnLayout {
                    anchors.fill: parent; spacing: 0

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 34
                        color: darkMode ? "#1e252e" : "#eef1f5"; radius: 16
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 12; color: parent.color }
                        Controls.Label {
                            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 14
                            text: "📋 " + qsTr("Log Output"); font.pixelSize: 12; font.weight: Font.DemiBold; color: page.cMutedFg
                        }
                    }

                    Controls.ScrollView {
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        Controls.TextArea {
                            id: _logArea; readOnly: true; wrapMode: Text.WordWrap
                            text: page.controller.install_log || qsTr("Waiting for output…")
                            font.family: "monospace"; font.pixelSize: 12; color: page.cMutedFg
                            background: null; leftPadding: 14; rightPadding: 14; topPadding: 8
                            onTextChanged: _logArea.cursorPosition = _logArea.text.length
                        }
                    }
                }
            }

            // ── Warning ──
            Rectangle {
                visible: page.controller.is_installing
                Layout.alignment: Qt.AlignHCenter; Layout.maximumWidth: 720; Layout.fillWidth: true
                implicitHeight: _warnRow.implicitHeight + 40; radius: 16
                color: Qt.rgba(page.cWarning.r, page.cWarning.g, page.cWarning.b, 0.1)
                border.width: 1; border.color: Qt.rgba(page.cWarning.r, page.cWarning.g, page.cWarning.b, 0.3)

                RowLayout {
                    id: _warnRow; anchors.fill: parent; anchors.margins: 20; spacing: 16
                    Rectangle {
                        Layout.preferredWidth: 40; Layout.preferredHeight: 40; Layout.alignment: Qt.AlignTop
                        radius: 12; color: Qt.rgba(page.cWarning.r, page.cWarning.g, page.cWarning.b, 0.2)
                        Controls.Label { anchors.centerIn: parent; text: "⚠️"; font.pixelSize: 20 }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 8
                        Controls.Label { text: qsTr("Important Notice"); font.pixelSize: 16; font.weight: Font.Bold; color: page.cWarning }
                        Controls.Label { text: qsTr("Do not turn off your computer or close this window during installation."); font.pixelSize: 14; color: page.cMutedFg; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    }
                }
            }

            // ── Buttons ──
            RowLayout {
                Layout.alignment: Qt.AlignHCenter; Layout.maximumWidth: 720; Layout.fillWidth: true; spacing: 16

                Controls.Button {
                    visible: page.controller.is_installing
                    text: "❌ " + qsTr("Cancel Installation"); implicitWidth: 200; implicitHeight: 48
                    background: Rectangle {
                        radius: 16; color: "transparent"; border.width: 2
                        border.color: parent.hovered ? page.cError : page.cBorder
                        Behavior on border.color { ColorAnimation { duration: 300 } }
                    }
                    contentItem: Controls.Label {
                        text: parent.text; font.pixelSize: 16; font.weight: Font.Medium
                        color: parent.hovered ? page.cError : page.cFg
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                    onClicked: _cancelDialog.open()
                }

                GradientButton {
                    visible: !page.controller.is_installing && page.controller.install_progress >= 100
                    text: qsTr("Reboot Now"); Layout.fillWidth: true
                    useGradient: true; gradientStart: page.cWarning; gradientEnd: Qt.darker(page.cWarning, 1.2)
                    darkMode: page.darkMode
                    onClicked: page.controller.reboot_system()
                }

                GradientButton {
                    visible: !page.controller.is_installing
                    text: qsTr("Done"); Layout.fillWidth: true
                    useGradient: true; gradientStart: page.cPrimary; gradientEnd: page.cAccent
                    darkMode: page.darkMode
                    onClicked: page.finished()
                }
            }

            Item { Layout.preferredHeight: 24 }
        }
    }

    Controls.Dialog {
        id: _cancelDialog; title: qsTr("Cancel Installation?"); modal: true; anchors.centerIn: parent
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        Controls.Label { text: qsTr("Cancelling may leave your system in an incomplete state.\nAre you sure?"); wrapMode: Text.WordWrap }
        onAccepted: page.finished()
    }
}
