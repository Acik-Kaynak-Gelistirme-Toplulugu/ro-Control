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

    readonly property color cCard:    darkMode ? "#1e293b" : "#fcfcfc"
    readonly property color cBorder:  darkMode ? "#334155" : "#e5e7eb"
    readonly property color cFg:      darkMode ? "#e2e8f0" : "#1a1d23"
    readonly property color cMutedFg: darkMode ? "#94a3b8" : "#64748b"
    readonly property color cPrimary: darkMode ? "#60a5fa" : "#3b82f6"
    readonly property color cAccent:  darkMode ? "#a78bfa" : "#8b5cf6"
    readonly property color cSuccess: darkMode ? "#34d399" : "#10b981"
    readonly property color cWarning: darkMode ? "#fbbf24" : "#f59e0b"

    Controls.ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: 24

            Item { Layout.preferredHeight: 12 }

            // ── Hero Section ──
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720; Layout.fillWidth: true
                spacing: 20

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 80; height: 80; radius: 20
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#EF4444" }
                        GradientStop { position: 1.0; color: "#DC2626" }
                    }

                    Controls.Label { anchors.centerIn: parent; text: "🦀"; font.pixelSize: 40 }

                    RotationAnimator on rotation { running: true; from: 0; to: 360; duration: 20000; loops: Animation.Infinite }
                    SequentialAnimation on scale {
                        running: true; loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 1.05; duration: 2000; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.05; to: 1.0; duration: 2000; easing.type: Easing.InOutQuad }
                    }
                }

                Controls.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Select Installation Type")
                    font.pixelSize: 30; font.weight: Font.Bold; color: page.cFg
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter; spacing: 12
                    Controls.Label {
                        text: qsTr("Optimized for your hardware •")
                        font.pixelSize: 18; color: page.cMutedFg
                    }
                    Controls.Label {
                        text: "🦀 Rust Powered"
                        font.pixelSize: 18; font.weight: Font.Bold; color: "#EF4444"
                    }
                }
            }

            // ── Action Cards ──
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720; Layout.fillWidth: true
                spacing: 16

                ActionCard {
                    Layout.fillWidth: true
                    iconEmoji: "⚡"; cardTitle: qsTr("Express Install")
                    description: page.controller.best_version.length > 0
                        ? qsTr("nvidia-%1 · Automatically installs the recommended driver").arg(page.controller.best_version)
                        : qsTr("Automatically installs the recommended driver with optimal settings")
                    statusText: page.controller.has_internet
                        ? (page.controller.best_version.length > 0 ? qsTr("nvidia-%1 · Verified Compatible").arg(page.controller.best_version) : qsTr("Recommended"))
                        : ""
                    statusColor: page.cSuccess
                    showGradientOverlay: true
                    enabled: page.controller.has_internet && !page.controller.is_installing
                    darkMode: page.darkMode

                    onClicked: {
                        page.controller.install_express();
                        page.showProgress();
                    }
                }

                ActionCard {
                    Layout.fillWidth: true
                    iconEmoji: "⚙️"; cardTitle: qsTr("Custom Install")
                    description: qsTr("Advanced options to choose specific driver version and kernel module type")
                    statusText: qsTr("Expert Mode")
                    statusColor: page.cPrimary
                    darkMode: page.darkMode

                    onClicked: page.showExpert()
                }
            }

            // ── Warning Banner ──
            Rectangle {
                visible: page.controller.secure_boot
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720; Layout.fillWidth: true
                implicitHeight: _warnContent.implicitHeight + 40
                radius: 16
                color: Qt.rgba(page.cWarning.r, page.cWarning.g, page.cWarning.b, 0.1)
                border.width: 1
                border.color: Qt.rgba(page.cWarning.r, page.cWarning.g, page.cWarning.b, 0.3)

                RowLayout {
                    id: _warnContent
                    anchors.fill: parent; anchors.margins: 20; spacing: 16

                    Rectangle {
                        Layout.preferredWidth: 40; Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignTop; radius: 12
                        color: Qt.rgba(page.cWarning.r, page.cWarning.g, page.cWarning.b, 0.2)
                        Controls.Label { anchors.centerIn: parent; text: "✨"; font.pixelSize: 20 }
                        SequentialAnimation on rotation {
                            running: true; loops: Animation.Infinite
                            NumberAnimation { from: 0; to: 10; duration: 1000 }
                            NumberAnimation { from: 10; to: 0; duration: 1000 }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 8
                        Controls.Label {
                            text: qsTr("Secure Boot Detected")
                            font.pixelSize: 16; font.weight: Font.Bold; color: page.cWarning
                        }
                        Controls.Label {
                            text: qsTr("You may need to sign the kernel modules or disable Secure Boot in BIOS to use NVIDIA proprietary drivers.")
                            font.pixelSize: 14; color: page.cMutedFg
                            wrapMode: Text.WordWrap; Layout.fillWidth: true; lineHeight: 1.4
                        }
                    }
                }
            }

            // ── No Internet Warning ──
            Rectangle {
                visible: !page.controller.has_internet
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720; Layout.fillWidth: true
                implicitHeight: _netWarn.implicitHeight + 40
                radius: 16
                color: Qt.rgba(page.cWarning.r, page.cWarning.g, page.cWarning.b, 0.1)
                border.width: 1; border.color: Qt.rgba(page.cWarning.r, page.cWarning.g, page.cWarning.b, 0.3)

                RowLayout {
                    id: _netWarn
                    anchors.fill: parent; anchors.margins: 20; spacing: 16
                    Controls.Label { text: "⚠️"; font.pixelSize: 20 }
                    Controls.Label {
                        text: qsTr("Internet connection required for driver download.")
                        font.pixelSize: 14; color: page.cMutedFg; Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
            }

            Item { Layout.preferredHeight: 12 }
        }
    }
}
