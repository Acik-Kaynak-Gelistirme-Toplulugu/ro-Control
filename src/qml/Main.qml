import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    width: 1360
    height: 860
    minimumWidth: 1120
    minimumHeight: 760
    title: qsTr("ro-Control")

    readonly property string themeMode: uiPreferences.themeMode
    readonly property bool darkMode: themeMode === "dark"
                                     || (themeMode === "system"
                                         && Qt.styleHints.colorScheme === Qt.Dark)
    readonly property bool compactMode: uiPreferences.compactMode
    readonly property bool showAdvancedInfo: uiPreferences.showAdvancedInfo
    readonly property var theme: darkMode ? ({
        window: "#0f141b",
        shell: "#121821",
        card: "#1b2432",
        cardStrong: "#212c3d",
        border: "#2a3647",
        text: "#e7edf6",
        textMuted: "#c8d0dd",
        textSoft: "#98a6bb",
        accentA: "#7b8fff",
        accentB: "#2ed0a0",
        accentC: "#ffb020",
        success: "#32d39c",
        warning: "#f0b540",
        danger: "#f06d6d",
        successBg: "#14392f",
        warningBg: "#332a17",
        dangerBg: "#391c22",
        infoBg: "#26364a",
        sidebarBg: "#11161d",
        sidebarText: "#eef2f8",
        sidebarMuted: "#95a4ba",
        sidebarAccent: "#90a1ff",
        sidebarActive: "#243146",
        sidebarHover: "#1a2330",
        sidebarBorder: "#273242",
        sidebarHint: "#77879d",
        topbarBg: "#1a2330",
        topbarChip: "#222d3d",
        topbarValue: "#eef2f8",
        contentBg: "#11161d",
        contentGlow: "#1a2431"
    }) : ({
        window: "#f3f6fb",
        shell: "#edf2f8",
        card: "#ffffff",
        cardStrong: "#f5f8fe",
        border: "#d9e2ef",
        text: "#1f2430",
        textMuted: "#56657d",
        textSoft: "#71809b",
        accentA: "#6674ff",
        accentB: "#2bbf97",
        accentC: "#ffad32",
        success: "#21b37f",
        warning: "#f59e0b",
        danger: "#e15a5a",
        successBg: "#e7faf2",
        warningBg: "#fff3dd",
        dangerBg: "#fdeceb",
        infoBg: "#ecf3ff",
        sidebarBg: "#fcfdff",
        sidebarText: "#232936",
        sidebarMuted: "#728199",
        sidebarAccent: "#6674ff",
        sidebarActive: "#edf3ff",
        sidebarHover: "#f5f8fd",
        sidebarBorder: "#dde5f0",
        sidebarHint: "#7c8ba2",
        topbarBg: "#ffffff",
        topbarChip: "#f4f7fc",
        topbarValue: "#202531",
        contentBg: "#f5f7fb",
        contentGlow: "#ebeff8"
    })

    color: theme.window
    property bool languageDialogOpen: false

    function topBarValue(fallback, preferred) {
        return preferred && preferred.length > 0 ? preferred : fallback;
    }

    function toggleThemeMode() {
        if (uiPreferences.themeMode === "dark") {
            uiPreferences.setThemeMode("light");
        } else {
            uiPreferences.setThemeMode("dark");
        }
    }

    onLanguageDialogOpenChanged: {
        if (languageDialogOpen) {
            languagePopup.open();
        } else {
            languagePopup.close();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.theme.window
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 78
            color: root.theme.topbarBg
            border.width: 1
            border.color: root.theme.border

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 32
                anchors.rightMargin: 32
                spacing: 22

                Repeater {
                    model: [
                        {
                            label: qsTr("Driver"),
                            value: root.topBarValue(qsTr("not installed"),
                                                    nvidiaDetector.driverVersion.length > 0
                                                    ? "nvidia-" + nvidiaDetector.driverVersion
                                                    : nvidiaUpdater.currentVersion.length > 0
                                                      ? "nvidia-" + nvidiaUpdater.currentVersion
                                                      : "")
                        },
                        {
                            label: qsTr("Secure Boot"),
                            value: nvidiaDetector.secureBootKnown
                                   ? (nvidiaDetector.secureBootEnabled ? qsTr("ON") : qsTr("OFF"))
                                   : qsTr("Unknown")
                        },
                        {
                            label: qsTr("GPU"),
                            value: root.topBarValue(qsTr("Unavailable"), nvidiaDetector.gpuName.length > 0 ? nvidiaDetector.gpuName : nvidiaDetector.displayAdapterName)
                        }
                    ]

                    delegate: RowLayout {
                        required property var modelData
                        spacing: 12

                        Label {
                            text: modelData.label + ":"
                            color: root.theme.textSoft
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            radius: 16
                            color: root.theme.topbarChip
                            implicitHeight: 38
                            implicitWidth: valueLabel.implicitWidth + 28

                            Label {
                                id: valueLabel
                                anchors.centerIn: parent
                                text: modelData.value
                                color: root.theme.topbarValue
                                font.pixelSize: 14
                                font.weight: Font.Bold
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 42
                    height: 42
                    radius: 21
                    color: root.theme.cardStrong
                    border.width: 1
                    border.color: root.theme.border

                    Label {
                        anchors.centerIn: parent
                        text: "\u263e"
                        color: root.theme.text
                        font.pixelSize: 19
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleThemeMode()
                    }
                }

                Rectangle {
                    width: 42
                    height: 42
                    radius: 21
                    color: root.theme.cardStrong
                    border.width: 1
                    border.color: root.theme.border

                    Label {
                        anchors.centerIn: parent
                        text: "\uD83C\uDF10"
                        color: root.theme.text
                        font.pixelSize: 17
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.languageDialogOpen = !root.languageDialogOpen
                    }
                }

            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            SidebarMenu {
                id: sidebar
                theme: root.theme
                Layout.fillHeight: true
                currentIndex: 0
                onCurrentIndexChanged: stack.currentIndex = currentIndex
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: root.theme.contentBg
                clip: true

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    opacity: root.darkMode ? 0.22 : 1.0
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.theme.contentGlow }
                        GradientStop { position: 0.22; color: Qt.rgba(0, 0, 0, 0) }
                        GradientStop { position: 0.78; color: Qt.rgba(0, 0, 0, 0) }
                        GradientStop { position: 1.0; color: root.theme.contentGlow }
                    }
                }

                StackLayout {
                    id: stack
                    anchors.fill: parent
                    anchors.margins: root.compactMode ? 20 : 28
                    currentIndex: sidebar.currentIndex

                    DriverPage {
                        theme: root.theme
                        darkMode: root.darkMode
                        compactMode: root.compactMode
                        showAdvancedInfo: root.showAdvancedInfo
                    }

                    SettingsPage {
                        theme: root.theme
                        darkMode: root.darkMode
                        compactMode: root.compactMode
                        showAdvancedInfo: root.showAdvancedInfo
                    }

                    MonitorPage {
                        theme: root.theme
                        darkMode: root.darkMode
                        compactMode: root.compactMode
                        showAdvancedInfo: root.showAdvancedInfo
                    }
                }
            }
        }
    }

    Popup {
        id: languagePopup
        modal: false
        focus: true
        x: root.width - width - 76
        y: 72
        width: 240
        height: languageColumn.implicitHeight + 24
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onClosed: root.languageDialogOpen = false

        background: Rectangle {
            radius: 22
            color: root.theme.card
            border.width: 1
            border.color: root.theme.border
        }

        ColumnLayout {
            id: languageColumn
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Repeater {
                model: languageManager.availableLanguages

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: 14
                    color: languageManager.currentLanguage === modelData.code ? root.theme.infoBg : "transparent"
                    border.width: languageManager.currentLanguage === modelData.code ? 1 : 0
                    border.color: root.theme.border

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        text: modelData.nativeLabel
                        color: root.theme.text
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            languageManager.setCurrentLanguage(modelData.code);
                            root.languageDialogOpen = false;
                        }
                    }
                }
            }
        }
    }
}
