pragma ComponentBehavior: Bound
// qmllint disable unqualified
// qmllint disable unresolved-type
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import "../components"
import io.github.AcikKaynakGelistirmeToplulugu.rocontrol

Item {
    id: page

    required property var controller
    signal finished

    readonly property var steps: [
        {
            step: qsTr("Checking compatibility..."),
            threshold: 10
        },
        {
            step: qsTr("Downloading packages..."),
            threshold: 30
        },
        {
            step: qsTr("Installing akmod-nvidia..."),
            threshold: 60
        },
        {
            step: qsTr("Building kernel module..."),
            threshold: 85
        },
        {
            step: qsTr("Running dracut..."),
            threshold: 100
        }
    ]

    function getStepStatus(index) {
        var prog = page.controller.install_progress;
        var thr = steps[index].threshold;
        var prev = index > 0 ? steps[index - 1].threshold : 0;
        if (prog >= thr)
            return "done";
        if (prog > prev)
            return "running";
        return "pending";
    }

    Controls.ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: 24

            Item {
                Layout.preferredHeight: 24
            }

            // ── Hero ──
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 96
                    implicitHeight: 96
                    radius: 20
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: Theme.primary
                        }
                        GradientStop {
                            position: 1.0
                            color: Theme.accent
                        }
                    }
                    Controls.Label {
                        anchors.centerIn: parent
                        text: "🛡️"
                        font.pixelSize: 48
                    }

                    RotationAnimator on rotation {
                        running: page.controller.is_installing
                        from: 0
                        to: 360
                        duration: 3000
                        loops: Animation.Infinite
                    }
                    SequentialAnimation on scale {
                        running: page.controller.is_installing
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: 1.0
                            to: 1.05
                            duration: 1000
                        }
                        NumberAnimation {
                            from: 1.05
                            to: 1.0
                            duration: 1000
                        }
                    }
                }

                Controls.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: page.controller.current_status === "removing" ? qsTr("Removing Drivers…") : qsTr("Installing nvidia-%1").arg(page.controller.best_version)
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    color: Theme.foreground
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    Controls.Label {
                        text: qsTr("This may take a few minutes •")
                        font.pixelSize: 16
                        color: Theme.mutedForeground
                    }
                    Controls.Label {
                        text: "Rust Edition"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Theme.primary
                    }
                }
            }

            // ── Progress Bar ──
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720
                Layout.fillWidth: true
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    Controls.Label {
                        text: qsTr("Progress")
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: Theme.mutedForeground
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Controls.Label {
                        text: page.controller.install_progress + "%"
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        color: Theme.primary
                        font.family: "monospace"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    radius: 8
                    color: Theme.muted

                    Rectangle {
                        width: parent.width * Math.min(100, Math.max(0, page.controller.install_progress)) / 100
                        height: parent.height
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: Theme.primary
                            }
                            GradientStop {
                                position: 0.5
                                color: Theme.accent
                            }
                            GradientStop {
                                position: 1.0
                                color: Theme.primary
                            }
                        }
                        Behavior on width {
                            NumberAnimation {
                                duration: 500
                                easing.type: Easing.OutCubic
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: Qt.rgba(1, 1, 1, 0.3)
                                }
                                GradientStop {
                                    position: 0.5
                                    color: Qt.rgba(1, 1, 1, 0.1)
                                }
                                GradientStop {
                                    position: 1.0
                                    color: "transparent"
                                }
                            }
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            opacity: 0.4
                            gradient: Gradient {
                                GradientStop {
                                    position: _shimmer.pos - 0.3
                                    color: "transparent"
                                }
                                GradientStop {
                                    position: _shimmer.pos
                                    color: "white"
                                }
                                GradientStop {
                                    position: _shimmer.pos + 0.3
                                    color: "transparent"
                                }
                                orientation: Gradient.Horizontal
                            }
                            QtObject {
                                id: _shimmer
                                property real pos: -0.3
                            }
                            SequentialAnimation on _shimmer.pos {
                                running: page.controller.is_installing
                                loops: Animation.Infinite
                                NumberAnimation {
                                    from: -0.3
                                    to: 1.3
                                    duration: 1500
                                }
                            }
                        }
                        Controls.Label {
                            visible: page.controller.is_installing
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "●"
                            font.pixelSize: 14
                            color: "white"
                            SequentialAnimation on opacity {
                                running: page.controller.is_installing
                                loops: Animation.Infinite
                                NumberAnimation {
                                    from: 1
                                    to: 0.3
                                    duration: 750
                                }
                                NumberAnimation {
                                    from: 0.3
                                    to: 1
                                    duration: 750
                                }
                            }
                        }
                    }
                }
            }

            // ── Installation Log ──
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720
                Layout.fillWidth: true
                spacing: 16

                Controls.Label {
                    text: "⚙️ " + qsTr("Installation Log")
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: Theme.foreground
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.min(320, _stepsCol.implicitHeight + 40)
                    radius: 16
                    color: Theme.card
                    border.width: 1
                    border.color: Theme.border
                    clip: true

                    ColumnLayout {
                        id: _stepsCol
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 12

                        Repeater {
                            model: page.steps
                            delegate: StepItem {
                                Layout.fillWidth: true
                                status: page.getStepStatus(index)
                                label: modelData.step
                                required property int index
                                required property var modelData
                            }
                        }
                    }
                }
            }

            // ── Log Output ──
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                radius: 16
                color: Theme.isDark ? Qt.darker(Theme.card, 1.3) : Qt.lighter(Theme.card, 1.05)
                border.width: 1
                border.color: Theme.border

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        color: Theme.isDark ? Qt.darker(Theme.card, 1.1) : Qt.lighter(Theme.muted, 1.02)
                        radius: 16
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 12
                            color: parent.color
                        }
                        Controls.Label {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            text: "📋 " + qsTr("Log Output")
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Theme.mutedForeground
                        }
                    }

                    Controls.ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        Controls.TextArea {
                            id: _logArea
                            readOnly: true
                            wrapMode: Text.WordWrap
                            text: page.controller.install_log || qsTr("Waiting for output…")
                            font.family: "monospace"
                            font.pixelSize: 12
                            color: Theme.mutedForeground
                            background: null
                            leftPadding: 14
                            rightPadding: 14
                            topPadding: 8
                            onTextChanged: _logArea.cursorPosition = _logArea.text.length
                        }
                    }
                }
            }

            // ── Warning ──
            Rectangle {
                visible: page.controller.is_installing
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720
                Layout.fillWidth: true
                implicitHeight: _warnRow.implicitHeight + 40
                radius: 16
                color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.1)
                border.width: 1
                border.color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.3)

                RowLayout {
                    id: _warnRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16
                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignTop
                        radius: 12
                        color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.2)
                        Controls.Label {
                            anchors.centerIn: parent
                            text: "⚠️"
                            font.pixelSize: 20
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Controls.Label {
                            text: qsTr("Important Notice")
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            color: Theme.warning
                        }
                        Controls.Label {
                            text: qsTr("Do not turn off your computer or close this window during installation.")
                            font.pixelSize: 14
                            color: Theme.mutedForeground
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // ── Buttons ──
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720
                Layout.fillWidth: true
                spacing: 16

                Controls.Button {
                    id: cancelBtn
                    visible: page.controller.is_installing
                    text: "❌ " + qsTr("Cancel Installation")
                    implicitWidth: 200
                    implicitHeight: 48
                    background: Rectangle {
                        radius: 16
                        color: "transparent"
                        border.width: 2
                        border.color: cancelBtn.hovered ? Theme.error : Theme.border
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 300
                            }
                        }
                    }
                    contentItem: Controls.Label {
                        text: cancelBtn.text
                        font.pixelSize: 16
                        font.weight: Font.Medium
                        color: cancelBtn.hovered ? Theme.error : Theme.foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        Behavior on color {
                            ColorAnimation {
                                duration: 300
                            }
                        }
                    }
                    onClicked: _cancelDialog.open()
                }

                GradientButton {
                    visible: !page.controller.is_installing && page.controller.install_progress >= 100
                    text: qsTr("Reboot Now")
                    Layout.fillWidth: true
                    useGradient: true
                    gradientStart: Theme.warning
                    gradientEnd: Qt.darker(Theme.warning, 1.2)
                    onClicked: page.controller.reboot_system()
                }

                GradientButton {
                    visible: !page.controller.is_installing
                    text: qsTr("Done")
                    Layout.fillWidth: true
                    useGradient: true
                    gradientStart: Theme.primary
                    gradientEnd: Theme.accent
                    onClicked: page.finished()
                }
            }

            Item {
                Layout.preferredHeight: 24
            }
        }
    }

    Controls.Dialog {
        id: _cancelDialog
        title: qsTr("Cancel Installation?")
        modal: true
        anchors.centerIn: parent
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        Controls.Label {
            text: qsTr("The installation process cannot be interrupted safely.\nThis will navigate away, but the operation may continue in the background.\nAre you sure?")
            wrapMode: Text.WordWrap
        }
        onAccepted: page.finished()
    }
}
