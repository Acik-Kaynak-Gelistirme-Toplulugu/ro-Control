pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import "pages" as Pages

ApplicationWindow {
    id: root
    required property var nvidiaDetector
    required property var nvidiaInstaller
    required property var nvidiaUpdater
    required property var cpuMonitor
    required property var gpuMonitor
    required property var ramMonitor
    required property var systemInfo
    required property var languageManager
    required property var uiPreferences
    visible: true
    width: 1320
    height: 840
    minimumWidth: 1024
    minimumHeight: 700
    title: qsTr("ro-Control")
    font.family: "Noto Sans"

    readonly property bool hasUiPreferences: root.uiPreferences !== null
    readonly property bool hasLanguageManager: root.languageManager !== null
    readonly property string themeMode: (hasUiPreferences && root.uiPreferences.themeMode)
                                        ? root.uiPreferences.themeMode
                                        : "light"
    readonly property bool darkMode: themeMode === "dark"
    readonly property bool showAdvancedInfo: (hasUiPreferences && root.uiPreferences.showAdvancedInfo !== undefined)
                                             ? root.uiPreferences.showAdvancedInfo
                                             : true
    readonly property real uiScale: Math.max(0.85, Math.min(width / 1320, 1.15))
    property string quickMenuMode: ""
    readonly property var visibleLanguages: root.hasLanguageManager
                                            ? root.languageManager.availableLanguages
                                            : []
    readonly property var visibleThemeModes: root.hasUiPreferences
                                             ? root.uiPreferences.availableThemeModes
                                             : []

    function currentLanguageLabel() {
        return root.hasLanguageManager ? root.languageManager.currentLanguageLabel : qsTr("Language");
    }

    function currentThemeLabel() {
        if (root.themeMode === "dark")
            return qsTr("Dark");
        if (root.themeMode === "light")
            return qsTr("Light");
        return qsTr("Automatic");
    }

    function sessionLabel() {
        if (!root.nvidiaDetector || root.nvidiaDetector.sessionType.length === 0)
            return qsTr("Unknown");
        const value = root.nvidiaDetector.sessionType;
        return value.charAt(0).toUpperCase() + value.slice(1);
    }

    function openQuickMenu(mode, sourceButton) {
        quickMenuMode = mode;
        quickMenuPopup.width = Math.round(220 * root.uiScale);
        quickMenuPopup.x = Math.max(Math.round(16 * root.uiScale),
                                    Math.min(sourceButton.mapToItem(root.contentItem, 0, 0).x
                                             + sourceButton.width - quickMenuPopup.width,
                                             root.width - quickMenuPopup.width - Math.round(16 * root.uiScale)));
        quickMenuPopup.y = sourceButton.mapToItem(root.contentItem, 0, sourceButton.height).y + Math.round(8 * root.uiScale);
        quickMenuPopup.open();
    }

    QtObject {
        id: colors
        // Light palette: #92C7CF #AAD7D9 #FBF9F1 #E5E1DA
        // Dark palette:  #352F44 #5C5470 #B9B4C7 #FAF0E6
        readonly property color window: root.darkMode ? "#352F44" : "#FBF9F1"
        readonly property color shell: root.darkMode ? "#5C5470" : "#E5E1DA"
        readonly property color shellAlt: root.darkMode ? "#352F44" : "#FBF9F1"
        readonly property color card: root.darkMode ? "#5C5470" : "#FBF9F1"
        readonly property color cardStrong: root.darkMode ? "#352F44" : "#AAD7D9"
        readonly property color border: root.darkMode ? "#B9B4C7" : "#92C7CF"
        readonly property color text: root.darkMode ? "#FAF0E6" : "#352F44"
        readonly property color textMuted: root.darkMode ? "#B9B4C7" : "#5C5470"
        readonly property color textSoft: root.darkMode ? "#B9B4C7" : "#5C5470"
        readonly property color accentA: root.darkMode ? "#B9B4C7" : "#92C7CF"
        readonly property color accentB: root.darkMode ? "#FAF0E6" : "#AAD7D9"
        readonly property color accentC: root.darkMode ? "#5C5470" : "#E5E1DA"
        readonly property color success: root.darkMode ? "#FAF0E6" : "#352F44"
        readonly property color warning: root.darkMode ? "#B9B4C7" : "#5C5470"
        readonly property color danger: root.darkMode ? "#FAF0E6" : "#352F44"
        readonly property color successBg: root.darkMode ? "#5C5470" : "#AAD7D9"
        readonly property color warningBg: root.darkMode ? "#352F44" : "#E5E1DA"
        readonly property color dangerBg: root.darkMode ? "#5C5470" : "#E5E1DA"
        readonly property color infoBg: root.darkMode ? "#5C5470" : "#AAD7D9"
        readonly property color heroStart: root.darkMode ? "#352F44" : "#FBF9F1"
        readonly property color heroEnd: root.darkMode ? "#5C5470" : "#E5E1DA"
    }

    color: colors.window
    font.pixelSize: Math.round(13 * uiScale)
    Material.theme: darkMode ? Material.Dark : Material.Light
    Material.accent: colors.accentA
    Material.primary: colors.accentB
    Material.background: colors.window
    Material.foreground: colors.text

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: colors.heroStart }
            GradientStop { position: 1.0; color: colors.shell }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(16 * root.uiScale)
        spacing: Math.round(10 * root.uiScale)

        Rectangle {
            Layout.fillWidth: true
            radius: Math.round(22 * root.uiScale)
            color: colors.shellAlt
            border.width: 1
            border.color: colors.border
            implicitHeight: topBar.implicitHeight + Math.round(26 * root.uiScale)

            RowLayout {
                id: topBar
                x: Math.round(16 * root.uiScale)
                y: Math.round(13 * root.uiScale)
                width: parent.width - Math.round(32 * root.uiScale)
                spacing: Math.round(14 * root.uiScale)

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: qsTr("ro-Control")
                        color: colors.text
                        font.pixelSize: Math.round(28 * root.uiScale)
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: qsTr("ro-ASD NVIDIA driver operations and system diagnostics")
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: colors.textSoft
                        font.pixelSize: Math.round(13 * root.uiScale)
                    }
                }

                RowLayout {
                    spacing: Math.round(10 * root.uiScale)

                    Rectangle {
                        Layout.preferredWidth: Math.round(92 * root.uiScale)
                        Layout.preferredHeight: Math.round(34 * root.uiScale)
                        radius: Math.round(10 * root.uiScale)
                        color: colors.card
                        border.width: 1
                        border.color: colors.border

                        Label {
                            anchors.centerIn: parent
                            text: root.sessionLabel()
                            color: colors.text
                            font.pixelSize: Math.round(13 * root.uiScale)
                            font.weight: Font.DemiBold
                        }
                    }

                    ToolButton {
                        id: languageButton
                        implicitWidth: Math.round(46 * root.uiScale)
                        implicitHeight: Math.round(46 * root.uiScale)
                        icon.source: "qrc:/qt/qml/rocontrol/assets/icon-language.svg"
                        icon.width: Math.round(21 * root.uiScale)
                        icon.height: Math.round(21 * root.uiScale)
                        display: AbstractButton.IconOnly
                        onClicked: root.openQuickMenu("language", languageButton)
                        ToolTip.visible: hovered
                        ToolTip.text: root.currentLanguageLabel()

                        background: Rectangle {
                            radius: width / 2
                            color: languageButton.down || quickMenuPopup.visible && root.quickMenuMode === "language"
                                   ? colors.accentA
                                   : colors.card
                            border.width: 1
                            border.color: colors.border
                        }

                    }

                    ToolButton {
                        id: themeButton
                        implicitWidth: Math.round(46 * root.uiScale)
                        implicitHeight: Math.round(46 * root.uiScale)
                        icon.source: "qrc:/qt/qml/rocontrol/assets/icon-theme.svg"
                        icon.width: Math.round(21 * root.uiScale)
                        icon.height: Math.round(21 * root.uiScale)
                        display: AbstractButton.IconOnly
                        onClicked: root.openQuickMenu("theme", themeButton)
                        ToolTip.visible: hovered
                        ToolTip.text: root.currentThemeLabel()

                        background: Rectangle {
                            radius: width / 2
                            color: themeButton.down || quickMenuPopup.visible && root.quickMenuMode === "theme"
                                   ? colors.accentA
                                   : colors.card
                            border.width: 1
                            border.color: colors.border
                        }

                    }
                }

            }
        }

        Popup {
            id: quickMenuPopup
            modal: false
            focus: true
            padding: Math.round(10 * root.uiScale)
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            background: Rectangle {
                radius: Math.round(16 * root.uiScale)
                color: colors.shellAlt
                border.width: 1
                border.color: colors.border
            }

            contentItem: ColumnLayout {
                spacing: Math.round(6 * root.uiScale)

                Repeater {
                    model: root.quickMenuMode === "language" ? root.visibleLanguages : root.visibleThemeModes

                    delegate: Button {
                        id: quickMenuButton
                        required property var modelData
                        Layout.fillWidth: true
                        text: root.quickMenuMode === "language" ? modelData.nativeLabel : modelData.label

                        background: Rectangle {
                            radius: Math.round(10 * root.uiScale)
                            color: quickMenuButton.modelData.code === (root.quickMenuMode === "language"
                                                                       ? root.languageManager.currentLanguage
                                                                       : root.uiPreferences.themeMode)
                                   ? colors.accentA
                                   : colors.card
                            border.width: 1
                            border.color: colors.border
                        }

                        contentItem: Text {
                            text: quickMenuButton.text
                            color: quickMenuButton.modelData.code === (root.quickMenuMode === "language"
                                                                       ? root.languageManager.currentLanguage
                                                                       : root.uiPreferences.themeMode)
                                   ? colors.text
                                   : colors.text
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: Math.round(13 * root.uiScale)
                            font.weight: quickMenuButton.modelData.code === (root.quickMenuMode === "language"
                                                                             ? root.languageManager.currentLanguage
                                                                             : root.uiPreferences.themeMode)
                                         ? Font.DemiBold : Font.Medium
                        }

                        onClicked: {
                            if (root.quickMenuMode === "language")
                                root.languageManager.setCurrentLanguage(modelData.code);
                            else
                                root.uiPreferences.setThemeMode(modelData.code);
                            quickMenuPopup.close();
                        }
                    }
                }
            }
        }

        TabBar {
            id: tabBar
            Layout.fillWidth: true
            spacing: Math.round(8 * root.uiScale)

            background: Rectangle {
                radius: 16
                color: colors.shellAlt
                border.width: 1
                border.color: colors.border
            }

            TabButton {
                id: driverTab
                text: qsTr("Driver")
                contentItem: Text {
                    text: driverTab.text
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: tabBar.currentIndex === 0 ? colors.text : colors.textMuted
                    font.pixelSize: Math.round(14 * root.uiScale)
                    font.weight: tabBar.currentIndex === 0 ? Font.DemiBold : Font.Medium
                }
                background: Rectangle {
                    radius: Math.round(12 * root.uiScale)
                    color: tabBar.currentIndex === 0 ? colors.accentA : "transparent"
                }
            }
            TabButton {
                id: monitorTab
                text: qsTr("Monitor")
                contentItem: Text {
                    text: monitorTab.text
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: tabBar.currentIndex === 1 ? colors.text : colors.textMuted
                    font.pixelSize: Math.round(14 * root.uiScale)
                    font.weight: tabBar.currentIndex === 1 ? Font.DemiBold : Font.Medium
                }
                background: Rectangle {
                    radius: Math.round(12 * root.uiScale)
                    color: tabBar.currentIndex === 1 ? colors.accentA : "transparent"
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Math.round(22 * root.uiScale)
            color: colors.card
            border.width: 1
            border.color: colors.border

            StackLayout {
                anchors.fill: parent
                anchors.margins: Math.round(10 * root.uiScale)
                currentIndex: tabBar.currentIndex

                Pages.DriverPage {
                    theme: colors
                    darkMode: root.darkMode
                    showAdvancedInfo: root.showAdvancedInfo
                    uiScale: root.uiScale
                    nvidiaDetector: root.nvidiaDetector
                    nvidiaInstaller: root.nvidiaInstaller
                    nvidiaUpdater: root.nvidiaUpdater
                    systemInfo: root.systemInfo
                }

                Pages.MonitorPage {
                    theme: colors
                    darkMode: root.darkMode
                    showAdvancedInfo: root.showAdvancedInfo
                    uiScale: root.uiScale
                    systemInfo: root.systemInfo
                    cpuMonitor: root.cpuMonitor
                    gpuMonitor: root.gpuMonitor
                    ramMonitor: root.ramMonitor
                }

            }
        }
    }
}
