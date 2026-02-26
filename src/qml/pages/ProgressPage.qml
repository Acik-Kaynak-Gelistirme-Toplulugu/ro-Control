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

    readonly property color cSurface:  darkMode ? "#242b35" : "#ffffff"
    readonly property color cBorder:   darkMode ? "#313840" : "#d0d7de"
    readonly property color cText:     darkMode ? "#e6edf3" : "#1f2328"
    readonly property color cTextSub:  darkMode ? "#8b949e" : "#656d76"
    readonly property color cTextMuted:darkMode ? "#6e7681" : "#8c959f"

    Controls.ScrollView {
        anchors.fill: parent

        ColumnLayout {
            width: Math.min(parent.width - 48, 640)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0

            Item { Layout.preferredHeight: 32 }

            // ── Title ──
            Controls.Label {
                text: page.controller.current_status === "removing"
                    ? qsTr("Removing Drivers\u2026")
                    : qsTr("Installing nvidia-%1").arg(page.controller.best_version)
                font.pixelSize: 20; font.weight: Font.DemiBold; color: page.cText
            }

            Item { Layout.preferredHeight: 16 }

            // ── Progress Bar ──
            RowLayout {
                Layout.fillWidth: true; spacing: 12

                Controls.ProgressBar {
                    Layout.fillWidth: true
                    from: 0; to: 100
                    value: page.controller.install_progress
                    indeterminate: page.controller.install_progress === 0 && page.controller.is_installing

                    background: Rectangle {
                        implicitHeight: 8; radius: 4
                        color: darkMode ? "#1b2028" : "#e8ebef"
                    }

                    contentItem: Item {
                        implicitHeight: 8
                        Rectangle {
                            width: page.controller.install_progress / 100.0 * parent.width
                            height: parent.height; radius: 4; color: "#3daee9"
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                Controls.Label {
                    text: page.controller.install_progress + "%"
                    font.pixelSize: 16; font.weight: Font.DemiBold
                    color: page.cTextSub
                    Layout.preferredWidth: 48
                    horizontalAlignment: Text.AlignRight
                }
            }

            Item { Layout.preferredHeight: 16 }

            // ── Installation Steps ──
            Rectangle {
                visible: page.controller.is_installing
                Layout.fillWidth: true
                implicitHeight: stepsCol.implicitHeight + 24
                radius: 10; color: page.cSurface
                border.width: 1; border.color: page.cBorder

                ColumnLayout {
                    id: stepsCol
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter; anchors.margins: 16
                    spacing: 6

                    StepItem {
                        text: qsTr("Checking compatibility")
                        status: page.controller.install_progress >= 10 ? "done" : "pending"
                        darkMode: page.darkMode
                    }
                    StepItem {
                        text: qsTr("Downloading packages")
                        status: page.controller.install_progress >= 30 ? "done" : page.controller.install_progress >= 10 ? "running" : "pending"
                        darkMode: page.darkMode
                    }
                    StepItem {
                        text: qsTr("Installing drivers")
                        status: page.controller.install_progress >= 60 ? "done" : page.controller.install_progress >= 30 ? "running" : "pending"
                        darkMode: page.darkMode
                    }
                    StepItem {
                        text: qsTr("Building kernel module")
                        status: page.controller.install_progress >= 80 ? "done" : page.controller.install_progress >= 60 ? "running" : "pending"
                        darkMode: page.darkMode
                    }
                    StepItem {
                        text: qsTr("Running dracut")
                        status: page.controller.install_progress >= 100 ? "done" : page.controller.install_progress >= 80 ? "running" : "pending"
                        darkMode: page.darkMode
                    }
                }
            }

            Item { Layout.preferredHeight: 12 }

            // ── Log Output ──
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                radius: 10
                color: darkMode ? "#161b22" : "#f6f8fa"
                border.width: 1; border.color: page.cBorder

                ColumnLayout {
                    anchors.fill: parent; spacing: 0

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 32
                        color: darkMode ? "#1e252e" : "#eef1f5"
                        radius: 10

                        // Clip bottom corners
                        Rectangle {
                            anchors.bottom: parent.bottom; width: parent.width; height: 10
                            color: parent.color
                        }

                        Controls.Label {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: 12
                            text: qsTr("Log Output")
                            font.pixelSize: 12; font.weight: Font.DemiBold
                            color: page.cTextSub
                        }
                    }

                    Controls.ScrollView {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true

                        Controls.TextArea {
                            id: logArea
                            readOnly: true; wrapMode: Text.WordWrap
                            text: page.controller.install_log || qsTr("Waiting for output\u2026")
                            font.family: "monospace"; font.pixelSize: 12
                            color: page.cTextMuted
                            background: null
                            leftPadding: 12; rightPadding: 12; topPadding: 8

                            onTextChanged: logArea.cursorPosition = logArea.text.length
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 12 }

            // ── Warning ──
            WarningBanner {
                visible: page.controller.is_installing
                type: "warning"
                text: qsTr("Do not turn off your computer during this process.")
                darkMode: page.darkMode
                Layout.fillWidth: true
            }

            Item { Layout.preferredHeight: 16 }

            // ── Action Buttons ──
            RowLayout {
                Layout.fillWidth: true; spacing: 10

                Controls.Button {
                    visible: page.controller.is_installing
                    text: qsTr("Cancel")
                    font.pixelSize: 14
                    Layout.preferredWidth: 120
                    onClicked: cancelDialog.open()

                    background: Rectangle {
                        implicitHeight: 38; radius: 10
                        color: parent.down ? (darkMode ? "#2c3440" : "#dde0e4") : (darkMode ? "#313840" : "#e8ebef")
                        border.width: 1; border.color: page.cBorder
                    }
                }

                Controls.Button {
                    visible: !page.controller.is_installing
                    text: qsTr("Done")
                    Layout.fillWidth: true; font.pixelSize: 14

                    contentItem: Controls.Label {
                        text: parent.text; font: parent.font; color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        implicitHeight: 38; radius: 10
                        color: parent.down ? "#2a8ec4" : "#3daee9"
                    }

                    onClicked: page.finished()
                }

                Controls.Button {
                    visible: !page.controller.is_installing && page.controller.install_progress >= 100
                    text: qsTr("Reboot Now")
                    icon.name: "system-reboot"
                    Layout.fillWidth: true; font.pixelSize: 14

                    contentItem: RowLayout {
                        spacing: 6
                        Controls.Label {
                            text: "\u27F3"; font.pixelSize: 16; color: "#ffffff"
                        }
                        Controls.Label {
                            text: qsTr("Reboot Now"); font.pixelSize: 14; color: "#ffffff"
                        }
                    }
                    background: Rectangle {
                        implicitHeight: 38; radius: 10
                        color: parent.down ? "#2a8ec4" : "#3daee9"
                    }

                    onClicked: {
                        console.log("Reboot requested by user");
                        page.controller.reboot_system();
                    }
                }
            }

            Item { Layout.preferredHeight: 24 }
        }
    }

    Controls.Dialog {
        id: cancelDialog
        title: qsTr("Cancel Installation?")
        modal: true; anchors.centerIn: parent
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No

        Controls.Label {
            text: qsTr("Cancelling may leave your system in an incomplete state.\nAre you sure?")
            wrapMode: Text.WordWrap
        }

        onAccepted: {
            console.warn("Installation cancelled by user");
            page.finished();
        }
    }
}
