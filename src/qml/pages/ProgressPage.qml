import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import io.github.AcikKaynakGelistirmeToplulugu.rocontrol

// Progress Page — Real-time installation/removal progress
// Shows step-by-step process with status icons

Item {
    id: progressPage

    required property var controller
    signal finished()

    Controls.ScrollView {
        anchors.fill: parent

        ColumnLayout {
            width: Math.min(parent.width, 560)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Item { Layout.preferredHeight: 40 }

            // ─── Title ───
            Controls.Label {
                text: controller.current_status === "removing"
                    ? qsTr("Removing Drivers...")
                    : qsTr("Installing nvidia-%1").arg(controller.best_version)
                font.pixelSize: 20
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            // ─── Progress Bar ───
            Controls.ProgressBar {
                Layout.fillWidth: true
                from: 0
                to: 100
                value: controller.install_progress
                indeterminate: controller.install_progress === 0 && controller.is_installing
            }

            Controls.Label {
                text: controller.install_progress + " %"
                Layout.alignment: Qt.AlignHCenter
                opacity: 0.6
            }

            // ─── Installation Steps ───
            Controls.GroupBox {
                visible: controller.is_installing
                Layout.fillWidth: true
                title: qsTr("Installation Steps")

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4

                    StepItem {
                        text: qsTr("Checking compatibility")
                        status: controller.install_progress >= 10 ? "done" : "pending"
                    }

                    StepItem {
                        text: qsTr("Downloading packages")
                        status: controller.install_progress >= 30 ? "done" : 
                               controller.install_progress >= 10 ? "running" : "pending"
                    }

                    StepItem {
                        text: qsTr("Installing drivers")
                        status: controller.install_progress >= 60 ? "done" : 
                               controller.install_progress >= 30 ? "running" : "pending"
                    }

                    StepItem {
                        text: qsTr("Building kernel module")
                        status: controller.install_progress >= 80 ? "done" : 
                               controller.install_progress >= 60 ? "running" : "pending"
                    }

                    StepItem {
                        text: qsTr("Running dracut")
                        status: controller.install_progress >= 100 ? "done" : 
                               controller.install_progress >= 80 ? "running" : "pending"
                    }
                }
            }

            // ─── Log Output ───
            Controls.GroupBox {
                Layout.fillWidth: true
                Layout.preferredHeight: 240
                title: qsTr("Log")

                Controls.ScrollView {
                    anchors.fill: parent

                    Controls.TextArea {
                        id: logArea
                        readOnly: true
                        text: controller.install_log
                        font.family: "monospace"
                        font.pixelSize: 12
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true

                        // Auto-scroll to bottom
                        onTextChanged: {
                            logArea.cursorPosition = logArea.length
                        }
                    }
                }
            }

            // ─── Warning ───
            Controls.Label {
                visible: controller.is_installing
                text: "⚠ " + qsTr("Do not turn off your computer during this process")
                opacity: 0.7
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 12
            }

            // ─── Buttons ───
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Controls.Button {
                    visible: controller.is_installing
                    text: qsTr("Cancel")
                    Layout.fillWidth: true
                    onClicked: cancelDialog.open()
                }

                Controls.Button {
                    visible: !controller.is_installing
                    text: qsTr("Done")
                    highlighted: true
                    Layout.fillWidth: true
                    onClicked: progressPage.finished()
                }

                Controls.Button {
                    visible: !controller.is_installing && controller.install_progress >= 100
                    text: qsTr("Reboot Now")
                    icon.name: "system-reboot"
                    highlighted: true
                    Layout.fillWidth: true
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }

    // ─── Cancel Confirmation Dialog ───
    Controls.Dialog {
        id: cancelDialog
        title: qsTr("Cancel Installation?")
        modal: true
        anchors.centerIn: parent
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No

        Controls.Label {
            text: qsTr("Cancelling may leave your system in an incomplete state.\nAre you sure?")
            wrapMode: Text.WordWrap
        }

        onAccepted: {
            // TODO: implement cancel logic
            progressPage.finished()
        }
    }
}
