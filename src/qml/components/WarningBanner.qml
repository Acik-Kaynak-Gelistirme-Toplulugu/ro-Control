import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

Rectangle {
    id: banner

    implicitHeight: bannerRow.implicitHeight + 20
    radius: 10
    Layout.fillWidth: true

    property string type: "warning"
    property string text: ""
    property bool darkMode: false

    readonly property var _style: {
        var m = {
            "error":   { bg: darkMode ? "#3d1418" : "#ffebe9", fg: darkMode ? "#f85149" : "#cf222e", bd: darkMode ? "#5c2125" : "#f0c2c2", ic: "\u2715" },
            "success": { bg: darkMode ? "#162d1f" : "#dafbe1", fg: darkMode ? "#3fb950" : "#1a7f37", bd: darkMode ? "#245a34" : "#b4e6b4", ic: "\u2713" },
            "info":    { bg: darkMode ? "#1a3a52" : "#deeffe", fg: darkMode ? "#3daee9" : "#2980b9", bd: darkMode ? "#2a5580" : "#b0d5f1", ic: "\u2139" },
            "warning": { bg: darkMode ? "#2d2310" : "#fff8c5", fg: darkMode ? "#d29922" : "#bf8700", bd: darkMode ? "#5c4b1f" : "#e8d468", ic: "\u26A0" }
        };
        return m[type] || m["warning"];
    }

    color: _style.bg
    border.width: 1
    border.color: _style.bd

    RowLayout {
        id: bannerRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 12
        spacing: 10

        Controls.Label {
            text: banner._style.ic
            font.pixelSize: 15
            font.weight: Font.DemiBold
            color: banner._style.fg
        }

        Controls.Label {
            text: banner.text
            color: banner._style.fg
            font.pixelSize: 13
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
