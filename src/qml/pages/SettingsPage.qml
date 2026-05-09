import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: settingsPage
    required property var uiPreferences

    property var theme: ({})
    property bool darkMode: false
    property bool showAdvancedInfo: true
    property real uiScale: 1.0
    readonly property bool hasUiPreferences: settingsPage.uiPreferences !== null

    readonly property color cardColor: theme && theme.cardStrong ? theme.cardStrong : "#f5f8ff"
    readonly property color borderColor: theme && theme.border ? theme.border : "#d9e1f0"
    readonly property color textColor: theme && theme.text ? theme.text : "#12213a"
    readonly property color softTextColor: theme && theme.textSoft ? theme.textSoft : "#6f829e"

    ScrollView {
        id: pageScroll
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: pageScroll.availableWidth
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                radius: 14
                color: settingsPage.cardColor
                border.width: 1
                border.color: settingsPage.borderColor
                implicitHeight: preferencesLayout.implicitHeight + 24

                ColumnLayout {
                    id: preferencesLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Label {
                        text: qsTr("Appearance")
                        color: settingsPage.textColor
                        font.pixelSize: Math.round(18 * settingsPage.uiScale)
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Show advanced diagnostics")
                            color: settingsPage.textColor
                        }

                        Switch {
                            checked: settingsPage.hasUiPreferences ? settingsPage.uiPreferences.showAdvancedInfo : false
                            enabled: settingsPage.hasUiPreferences
                            onToggled: if (settingsPage.hasUiPreferences) settingsPage.uiPreferences.setShowAdvancedInfo(checked)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Button {
                            text: qsTr("Reset Defaults")
                            enabled: settingsPage.hasUiPreferences
                            onClicked: if (settingsPage.hasUiPreferences) settingsPage.uiPreferences.resetToDefaults()
                        }
                    }
                }
            }
        }
    }

}
