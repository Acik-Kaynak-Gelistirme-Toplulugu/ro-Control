pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: sidebar
    width: 286
    required property var theme
    color: theme.sidebarBg
    border.width: 1
    border.color: theme.sidebarBorder
    clip: true

    property int currentIndex: 0
    readonly property var menuItems: [
        { title: qsTr("Install"), marker: "\u2193" },
        { title: qsTr("Expert"), marker: "\u2699" },
        { title: qsTr("Monitor"), marker: "\u223f" }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 22
        anchors.bottomMargin: 22
        spacing: 0

        Repeater {
            model: sidebar.menuItems

            delegate: Rectangle {
                id: menuCard
                required property int index
                required property var modelData

                Layout.leftMargin: 22
                Layout.rightMargin: 22
                Layout.topMargin: menuCard.index === 0 ? 0 : 10
                Layout.fillWidth: true
                implicitHeight: 90
                radius: 22
                color: sidebar.currentIndex === menuCard.index ? sidebar.theme.sidebarActive
                                                               : "transparent"
                border.width: sidebar.currentIndex === menuCard.index ? 1 : 0
                border.color: sidebar.theme.sidebarBorder

                Rectangle {
                    visible: sidebar.currentIndex === menuCard.index
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4
                    height: parent.height - 20
                    radius: 2
                    color: sidebar.theme.sidebarAccent
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 22
                    anchors.rightMargin: 22
                    spacing: 16

                    Rectangle {
                        implicitWidth: 48
                        implicitHeight: 48
                        radius: 16
                        color: sidebar.currentIndex === menuCard.index ? sidebar.theme.sidebarAccent : sidebar.theme.cardStrong

                        Label {
                            anchors.centerIn: parent
                            text: menuCard.modelData.marker
                            color: sidebar.currentIndex === menuCard.index ? "#ffffff" : sidebar.theme.sidebarMuted
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: menuCard.modelData.title
                        color: sidebar.theme.sidebarText
                        font.pixelSize: 16
                        font.weight: sidebar.currentIndex === menuCard.index ? Font.DemiBold : Font.Medium
                    }

                    Rectangle {
                        implicitWidth: 10
                        implicitHeight: 10
                        radius: 5
                        visible: sidebar.currentIndex === menuCard.index
                        color: sidebar.theme.sidebarAccent
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        if (sidebar.currentIndex !== menuCard.index)
                            menuCard.color = sidebar.theme.sidebarHover;
                    }
                    onExited: {
                        if (sidebar.currentIndex !== menuCard.index)
                            menuCard.color = "transparent";
                    }
                    onClicked: sidebar.currentIndex = menuCard.index
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
