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
    required property var fanController
    required property var systemInfo
    required property var languageManager
    required property var uiPreferences
    visible: true
    width: 1280
    height: 800
    minimumWidth: 960
    minimumHeight: 600
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
    readonly property real uiScale: 1.0
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
        return qsTr("Light");
    }

    function sessionLabel() {
        if (!root.nvidiaDetector || root.nvidiaDetector.sessionType.length === 0)
            return qsTr("Unknown");
        const value = root.nvidiaDetector.sessionType;
        return value.charAt(0).toUpperCase() + value.slice(1);
    }

    function deviceTypeLabel() {
        if (root.systemInfo && root.systemInfo.deviceType && root.systemInfo.deviceType.length > 0)
            return root.systemInfo.deviceType;
        return qsTr("Desktop");
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

    function refreshAfterResume() {
        if (root.systemInfo)
            root.systemInfo.refresh();
        if (root.nvidiaDetector)
            root.nvidiaDetector.refresh();
        if (root.cpuMonitor) {
            root.cpuMonitor.start();
            root.cpuMonitor.refresh();
        }
        if (root.gpuMonitor) {
            root.gpuMonitor.start();
            root.gpuMonitor.refresh();
        }
        if (root.ramMonitor) {
            root.ramMonitor.start();
            root.ramMonitor.refresh();
        }
        if (root.fanController) {
            root.fanController.start();
            root.fanController.refresh();
        }
    }

    onActiveChanged: {
        if (active)
            resumeRefreshTimer.restart();
    }

    Timer {
        id: resumeRefreshTimer
        interval: 350
        repeat: false
        onTriggered: root.refreshAfterResume()
    }

    QtObject {
        id: colors
        // Clean high-contrast palettes for light and dark themes
        readonly property color window: root.darkMode ? "#1A1625" : "#F4F6F8"
        readonly property color shell: root.darkMode ? "#241F33" : "#EAEFF4"
        readonly property color shellAlt: root.darkMode ? "#1F1B2B" : "#FFFFFF"
        readonly property color card: root.darkMode ? "#29233B" : "#FFFFFF"
        readonly property color cardStrong: root.darkMode ? "#342D4A" : "#F1F5F9"
        readonly property color border: root.darkMode ? "#4D436B" : "#CBD5E1"
        readonly property color text: root.darkMode ? "#F8FAFC" : "#0F172A"
        readonly property color textMuted: root.darkMode ? "#CBD5E1" : "#475569"
        readonly property color textSoft: root.darkMode ? "#94A3B8" : "#64748B"
        readonly property color accentA: root.darkMode ? "#818CF8" : "#4F46E5"
        readonly property color accentB: root.darkMode ? "#A5B4FC" : "#6366F1"
        readonly property color accentC: root.darkMode ? "#312E81" : "#EEF2FF"
        readonly property color success: root.darkMode ? "#4ADE80" : "#059669"
        readonly property color warning: root.darkMode ? "#FBBF24" : "#D97706"
        readonly property color danger: root.darkMode ? "#F87171" : "#DC2626"
        readonly property color successBg: root.darkMode ? "#143828" : "#ECFDF5"
        readonly property color warningBg: root.darkMode ? "#3A2E12" : "#FFFBEB"
        readonly property color dangerBg: root.darkMode ? "#3D171E" : "#FEF2F2"
        readonly property color infoBg: root.darkMode ? "#1E2548" : "#EFF6FF"
        readonly property color heroStart: root.darkMode ? "#1A1625" : "#F4F6F8"
        readonly property color heroEnd: root.darkMode ? "#241F33" : "#EAEFF4"
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
            radius: Math.round(14 * root.uiScale)
            color: colors.shellAlt
            border.width: 1
            border.color: colors.border
            implicitHeight: topBar.implicitHeight + Math.round(20 * root.uiScale)

            RowLayout {
                id: topBar
                x: Math.round(16 * root.uiScale)
                y: Math.round(10 * root.uiScale)
                width: parent.width - Math.round(32 * root.uiScale)
                spacing: Math.round(14 * root.uiScale)

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Label {
                        text: qsTr("ro-Control")
                        color: colors.text
                        font.pixelSize: Math.round(24 * root.uiScale)
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: qsTr("Ro-ASD driver control and system diagnostics")
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: colors.textSoft
                        font.pixelSize: Math.round(12 * root.uiScale)
                    }
                }

                RowLayout {
                    spacing: Math.round(10 * root.uiScale)

                    Rectangle {
                        Layout.preferredWidth: Math.round(104 * root.uiScale)
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

                    Rectangle {
                        Layout.preferredWidth: Math.round(132 * root.uiScale)
                        Layout.preferredHeight: Math.round(34 * root.uiScale)
                        radius: Math.round(10 * root.uiScale)
                        color: colors.card
                        border.width: 1
                        border.color: colors.border

                        Label {
                            anchors.centerIn: parent
                            width: parent.width - Math.round(10 * root.uiScale)
                            text: root.deviceTypeLabel()
                            color: colors.text
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Math.round(12 * root.uiScale)
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

            contentItem: ListView {
                model: tabBar.contentModel
                currentIndex: tabBar.currentIndex
                spacing: tabBar.spacing
                orientation: ListView.Horizontal
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0
                highlightResizeDuration: 0
                highlight: null
            }

            TabButton {
                id: driverTab
                text: qsTr("Driver")
                hoverEnabled: true
                contentItem: Text {
                    text: driverTab.text
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: tabBar.currentIndex === 0 ? "#FFFFFF" : colors.textMuted
                    font.pixelSize: Math.round(14 * root.uiScale)
                    font.weight: tabBar.currentIndex === 0 ? Font.Bold : Font.Medium
                }
                background: Rectangle {
                    radius: Math.round(12 * root.uiScale)
                    color: tabBar.currentIndex === 0 ? colors.accentA : (driverTab.hovered ? colors.cardStrong : "transparent")
                }
            }
            TabButton {
                id: monitorTab
                text: qsTr("Monitor")
                hoverEnabled: true
                contentItem: Text {
                    text: monitorTab.text
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: tabBar.currentIndex === 1 ? "#FFFFFF" : colors.textMuted
                    font.pixelSize: Math.round(14 * root.uiScale)
                    font.weight: tabBar.currentIndex === 1 ? Font.Bold : Font.Medium
                }
                background: Rectangle {
                    radius: Math.round(12 * root.uiScale)
                    color: tabBar.currentIndex === 1 ? colors.accentA : (monitorTab.hovered ? colors.cardStrong : "transparent")
                }
            }
            TabButton {
                id: fanTab
                text: qsTr("Cooling & Fans")
                hoverEnabled: true
                contentItem: Text {
                    text: fanTab.text
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: tabBar.currentIndex === 2 ? "#FFFFFF" : colors.textMuted
                    font.pixelSize: Math.round(14 * root.uiScale)
                    font.weight: tabBar.currentIndex === 2 ? Font.Bold : Font.Medium
                }
                background: Rectangle {
                    radius: Math.round(12 * root.uiScale)
                    color: tabBar.currentIndex === 2 ? colors.accentA : (fanTab.hovered ? colors.cardStrong : "transparent")
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
                    fanController: root.fanController
                }

                Pages.FanPage {
                    theme: colors
                    darkMode: root.darkMode
                    showAdvancedInfo: root.showAdvancedInfo
                    uiScale: root.uiScale
                    systemInfo: root.systemInfo
                    cpuMonitor: root.cpuMonitor
                    gpuMonitor: root.gpuMonitor
                    fanController: root.fanController
                }

            }
        }
    }
}
