import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: settingsPage

    property var theme: ({})
    property bool darkMode: false
    property bool showAdvancedInfo: true
    property real uiScale: 1.0
    readonly property bool hasUiPreferences: typeof uiPreferences !== "undefined" && uiPreferences !== null
    readonly property bool hasLanguageManager: typeof languageManager !== "undefined" && languageManager !== null
    readonly property string themeMode: hasUiPreferences ? uiPreferences.themeMode : "system"
    property string lastDiagnosticsRefresh: ""

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
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Theme mode")
                            color: settingsPage.textColor
                        }

                        ComboBox {
                            id: themePicker
                            Layout.preferredWidth: Math.round(220 * settingsPage.uiScale)
                            model: hasUiPreferences ? uiPreferences.availableThemeModes : []
                            textRole: "label"
                            palette.text: settingsPage.textColor
                            palette.buttonText: settingsPage.textColor

                            Component.onCompleted: settingsPage.syncThemePicker()

                            onActivated: {
                                const selected = model[currentIndex];
                                if (hasUiPreferences && selected && selected.code)
                                    uiPreferences.setThemeMode(selected.code);
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Language")
                            color: settingsPage.textColor
                        }

                        ComboBox {
                            id: languagePicker
                            Layout.preferredWidth: Math.round(220 * settingsPage.uiScale)
                            model: hasLanguageManager ? languageManager.availableLanguages : []
                            textRole: "label"
                            palette.text: settingsPage.textColor
                            palette.buttonText: settingsPage.textColor

                            Component.onCompleted: settingsPage.syncLanguagePicker()

                            onActivated: {
                                const selected = model[currentIndex];
                                if (hasLanguageManager && selected && selected.code)
                                    languageManager.setCurrentLanguage(selected.code);
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Show advanced diagnostics")
                            color: settingsPage.textColor
                        }

                        Switch {
                            checked: hasUiPreferences ? uiPreferences.showAdvancedInfo : false
                            enabled: hasUiPreferences
                            onToggled: if (hasUiPreferences) uiPreferences.setShowAdvancedInfo(checked)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Button {
                            text: qsTr("Reset Defaults")
                            enabled: hasUiPreferences
                            onClicked: if (hasUiPreferences) uiPreferences.resetToDefaults()
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: settingsPage.themeMode === "system" ? qsTr("Following system")
                                                                       : (settingsPage.darkMode ? qsTr("Dark mode") : qsTr("Light mode"))
                            color: settingsPage.softTextColor
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 14
                color: settingsPage.cardColor
                border.width: 1
                border.color: settingsPage.borderColor
                implicitHeight: aboutLayout.implicitHeight + 24

                ColumnLayout {
                    id: aboutLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Label {
                        text: qsTr("Diagnostics Snapshot")
                        color: settingsPage.textColor
                        font.pixelSize: Math.round(18 * settingsPage.uiScale)
                        font.bold: true
                    }

                    Label { text: qsTr("Application: %1 %2").arg(Qt.application.name).arg(Qt.application.version); color: settingsPage.softTextColor }
                    Label { text: qsTr("GPU: %1").arg(nvidiaDetector.gpuFound ? nvidiaDetector.gpuName : qsTr("Not detected")); color: settingsPage.softTextColor }
                    Label { text: qsTr("Driver: %1").arg(nvidiaDetector.activeDriver); color: settingsPage.softTextColor }
                    Label { text: qsTr("Session: %1").arg(nvidiaDetector.sessionType.length > 0 ? nvidiaDetector.sessionType : qsTr("Unknown")); color: settingsPage.softTextColor }
                    Label { text: qsTr("Language: %1").arg(hasLanguageManager ? languageManager.currentLanguageLabel : qsTr("Unknown")); color: settingsPage.softTextColor }
                    Label { text: qsTr("CPU Temp: %1 C").arg(cpuMonitor.temperatureC); color: settingsPage.softTextColor }
                    Label { text: qsTr("GPU Temp: %1 C").arg(gpuMonitor.temperatureC); color: settingsPage.softTextColor }
                    Label { text: qsTr("RAM Used: %1 / %2 MiB").arg(ramMonitor.usedMiB).arg(ramMonitor.totalMiB); color: settingsPage.softTextColor }
                    Label { text: qsTr("Last refresh: %1").arg(settingsPage.lastDiagnosticsRefresh.length > 0 ? settingsPage.lastDiagnosticsRefresh : qsTr("auto")); color: settingsPage.softTextColor }

                    Button {
                        text: qsTr("Refresh Diagnostics")
                        onClicked: {
                            nvidiaDetector.refresh()
                            cpuMonitor.refresh()
                            gpuMonitor.refresh()
                            ramMonitor.refresh()
                            settingsPage.lastDiagnosticsRefresh = Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm:ss")
                        }
                    }
                }
            }
        }
    }

    function syncLanguagePicker() {
        if (!hasLanguageManager)
            return;
        for (let i = 0; i < languagePicker.model.length; ++i) {
            if (languagePicker.model[i].code === languageManager.currentLanguage) {
                languagePicker.currentIndex = i;
                break;
            }
        }
    }

    function syncThemePicker() {
        if (!hasUiPreferences)
            return;
        for (let i = 0; i < themePicker.model.length; ++i) {
            if (themePicker.model[i].code === uiPreferences.themeMode) {
                themePicker.currentIndex = i;
                break;
            }
        }
    }

    Connections {
        target: hasLanguageManager ? languageManager : null

        function onAvailableVersionsChanged() {
            // Logic moved to DriverPage or not needed here
        }

        function onUpdateFinished(success, message) {
            nvidiaDetector.refresh();
        }
    }

    Connections {
        target: hasUiPreferences ? uiPreferences : null
        // No specific slots needed here for now
    }

    Component.onCompleted: {
        nvidiaDetector.refresh()
        cpuMonitor.refresh()
        gpuMonitor.refresh()
        ramMonitor.refresh()
        settingsPage.lastDiagnosticsRefresh = Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm:ss")
    }
}
