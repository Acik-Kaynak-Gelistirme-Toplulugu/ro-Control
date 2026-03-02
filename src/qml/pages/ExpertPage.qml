pragma ComponentBehavior: Bound
// qmllint disable unqualified
// qmllint disable missing-property
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import "../components"
import io.github.AcikKaynakGelistirmeToplulugu.rocontrol

Item {
    id: page

    required property var controller
    required property string kernelVersion
    signal showProgress
    signal goBack

    property string selectedVersion: ""
    property bool useOpenKernel: false
    property bool deepClean: false

    property var versionList: {
        var raw = page.controller.available_versions;
        if (raw.length === 0)
            return [];
        return raw.split(",");
    }

    property var displayVersions: {
        var raw = page.controller.official_versions_json;
        if (raw.length > 0) {
            try {
                var p = JSON.parse(raw);
                if (p.length > 0)
                    return p;
            } catch (e) {}
        }
        return versionList.map(function (v, i) {
            return {
                version: v,
                changes: i === 0 ? qsTr("Latest Stable") : "",
                is_latest: i === 0,
                installable: true
            };
        });
    }

    property bool selectedVersionInstallable: {
        if (page.selectedVersion.length === 0)
            return false;
        for (var i = 0; i < page.displayVersions.length; i++) {
            var item = page.displayVersions[i];
            var ver = typeof item === "string" ? item : item.version;
            if (ver === page.selectedVersion)
                return typeof item === "object" && item.installable !== undefined ? item.installable : true;
        }
        return false;
    }

    onVisibleChanged: {
        if (visible)
            page.controller.load_official_versions();
    }

    Controls.ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: 20

            Item {
                Layout.preferredHeight: 12
            }

            // ── Header ──
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720
                spacing: 12

                Controls.Label {
                    text: qsTr("Expert Driver Management")
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    color: Theme.foreground
                }
                Controls.Label {
                    text: "Rust Edition"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Theme.primary
                }
            }

            // ── Current Driver Info ──
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720
                Layout.fillWidth: true
                implicitHeight: _driverInfo.implicitHeight + 40
                radius: 16
                color: Theme.card
                border.width: 1
                border.color: Theme.border

                ColumnLayout {
                    id: _driverInfo
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        Rectangle {
                            implicitWidth: 32
                            implicitHeight: 32
                            radius: 8
                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: Theme.primary
                                }
                                GradientStop {
                                    position: 1
                                    color: Theme.accent
                                }
                            }
                            Controls.Label {
                                anchors.centerIn: parent
                                text: "🔧"
                                font.pixelSize: 16
                            }
                        }
                        Controls.Label {
                            text: qsTr("Current Driver")
                            font.pixelSize: 14
                            color: Theme.mutedForeground
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        Controls.Label {
                            text: (page.controller.driver_in_use.length > 0 ? page.controller.driver_in_use : qsTr("N/A")) + " (proprietary)"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: Theme.foreground
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        Controls.Label {
                            text: qsTr("Kernel:")
                            font.pixelSize: 13
                            color: Theme.mutedForeground
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        Controls.Label {
                            text: page.kernelVersion || "—"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: Theme.foreground
                        }
                    }
                }
            }

            // ── Available Versions ──
            Controls.Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720
                text: qsTr("Available Versions")
                font.pixelSize: 18
                font.weight: Font.Bold
                color: Theme.foreground
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720
                Layout.fillWidth: true
                implicitHeight: _verCol.implicitHeight + 40
                radius: 16
                color: Theme.card
                border.width: 1
                border.color: Theme.border

                ColumnLayout {
                    id: _verCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    Repeater {
                        model: page.displayVersions

                        delegate: Controls.ItemDelegate {
                            id: verDelegate
                            Layout.fillWidth: true
                            implicitHeight: 56

                            required property int index
                            required property var modelData

                            readonly property string ver: typeof verDelegate.modelData === "string" ? verDelegate.modelData : verDelegate.modelData.version
                            readonly property bool isSelected: page.selectedVersion === verDelegate.ver

                            background: Rectangle {
                                radius: 12
                                color: verDelegate.isSelected ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1) : (verDelegate.hovered ? Theme.muted : "transparent")
                                border.width: verDelegate.isSelected ? 2 : 0
                                border.color: Theme.primary
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 300
                                    }
                                }
                            }

                            contentItem: RowLayout {
                                spacing: 16
                                Rectangle {
                                    implicitWidth: 24
                                    implicitHeight: 24
                                    radius: 12
                                    color: verDelegate.isSelected ? Theme.primary : "transparent"
                                    border.width: 2
                                    border.color: verDelegate.isSelected ? Theme.primary : Theme.mutedForeground
                                    Rectangle {
                                        visible: verDelegate.isSelected
                                        anchors.centerIn: parent
                                        implicitWidth: 12
                                        implicitHeight: 12
                                        radius: 6
                                        color: "white"
                                    }
                                }
                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true
                                    Controls.Label {
                                        text: verDelegate.ver
                                        font.pixelSize: 16
                                        font.weight: verDelegate.isSelected ? Font.Bold : Font.Normal
                                        color: Theme.foreground
                                    }
                                    Controls.Label {
                                        visible: typeof verDelegate.modelData === "object" && verDelegate.modelData.changes
                                        text: typeof verDelegate.modelData === "object" ? (verDelegate.modelData.changes || "") : ""
                                        font.pixelSize: 12
                                        color: Theme.mutedForeground
                                        elide: Text.ElideRight
                                    }
                                }
                                Rectangle {
                                    visible: typeof verDelegate.modelData === "object" && verDelegate.modelData.is_latest
                                    implicitWidth: _ltLbl.width + 16
                                    implicitHeight: 22
                                    radius: 11
                                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                                    Controls.Label {
                                        id: _ltLbl
                                        anchors.centerIn: parent
                                        text: "Latest"
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        color: Theme.primary
                                    }
                                }
                            }
                            onClicked: page.selectedVersion = verDelegate.ver
                        }
                    }

                    Controls.Label {
                        visible: page.versionList.length === 0
                        text: qsTr("No versions available. Check internet connection.")
                        color: Theme.mutedForeground
                        font.pixelSize: 12
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // ── Configuration ──
            Controls.Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720
                text: qsTr("Configuration")
                font.pixelSize: 18
                font.weight: Font.Bold
                color: Theme.foreground
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720
                Layout.fillWidth: true
                implicitHeight: _modLayout.implicitHeight + 40
                radius: 16
                color: Theme.card
                border.width: 1
                border.color: Theme.border

                ColumnLayout {
                    id: _modLayout
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    Controls.Label {
                        text: qsTr("Kernel Module Type")
                        font.pixelSize: 14
                        color: Theme.mutedForeground
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        Repeater {
                            model: [
                                {
                                    value: false,
                                    label: qsTr("Proprietary"),
                                    emoji: "🔒"
                                },
                                {
                                    value: true,
                                    label: qsTr("Open Source"),
                                    emoji: "🔓"
                                }
                            ]
                            delegate: Controls.Button {
                                Layout.fillWidth: true
                                implicitHeight: 48
                                required property var modelData
                                background: Rectangle {
                                    radius: 12
                                    color: page.useOpenKernel === modelData.value ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1) : Theme.muted
                                    border.width: page.useOpenKernel === modelData.value ? 2 : 0
                                    border.color: Theme.primary
                                }
                                contentItem: RowLayout {
                                    spacing: 8
                                    Controls.Label {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.emoji
                                        font.pixelSize: 18
                                    }
                                    Controls.Label {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.label
                                        font.pixelSize: 16
                                        font.weight: Font.Medium
                                        color: Theme.foreground
                                    }
                                }
                                onClicked: page.useOpenKernel = modelData.value
                            }
                        }
                    }
                }
            }

            // ── Deep Clean ──
            Controls.CheckDelegate {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720
                Layout.fillWidth: true
                text: "🗑️  " + qsTr("Deep Clean Installation (removes all previous drivers)")
                checked: page.deepClean
                onToggled: page.deepClean = checked
                background: Rectangle {
                    radius: 16
                    color: page.deepClean ? Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.1) : Theme.card
                    border.width: 1
                    border.color: page.deepClean ? Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.3) : Theme.border
                }
            }

            // ── Action Buttons ──
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 720
                Layout.fillWidth: true
                spacing: 16

                GradientButton {
                    Layout.fillWidth: true
                    text: page.selectedVersionInstallable ? "📥 " + qsTr("Install Selected Version") : qsTr("Not in Repo")
                    enabled: page.selectedVersion.length > 0 && page.selectedVersionInstallable
                    useGradient: true
                    gradientStart: Theme.primary
                    gradientEnd: Theme.accent
                    onClicked: {
                        page.controller.install_custom(page.selectedVersion, page.useOpenKernel);
                        page.showProgress();
                    }
                }

                GradientButton {
                    Layout.preferredWidth: 140
                    text: "🗑️ " + qsTr("Remove All")
                    useGradient: true
                    gradientStart: Theme.error
                    gradientEnd: Qt.darker(Theme.error, 1.2)
                    onClicked: _removeDialog.open()
                }
            }

            // ── Back Button ──
            Controls.Button {
                Layout.alignment: Qt.AlignHCenter
                text: "← " + qsTr("Back to Install")
                flat: true
                font.pixelSize: 14
                onClicked: page.goBack()
            }

            Item {
                Layout.preferredHeight: 12
            }
        }
    }

    Controls.Dialog {
        id: _removeDialog
        title: qsTr("Remove All Drivers?")
        modal: true
        anchors.centerIn: parent
        standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel
        ColumnLayout {
            spacing: 8
            Controls.Label {
                text: qsTr("This will remove all NVIDIA drivers.\nA reboot will be required.")
                wrapMode: Text.WordWrap
            }
            Controls.CheckBox {
                text: qsTr("Also remove config files (deep clean)")
                checked: page.deepClean
                onToggled: page.deepClean = checked
            }
        }
        onAccepted: {
            page.controller.remove_drivers(page.deepClean);
            page.showProgress();
        }
    }
}
