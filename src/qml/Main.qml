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

    SystemPalette {
        id: systemPalette
        colorGroup: SystemPalette.Active
    }

    function isColorDark(colorValue) {
        return ((0.2126 * colorValue.r) + (0.7152 * colorValue.g) + (0.0722 * colorValue.b)) < 0.5;
    }

    readonly property bool hasUiPreferences: root.uiPreferences !== null
    readonly property bool hasLanguageManager: root.languageManager !== null
    readonly property string themeMode: (hasUiPreferences && root.uiPreferences.themeMode)
                                        ? root.uiPreferences.themeMode
                                        : "system"
    readonly property bool systemDarkMode: isColorDark(systemPalette.window)
    readonly property bool darkMode: themeMode === "dark"
                                     || (themeMode === "system" && systemDarkMode)
    readonly property bool showAdvancedInfo: (hasUiPreferences && root.uiPreferences.showAdvancedInfo !== undefined)
                                             ? root.uiPreferences.showAdvancedInfo
                                             : true
    readonly property real uiScale: Math.max(0.85, Math.min(width / 1320, 1.15))

    function syncThemePicker() {
        if (!hasUiPreferences)
            return;
        for (let i = 0; i < themePicker.model.length; ++i) {
            if (themePicker.model[i].code === root.uiPreferences.themeMode) {
                themePicker.currentIndex = i;
                break;
            }
        }
    }

    function syncLanguagePicker() {
        if (!hasLanguageManager)
            return;
        for (let i = 0; i < languagePicker.model.length; ++i) {
            if (languagePicker.model[i].code === root.languageManager.currentLanguage) {
                languagePicker.currentIndex = i;
                break;
            }
        }
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
                        text: qsTr("Modern NVIDIA driver operations and live Linux telemetry")
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: colors.textSoft
                        font.pixelSize: Math.round(13 * root.uiScale)
                    }
                }

                RowLayout {
                    spacing: Math.round(8 * root.uiScale)

                    ComboBox {
                        id: languagePicker
                        Layout.preferredWidth: Math.round(170 * root.uiScale)
                        model: root.hasLanguageManager ? root.languageManager.availableLanguages : []
                        textRole: "nativeLabel"
                        palette.text: colors.text
                        palette.buttonText: colors.text

                        Component.onCompleted: root.syncLanguagePicker()

                        onActivated: {
                            const selected = model[currentIndex];
                            if (root.hasLanguageManager && selected && selected.code)
                                root.languageManager.setCurrentLanguage(selected.code);
                        }
                    }

                    ComboBox {
                        id: themePicker
                        Layout.preferredWidth: Math.round(150 * root.uiScale)
                        model: root.hasUiPreferences ? root.uiPreferences.availableThemeModes : []
                        textRole: "label"
                        palette.text: colors.text
                        palette.buttonText: colors.text

                        Component.onCompleted: root.syncThemePicker()

                        onActivated: {
                            const selected = model[currentIndex];
                            if (root.hasUiPreferences && selected && selected.code)
                                root.uiPreferences.setThemeMode(selected.code);
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
                    color: tabBar.currentIndex === 0 ? colors.window : colors.textMuted
                    font.pixelSize: Math.round(14 * root.uiScale)
                    font.bold: tabBar.currentIndex === 0
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
                    color: tabBar.currentIndex === 1 ? colors.window : colors.textMuted
                    font.pixelSize: Math.round(14 * root.uiScale)
                    font.bold: tabBar.currentIndex === 1
                }
                background: Rectangle {
                    radius: Math.round(12 * root.uiScale)
                    color: tabBar.currentIndex === 1 ? colors.accentA : "transparent"
                }
            }
            TabButton {
                id: settingsTab
                text: qsTr("Settings")
                contentItem: Text {
                    text: settingsTab.text
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: tabBar.currentIndex === 2 ? colors.window : colors.textMuted
                    font.pixelSize: Math.round(14 * root.uiScale)
                    font.bold: tabBar.currentIndex === 2
                }
                background: Rectangle {
                    radius: Math.round(12 * root.uiScale)
                    color: tabBar.currentIndex === 2 ? colors.accentA : "transparent"
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

                Pages.SettingsPage {
                    theme: colors
                    darkMode: root.darkMode
                    showAdvancedInfo: root.showAdvancedInfo
                    uiScale: root.uiScale
                    uiPreferences: root.uiPreferences
                }
            }
        }
    }

    Connections {
        target: root.uiPreferences

        function onThemeModeChanged() {
            root.syncThemePicker()
        }
    }

    Connections {
        target: root.languageManager

        function onCurrentLanguageChanged() {
            root.syncLanguagePicker()
        }
    }
}
