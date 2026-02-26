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

                // App Logo
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 80; height: 80; radius: 20
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: page.cPrimary }
                        GradientStop { position: 1.0; color: page.cAccent }
                    }

                    Controls.Label { anchors.centerIn: parent; text: "🛡️"; font.pixelSize: 40 }

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
                        text: "Rust Edition"
                        font.pixelSize: 18; font.weight: Font.Bold; color: page.cPrimary
                    }
                }
            }

            // ── Secure Boot Status Banner ──
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720; Layout.fillWidth: true
                implicitHeight: _secbootContent.implicitHeight + 40
                radius: 16
                color: page.controller.secure_boot
                    ? Qt.rgba(page.cWarning.r, page.cWarning.g, page.cWarning.b, 0.1)
                    : Qt.rgba(page.cSuccess.r, page.cSuccess.g, page.cSuccess.b, 0.08)
                border.width: 1
                border.color: page.controller.secure_boot
                    ? Qt.rgba(page.cWarning.r, page.cWarning.g, page.cWarning.b, 0.3)
                    : Qt.rgba(page.cSuccess.r, page.cSuccess.g, page.cSuccess.b, 0.25)

                RowLayout {
                    id: _secbootContent
                    anchors.fill: parent; anchors.margins: 20; spacing: 16

                    Rectangle {
                        Layout.preferredWidth: 40; Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignTop; radius: 12
                        color: page.controller.secure_boot
                            ? Qt.rgba(page.cWarning.r, page.cWarning.g, page.cWarning.b, 0.2)
                            : Qt.rgba(page.cSuccess.r, page.cSuccess.g, page.cSuccess.b, 0.15)
                        Controls.Label {
                            anchors.centerIn: parent
                            text: page.controller.secure_boot ? "⚠️" : "✅"
                            font.pixelSize: 20
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 8
                        Controls.Label {
                            text: page.controller.secure_boot
                                ? qsTr("Secure Boot is Enabled")
                                : qsTr("Secure Boot is Disabled")
                            font.pixelSize: 16; font.weight: Font.Bold
                            color: page.controller.secure_boot ? page.cWarning : page.cSuccess
                        }
                        Controls.Label {
                            text: page.controller.secure_boot
                                ? qsTr("Your system has Secure Boot enabled in UEFI/BIOS. Third-party kernel modules (including NVIDIA proprietary drivers) may fail to load unless they are signed with a Machine Owner Key (MOK). You may need to enroll a key after installation, or disable Secure Boot in BIOS.")
                                : qsTr("Third-party kernel modules (NVIDIA drivers) can load freely without MOK signing. No additional steps are required for driver installation.")
                            font.pixelSize: 14; color: page.cMutedFg
                            wrapMode: Text.WordWrap; Layout.fillWidth: true; lineHeight: 1.4
                        }
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

                    onClicked: _expressConfirmDialog.open()
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

    // ── Express Install Confirmation Dialog ──
    Controls.Dialog {
        id: _expressConfirmDialog
        title: qsTr("Express Install — Confirm Options")
        modal: true; anchors.centerIn: parent
        width: Math.min(500, parent.width - 40)
        standardButtons: Controls.Dialog.NoButton

        property bool useOpenKernel: false

        ColumnLayout {
            width: parent.width; spacing: 16

            // Info rows
            GridLayout {
                columns: 2; columnSpacing: 16; rowSpacing: 10
                Layout.fillWidth: true

                Controls.Label { text: qsTr("Driver Version:"); font.pixelSize: 14; color: page.cMutedFg }
                Controls.Label {
                    text: page.controller.best_version.length > 0
                        ? "v" + page.controller.best_version + " (" + qsTr("Latest Stable") + ")"
                        : qsTr("Best available")
                    font.pixelSize: 14; font.weight: Font.Bold; color: page.cFg
                    Layout.fillWidth: true; horizontalAlignment: Text.AlignRight
                }

                Controls.Label { text: qsTr("GPU:"); font.pixelSize: 14; color: page.cMutedFg }
                Controls.Label {
                    text: page.controller.gpu_model.length > 0 ? page.controller.gpu_model : "N/A"
                    font.pixelSize: 14; font.weight: Font.Bold; color: page.cFg
                    Layout.fillWidth: true; horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }

                Controls.Label { text: qsTr("Secure Boot:"); font.pixelSize: 14; color: page.cMutedFg }
                Controls.Label {
                    text: page.controller.secure_boot
                        ? qsTr("ON — MOK signing may be required")
                        : qsTr("OFF — No restrictions")
                    font.pixelSize: 14; font.weight: Font.Bold
                    color: page.controller.secure_boot ? page.cWarning : page.cSuccess
                    Layout.fillWidth: true; horizontalAlignment: Text.AlignRight
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: page.cBorder }

            // Kernel Module Type selection
            Controls.Label { text: qsTr("Kernel Module Type"); font.pixelSize: 16; font.weight: Font.Bold; color: page.cFg }

            ColumnLayout {
                spacing: 8; Layout.fillWidth: true

                Controls.RadioButton {
                    id: _radioProprietary; checked: true; text: qsTr("Proprietary (Closed Source)")
                    onCheckedChanged: if (checked) _expressConfirmDialog.useOpenKernel = false
                }
                Controls.Label {
                    text: qsTr("Official NVIDIA binary driver. Best compatibility and performance.")
                    font.pixelSize: 12; color: page.cMutedFg; leftPadding: 36
                }

                Controls.RadioButton {
                    id: _radioOpen; text: qsTr("Open Kernel Module")
                    onCheckedChanged: if (checked) _expressConfirmDialog.useOpenKernel = true
                }
                Controls.Label {
                    text: qsTr("NVIDIA open source kernel module. Requires Turing+ GPU (RTX 20xx/30xx/40xx). Experimental.")
                    font.pixelSize: 12; color: page.cMutedFg; leftPadding: 36
                    wrapMode: Text.WordWrap; Layout.fillWidth: true
                }
            }

            // EULA notice (only for proprietary)
            Rectangle {
                visible: !_expressConfirmDialog.useOpenKernel
                Layout.fillWidth: true
                implicitHeight: _eulaRow.implicitHeight + 20; radius: 8
                color: Qt.rgba(page.cWarning.r, page.cWarning.g, page.cWarning.b, 0.08)

                RowLayout {
                    id: _eulaRow; anchors.fill: parent; anchors.margins: 10; spacing: 8
                    Controls.Label { text: "⚠️"; font.pixelSize: 14 }
                    Controls.Label {
                        text: qsTr("By installing the NVIDIA Proprietary driver, you agree to the NVIDIA EULA.")
                        font.pixelSize: 12; color: page.cMutedFg; wrapMode: Text.WordWrap; Layout.fillWidth: true
                    }
                }
            }

            // Action buttons
            RowLayout {
                Layout.fillWidth: true; spacing: 12

                GradientButton {
                    Layout.fillWidth: true
                    text: qsTr("Accept and Install")
                    useGradient: true; gradientStart: page.cPrimary; gradientEnd: page.cAccent
                    darkMode: page.darkMode
                    onClicked: {
                        _expressConfirmDialog.close();
                        page.controller.install_express(_expressConfirmDialog.useOpenKernel);
                        page.showProgress();
                    }
                }

                Controls.Button {
                    text: qsTr("Cancel"); implicitHeight: 40
                    onClicked: _expressConfirmDialog.close()
                }
            }
        }
    }
}
