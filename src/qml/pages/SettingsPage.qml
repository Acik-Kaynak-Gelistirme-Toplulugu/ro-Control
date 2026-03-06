import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: settingsPage
    property bool darkMode: false

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20

        ColumnLayout {
            width: parent.width
            spacing: 14

            Label {
                text: "Ayarlar"
                font.pixelSize: 24
                font.bold: true
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 10
                border.width: 1
                border.color: settingsPage.darkMode ? "#4f5f82" : "#c4ccdd"
                color: "transparent"
                implicitHeight: aboutColumn.implicitHeight + 20

                ColumnLayout {
                    id: aboutColumn
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Label {
                        text: "Hakkinda"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    Label {
                        text: "Uygulama: " + Qt.application.name + " (" + Qt.application.version + ")"
                        wrapMode: Text.Wrap
                    }

                    Label {
                        text: "Tema modu: " + (settingsPage.darkMode ? "Sistem Koyu" : "Sistem Acik")
                    }

                    Label {
                        text: "Son iyilestirmeler:"
                        font.bold: true
                    }

                    Label {
                        text: "- Secure Boot kontrolu eklendi\n" + "- Surucu versiyonu teyit raporu eklendi\n" + "- CommandRunner stdout kaybi duzeltildi\n" + "- RPM Fusion URL olusturma duzeltildi"
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}
