import QtQuick
import QtQuick.Controls

Rectangle {
    id: sidebar
    width: 220
    required property var theme
    color: theme.sidebarBg

    property int currentIndex: 0
    readonly property var menuItems: [
        qsTr("Driver Management"),
        qsTr("System Monitoring"),
        qsTr("Settings")
    ]

    Column {
        anchors.fill: parent
        spacing: 0

        // Başlık
        Item {
            width: parent.width
            height: 70

            Label {
                anchors.centerIn: parent
                text: qsTr("ro-Control")
                font.pixelSize: 22
                font.bold: true
                color: theme.sidebarText
            }
        }

        Rectangle {
            width: parent.width - 32
            height: 1
            anchors.horizontalCenter: parent.horizontalCenter
            color: theme.sidebarBorder
        }

        Item {
            width: 1
            height: 12
        }

        Repeater {
            model: sidebar.menuItems

            delegate: Rectangle {
                id: menuItem
                required property int index

                width: sidebar.width - 16
                height: 44
                x: 8
                radius: 8
                color: sidebar.currentIndex === menuItem.index ? theme.sidebarActive
                                                               : mouseArea.containsMouse ? theme.sidebarHover
                                                                                         : "transparent"

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 16
                    text: modelData
                    font.pixelSize: 14
                    color: sidebar.currentIndex === menuItem.index ? theme.sidebarAccent : theme.sidebarMuted
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sidebar.currentIndex = menuItem.index
                }
            }
        }
    }

    // Versiyon — alt köşe
    Label {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 16
        text: "v" + Qt.application.version
        font.pixelSize: 11
        color: theme.sidebarHint
    }
}
