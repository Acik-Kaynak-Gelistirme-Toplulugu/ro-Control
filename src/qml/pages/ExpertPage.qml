import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import io.github.AcikKaynakGelistirmeToplulugu.rocontrol

// Expert Page — Manual driver version selection
// Allows custom choice of version, kernel module type, and cleanup options

Item {
    id: expertPage

    required property var controller
    signal showProgress()
    signal goBack()

    property string selectedVersion: ""
    property bool useOpenKernel: false
    property bool deepClean: false

    // Parse versions from controller
    property var versionList: {
        var raw = controller.get_available_versions()
        if (raw.length === 0) return []
        return raw.split(",")
    }

    Controls.ScrollView {
        anchors.fill: parent

        ColumnLayout {
            width: Math.min(parent.width, 560)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Item { Layout.preferredHeight: 24 }

            // ─── Header ───
            RowLayout {
                spacing: 12

                Controls.Button {
                    icon.name: "go-previous"
                    flat: true
                    onClicked: expertPage.goBack()
                }

                ColumnLayout {
                    spacing: 2
                    Controls.Label {
                        text: qsTr("Expert Driver Management")
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Controls.Label {
                        text: qsTr("Current: %1").arg(controller.driver_in_use)
                        opacity: 0.6
                        font.pixelSize: 12
                    }
                }
            }

            // ─── Version Selection ───
            Controls.GroupBox {
                Layout.fillWidth: true
                title: qsTr("Available Versions")

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Repeater {
                        model: expertPage.versionList

                        VersionRow {
                            required property string modelData
                            required property int index
                            
                            version: modelData
                            statusText: index === 0 ? qsTr("Latest Stable") : ""
                            status: index === 0 ? "available" : "available"
                            selected: expertPage.selectedVersion === modelData
                            
                            onClicked: expertPage.selectedVersion = modelData
                            
                            Layout.fillWidth: true
                        }
                    }

                    Controls.Label {
                        visible: expertPage.versionList.length === 0
                        text: qsTr("No versions available. Check internet connection.")
                        opacity: 0.5
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 12
                    }
                }
            }

            // ─── Kernel Module Type ───
            Controls.GroupBox {
                Layout.fillWidth: true
                title: qsTr("Kernel Module")

                RowLayout {
                    spacing: 16
                    Controls.RadioButton {
                        text: qsTr("Proprietary (nvidia)")
                        checked: !expertPage.useOpenKernel
                        onClicked: expertPage.useOpenKernel = false
                    }
                    Controls.RadioButton {
                        text: qsTr("Open Kernel (nvidia-open)")
                        checked: expertPage.useOpenKernel
                        onClicked: expertPage.useOpenKernel = true
                    }
                }
            }

            // ─── Options ───
            Controls.CheckBox {
                text: qsTr("Deep Clean (remove previous configs)")
                checked: expertPage.deepClean
                onToggled: expertPage.deepClean = checked
            }

            // ─── Action Buttons ───
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Controls.Button {
                    text: qsTr("Install Selected")
                    icon.name: "download"
                    enabled: expertPage.selectedVersion.length > 0
                    highlighted: true
                    Layout.fillWidth: true
                    onClicked: {
                        controller.install_custom(expertPage.selectedVersion, expertPage.useOpenKernel)
                        expertPage.showProgress()
                    }
                }

                Controls.Button {
                    text: qsTr("Remove All & Reset")
                    icon.name: "edit-delete"
                    Layout.fillWidth: true
                    onClicked: removeDialog.open()
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }

    // ─── Remove Confirmation Dialog ───
    Controls.Dialog {
        id: removeDialog
        title: qsTr("Remove All Drivers?")
        modal: true
        anchors.centerIn: parent
        standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel

        ColumnLayout {
            spacing: 8
            Controls.Label {
                text: qsTr("This will remove all NVIDIA drivers and reset to nouveau.\nA reboot will be required.")
                wrapMode: Text.WordWrap
            }
            Controls.CheckBox {
                text: qsTr("Also remove configuration files (deep clean)")
                checked: expertPage.deepClean
                onToggled: expertPage.deepClean = checked
            }
        }

        onAccepted: {
            controller.remove_drivers(expertPage.deepClean)
            expertPage.showProgress()
        }
    }
}
