import QtQuick
import QtQuick.Controls

Rectangle {
    id: badge

    property string text: ""
    property color backgroundColor: "#e5eefc"
    property color foregroundColor: "#15304f"

    radius: 999
    color: backgroundColor
    implicitHeight: 30
    implicitWidth: badgeLabel.implicitWidth + 22

    Label {
        id: badgeLabel
        anchors.centerIn: parent
        text: badge.text
        font.pixelSize: 12
        font.bold: true
        color: badge.foregroundColor
    }
}
