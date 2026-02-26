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
    signal showExpert
    signal showProgress

    readonly property color cSurface:  darkMode ? "#242b35" : "#ffffff"
    readonly property color cHover:    darkMode ? "#2c3440" : "#eef1f5"
    readonly property color cBorder:   darkMode ? "#313840" : "#d0d7de"
    readonly property color cText:     darkMode ? "#e6edf3" : "#1f2328"
    readonly property color cTextSub:  darkMode ? "#8b949e" : "#656d76"
    readonly property color cPrimary:  "#3daee9"
    readonly property color cSuccess:  darkMode ? "#3fb950" : "#1a7f37"
    readonly property color cSuccessBg:darkMode ? "#162d1f" : "#dafbe1"

    Controls.ScrollView {
        anchors.fill: parent

        ColumnLayout {
            width: Math.min(parent.width - 48, 640)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0

            Item { Layout.preferredHeight: 32 }

            // ── Page Title ──
            Controls.Label {
                text: qsTr("Driver Installation")
                font.pixelSize: 20
                font.weight: Font.DemiBold
                color: page.cText
            }

            Item { Layout.preferredHeight: 4 }

            Controls.Label {
                text: qsTr("Choose an installation method for your %1").arg(
                    page.controller.gpu_model.length > 0
                        ? page.controller.gpu_model
                        : (page.controller.is_detecting ? qsTr("detected GPU") : qsTr("GPU")))
                font.pixelSize: 14
                color: page.cTextSub
            }

            Item { Layout.preferredHeight: 20 }

            // ── Warnings ──
            WarningBanner {
                visible: !page.controller.has_internet
                type: "warning"
                text: qsTr("Internet connection required for driver download.")
                darkMode: page.darkMode
                Layout.fillWidth: true
            }
            Item { visible: !page.controller.has_internet; Layout.preferredHeight: 8 }

            WarningBanner {
                visible: page.controller.secure_boot
                type: "error"
                text: qsTr("Secure Boot is enabled \u2014 unsigned drivers may not load. Consider disabling it in UEFI settings.")
                darkMode: page.darkMode
                Layout.fillWidth: true
            }
            Item { visible: page.controller.secure_boot; Layout.preferredHeight: 8 }

            // ── Express Install Card ──
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: expressRow.implicitHeight + 32
                radius: 10
                color: expressMA.containsMouse && page.controller.has_internet
                    ? page.cHover : page.cSurface
                border.width: 1
                border.color: page.cBorder
                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: expressMA
                    anchors.fill: parent
                    hoverEnabled: page.controller.has_internet && !page.controller.is_installing
                    cursorShape: hoverEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: page.controller.has_internet && !page.controller.is_installing
                    onClicked: {
                        page.controller.install_express();
                        page.showProgress();
                    }
                }

                RowLayout {
                    id: expressRow
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 16; spacing: 14

                    Rectangle {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 44
                        radius: 10
                        color: Qt.rgba(page.cSuccess.r, page.cSuccess.g, page.cSuccess.b, 0.12)
                        Controls.Label {
                            anchors.centerIn: parent; text: "\u2713"
                            font.pixelSize: 20; color: page.cSuccess
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Controls.Label {
                            text: qsTr("Express Install")
                            font.pixelSize: 15; font.weight: Font.DemiBold; color: page.cText
                        }
                        Controls.Label {
                            text: page.controller.best_version.length > 0
                                ? qsTr("nvidia-%1 \u00B7 Recommended").arg(page.controller.best_version)
                                : qsTr("Latest stable version \u00B7 Recommended")
                            font.pixelSize: 13; color: page.cTextSub
                        }
                    }

                    Rectangle {
                        visible: page.controller.has_internet
                        implicitWidth: recLbl.implicitWidth + 16
                        implicitHeight: 22; radius: 11
                        color: page.cSuccessBg
                        Controls.Label {
                            id: recLbl; anchors.centerIn: parent
                            text: qsTr("Recommended")
                            font.pixelSize: 11; font.weight: Font.DemiBold; color: page.cSuccess
                        }
                    }

                    Controls.Label { text: "\u203A"; font.pixelSize: 20; color: page.cTextSub }
                }
            }

            Item { Layout.preferredHeight: 10 }

            // ── Custom Install Card ──
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: customRow.implicitHeight + 32
                radius: 10
                color: customMA.containsMouse ? page.cHover : page.cSurface
                border.width: 1; border.color: page.cBorder
                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: customMA; anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: page.showExpert()
                }

                RowLayout {
                    id: customRow
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 16; spacing: 14

                    Rectangle {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 44
                        radius: 10
                        color: Qt.rgba(page.cPrimary.r, page.cPrimary.g, page.cPrimary.b, 0.12)
                        Controls.Label {
                            anchors.centerIn: parent; text: "\u2699"
                            font.pixelSize: 20; color: page.cPrimary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Controls.Label {
                            text: qsTr("Custom Install")
                            font.pixelSize: 15; font.weight: Font.DemiBold; color: page.cText
                        }
                        Controls.Label {
                            text: qsTr("Choose version, kernel module, and options")
                            font.pixelSize: 13; color: page.cTextSub
                        }
                    }

                    Controls.Label { text: "\u203A"; font.pixelSize: 20; color: page.cTextSub }
                }
            }

            Item { Layout.preferredHeight: 32 }
        }
    }
}
