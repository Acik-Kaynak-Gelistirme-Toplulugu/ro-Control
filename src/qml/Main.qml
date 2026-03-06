import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    width: 980
    height: 640
    title: "ro-Control"

    readonly property bool darkMode: Qt.styleHints.colorScheme === Qt.Dark
    color: darkMode ? "#141822" : "#f3f5fa"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ToolBar {
            Layout.fillWidth: true
            background: Rectangle {
                color: root.darkMode ? "#1b2130" : "#ffffff"
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8

                Label {
                    text: "ro-Control"
                    font.pixelSize: 20
                    font.bold: true
                    color: root.darkMode ? "#e9eefc" : "#101520"
                }

                Item {
                    Layout.fillWidth: true
                }

                Label {
                    text: root.darkMode ? "Tema: Sistem (Koyu)" : "Tema: Sistem (Acik)"
                    color: root.darkMode ? "#c9d1e8" : "#2b364b"
                }
            }
        }

        TabBar {
            id: tabs
            Layout.fillWidth: true

            TabButton {
                text: "Surucu"
            }
            TabButton {
                text: "Izleme"
            }
            TabButton {
                text: "Ayarlar"
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabs.currentIndex

            DriverPage {}
            MonitorPage {}
            SettingsPage {
                darkMode: root.darkMode
            }
        }
    }
}
