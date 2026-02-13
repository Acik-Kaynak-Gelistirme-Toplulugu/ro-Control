import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import io.github.AcikKaynakGelistirmeToplulugu.rocontrol

// Install Page — Express & Custom install options
// States: default, update available, up to date, no internet, secure boot

Item {
    id: installPage

    required property var controller
    signal showExpert()
    signal showProgress()

    Controls.ScrollView {
        anchors.fill: parent

        ColumnLayout {
            width: Math.min(parent.width, 560)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Item { Layout.preferredHeight: 40 }

            // ─── Hero Section ───
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                // GPU Icon
                Controls.Label {
                    text: "🖥"
                    font.pixelSize: 48
                    Layout.alignment: Qt.AlignHCenter
                }

                Controls.Label {
                    text: qsTr("Select Installation Type")
                    font.pixelSize: 22
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Controls.Label {
                    text: qsTr("Optimized options for your hardware")
                    opacity: 0.6
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            Item { Layout.preferredHeight: 12 }

            // ─── No Internet Warning ───
            WarningBanner {
                visible: !controller.has_internet
                type: "warning"
                text: qsTr("Internet connection required for driver download")
                Layout.fillWidth: true
            }

            // ─── Secure Boot Warning ───
            WarningBanner {
                visible: controller.secure_boot
                type: "error"
                text: qsTr("Secure Boot is enabled — unsigned drivers may not work. Disable it in UEFI to proceed.")
                Layout.fillWidth: true
            }

            // ─── Express Install Card ───
            ActionCard {
                Layout.fillWidth: true
                enabled: controller.has_internet
                
                title: qsTr("Express Install (Recommended)")
                description: controller.is_up_to_date
                    ? qsTr("✓ Driver is up to date (%1)").arg(controller.best_version)
                    : qsTr("Install nvidia-%1 — Compatible ✓").arg(controller.best_version)
                icon: "✓"
                accentColor: palette.highlight
                
                onClicked: installPage.showProgress()
            }

            // ─── Custom Install Card ───
            ActionCard {
                Layout.fillWidth: true
                enabled: true
                
                title: qsTr("Custom Install (Expert)")
                description: qsTr("Choose version, kernel module, and cleanup options")
                icon: "⚙"
                accentColor: palette.mid
                
                onClicked: installPage.showExpert()
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
