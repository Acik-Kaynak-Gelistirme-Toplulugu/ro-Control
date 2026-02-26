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
    required property string kernelVersion
    signal showProgress
    signal goBack

    property string selectedVersion: ""
    property bool useOpenKernel: false
    property bool deepClean: false

    property bool selectedVersionInstallable: {
        if (page.selectedVersion.length === 0) return false;
        for (var i = 0; i < page.displayVersions.length; i++) {
            var item = page.displayVersions[i];
            var ver = typeof item === "string" ? item : item.version;
            if (ver === page.selectedVersion)
                return typeof item === "object" && item.installable !== undefined ? item.installable : true;
        }
        return false;
    }

    readonly property color cSurface:  darkMode ? "#242b35" : "#ffffff"
    readonly property color cHover:    darkMode ? "#2c3440" : "#eef1f5"
    readonly property color cBorder:   darkMode ? "#313840" : "#d0d7de"
    readonly property color cText:     darkMode ? "#e6edf3" : "#1f2328"
    readonly property color cTextSub:  darkMode ? "#8b949e" : "#656d76"
    readonly property color cTextMuted:darkMode ? "#6e7681" : "#8c959f"

    property var versionList: {
        var raw = page.controller.available_versions;
        if (raw.length === 0) return [];
        return raw.split(",");
    }

    property var displayVersions: {
        var raw = page.controller.official_versions_json;
        if (raw.length > 0) {
            try {
                var parsed = JSON.parse(raw);
                if (parsed.length > 0) return parsed;
            } catch (e) { /* fallback */ }
        }
        return versionList.map(function (v, idx) {
            return { version: v, changes: idx === 0 ? qsTr("Latest Stable") : qsTr("Official metadata unavailable"), is_latest: idx === 0 };
        });
    }

    onVisibleChanged: {
        if (visible) page.controller.load_official_versions();
    }

    Controls.ScrollView {
        anchors.fill: parent

        ColumnLayout {
            width: Math.min(parent.width - 48, 640)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0

            Item { Layout.preferredHeight: 24 }

            // ── Header Row ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Controls.ToolButton {
                    text: "\u2190"
                    font.pixelSize: 18
                    onClicked: page.goBack()
                    implicitWidth: 36; implicitHeight: 36
                }

                Controls.Label {
                    text: qsTr("Expert Driver Management")
                    font.pixelSize: 20; font.weight: Font.DemiBold
                    color: page.cText; Layout.fillWidth: true
                }

                Controls.Button {
                    text: qsTr("Refresh")
                    flat: true; font.pixelSize: 13
                    icon.name: "view-refresh"
                    onClicked: {
                        page.controller.detect_gpu();
                        page.controller.load_official_versions();
                    }
                }
            }

            Item { Layout.preferredHeight: 16 }

            // ── Current Driver Info ──
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: infoGrid.implicitHeight + 24
                radius: 10; color: page.cSurface
                border.width: 1; border.color: page.cBorder

                GridLayout {
                    id: infoGrid
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 14
                    columns: 2; rowSpacing: 6; columnSpacing: 12

                    Controls.Label { text: qsTr("Current Driver:"); color: page.cTextSub; font.pixelSize: 13 }
                    Controls.Label {
                        text: page.controller.driver_in_use.length > 0 ? page.controller.driver_in_use : qsTr("Not detected")
                        color: page.cText; font.pixelSize: 13; font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight; Layout.fillWidth: true
                    }

                    Controls.Label { text: qsTr("Kernel:"); color: page.cTextSub; font.pixelSize: 13 }
                    Controls.Label {
                        text: page.kernelVersion || "\u2014"
                        color: page.cText; font.pixelSize: 13; font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight; Layout.fillWidth: true
                    }
                }
            }

            Item { Layout.preferredHeight: 16 }

            // ── Available Versions ──
            Controls.Label {
                text: qsTr("Available Versions")
                font.pixelSize: 14; font.weight: Font.DemiBold; color: page.cTextSub
            }

            Item { Layout.preferredHeight: 8 }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: versionCol.implicitHeight + 16
                radius: 10; color: page.cSurface
                border.width: 1; border.color: page.cBorder

                ColumnLayout {
                    id: versionCol
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.top: parent.top; anchors.margins: 8
                    spacing: 2

                    Repeater {
                        model: page.displayVersions

                        VersionRow {
                            required property var modelData
                            required property int index

                            version: typeof modelData === "string" ? modelData : modelData.version
                            statusText: typeof modelData === "string" ? (index === 0 ? qsTr("Latest Stable") : "") : modelData.changes
                            status: (typeof modelData === "string" ? modelData : modelData.version) === page.controller.driver_in_use ? "installed" : "available"
                            source: typeof modelData === "object" && modelData.source ? modelData.source : "repo"
                            installable: typeof modelData === "object" && modelData.installable !== undefined ? modelData.installable : true
                            selected: page.selectedVersion === (typeof modelData === "string" ? modelData : modelData.version)
                            darkMode: page.darkMode

                            onClicked: page.selectedVersion = (typeof modelData === "string" ? modelData : modelData.version)
                            Layout.fillWidth: true
                        }
                    }

                    Controls.Label {
                        visible: page.versionList.length === 0
                        text: qsTr("No versions available. Check internet connection.")
                        color: page.cTextMuted; font.pixelSize: 12
                        Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                        Layout.topMargin: 12; Layout.bottomMargin: 12
                    }
                }
            }

            Controls.Label {
                text: qsTr("Versions are fetched from NVIDIA official sources and your local package repository. Versions marked 'Repo N/A' are not yet available in your package manager.")
                color: page.cTextMuted; font.pixelSize: 11
                wrapMode: Text.WordWrap; Layout.fillWidth: true
                Layout.topMargin: 6
            }

            Item { Layout.preferredHeight: 16 }

            // ── Kernel Module Selection ──
            Controls.Label {
                text: qsTr("Kernel Module")
                font.pixelSize: 14; font.weight: Font.DemiBold; color: page.cTextSub
            }

            Item { Layout.preferredHeight: 8 }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: moduleRow.implicitHeight + 24
                radius: 10; color: page.cSurface
                border.width: 1; border.color: page.cBorder

                RowLayout {
                    id: moduleRow
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.margins: 14; spacing: 16

                    Controls.RadioButton {
                        text: qsTr("Proprietary (Recommended)")
                        checked: !page.useOpenKernel
                        onClicked: page.useOpenKernel = false
                        font.pixelSize: 13
                    }

                    Controls.RadioButton {
                        text: qsTr("Open Kernel Module")
                        checked: page.useOpenKernel
                        onClicked: page.useOpenKernel = true
                        font.pixelSize: 13
                    }
                }
            }

            Item { Layout.preferredHeight: 12 }

            Controls.CheckBox {
                text: qsTr("Remove old configs (Deep Clean)")
                checked: page.deepClean
                onToggled: page.deepClean = checked
                font.pixelSize: 13
            }

            Item { Layout.preferredHeight: 16 }

            // ── Action Buttons ──
            RowLayout {
                Layout.fillWidth: true; spacing: 10

                Controls.Button {
                    text: page.selectedVersionInstallable
                        ? qsTr("Install Selected")
                        : qsTr("Not in Repo")
                    enabled: page.selectedVersion.length > 0 && page.selectedVersionInstallable
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    highlighted: true

                    contentItem: Controls.Label {
                        text: parent.text
                        font: parent.font
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        implicitHeight: 40
                        radius: 10
                        color: parent.enabled
                            ? (parent.down ? "#2a8ec4" : "#3daee9")
                            : (darkMode ? "#313840" : "#d0d7de")
                    }

                    onClicked: {
                        page.controller.install_custom(page.selectedVersion, page.useOpenKernel);
                        page.showProgress();
                    }
                }

                Controls.Button {
                    text: qsTr("Remove All")
                    Layout.fillWidth: true
                    font.pixelSize: 14

                    contentItem: Controls.Label {
                        text: parent.text
                        font: parent.font
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        implicitHeight: 40
                        radius: 10
                        color: parent.down
                            ? (darkMode ? "#c0392b" : "#b91c1c")
                            : (darkMode ? "#f85149" : "#cf222e")
                    }

                    onClicked: removeDialog.open()
                }
            }

            Item { Layout.preferredHeight: 24 }
        }
    }

    Controls.Dialog {
        id: removeDialog
        title: qsTr("Remove All Drivers?")
        modal: true; anchors.centerIn: parent
        standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel

        ColumnLayout {
            spacing: 8
            Controls.Label {
                text: qsTr("This will remove all NVIDIA drivers and reset to nouveau.\nA reboot will be required.")
                wrapMode: Text.WordWrap
            }
            Controls.CheckBox {
                text: qsTr("Also remove configuration files (deep clean)")
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
